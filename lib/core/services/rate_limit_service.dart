import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_fingerprint_service.dart';
import 'log_service.dart';

/// Service for rate limiting with server-side + local fallback.
///
/// Prevents API abuse by tracking request frequency per user and device.
/// Uses Supabase RPC function `check_rate_limit` with sliding window.
///
/// ## Security Model: Fail Closed
/// If server check fails, falls back to local rate limiting rather than
/// allowing unlimited requests. This prevents abuse when server is down.
///
/// ## Rate Limits
/// - Server-side: 20 requests/minute per user, 30/minute per device
/// - Local fallback: 10 requests/minute (conservative)
///
/// ## Usage
/// ```dart
/// final service = RateLimitService(deviceFingerprintService);
/// final result = await service.checkRateLimit();
/// if (!result.allowed) {
///   // Show "Too many requests, try again in X seconds"
/// }
/// ```
class RateLimitService {
  RateLimitService(this._deviceFingerprint);

  final DeviceFingerprintService _deviceFingerprint;

  // Local rate limiting fallback (persisted to survive app restart)
  List<DateTime> _localRequestTimestamps = [];
  static const _localWindowDuration = Duration(minutes: 1);
  static const _localMaxRequests = 10; // Conservative fallback limit
  static const _prefsKey = 'rate_limit_timestamps';
  bool _initialized = false;

  /// Load persisted timestamps from SharedPreferences
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_prefsKey);
      if (stored != null) {
        final now = DateTime.now();
        final windowStart = now.subtract(_localWindowDuration);
        // Only load timestamps within the current window
        _localRequestTimestamps = stored
            .map((s) => DateTime.tryParse(s))
            .whereType<DateTime>()
            .where((ts) => ts.isAfter(windowStart))
            .toList();
      }
    } catch (e) {
      Log.warning('Failed to load rate limit history', {'error': '$e'});
    }
    _initialized = true;
  }

  /// Persist timestamps to SharedPreferences
  Future<void> _persistTimestamps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strings = _localRequestTimestamps.map((ts) => ts.toIso8601String()).toList();
      await prefs.setStringList(_prefsKey, strings);
    } catch (e) {
      Log.warning('Failed to persist rate limit history', {'error': '$e'});
    }
  }

  /// Get Supabase client (may be null if not initialized)
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Get current user ID (null if not authenticated)
  String? get _userId => _supabase?.auth.currentUser?.id;

  /// Check if the current user/device is within rate limits.
  ///
  /// This should be called BEFORE making an expensive API call (like AI generation).
  /// If allowed, the request is automatically recorded for rate tracking.
  ///
  /// Returns [RateLimitResult] with:
  /// - [allowed]: true if request can proceed
  /// - [retryAfter]: seconds until rate limit resets (if blocked)
  /// - [reason]: why request was blocked (if blocked)
  ///
  /// Fail closed: Uses local fallback if server check fails.
  Future<RateLimitResult> checkRateLimit({
    String endpoint = 'generation',
  }) async {
    final supabase = _supabase;

    // No server available - use local fallback (fail closed)
    if (supabase == null) {
      Log.warning('Rate limit using local fallback: Supabase not initialized');
      return _checkLocalRateLimit();
    }

    final userId = _userId;
    final deviceFingerprint = await _deviceFingerprint.getDeviceFingerprint();

    // No identifier available - use local fallback (fail closed)
    if (userId == null && deviceFingerprint == null) {
      Log.warning('Rate limit using local fallback: no identifier available');
      return _checkLocalRateLimit();
    }

    try {
      final response = await supabase.rpc(
        'check_rate_limit',
        params: {
          'p_user_id': userId,
          'p_device_fingerprint': deviceFingerprint,
          'p_endpoint': endpoint,
        },
      );

      final result = response as Map<String, dynamic>;
      final allowed = result['allowed'] as bool? ?? true;
      final retryAfter = result['retry_after'] as int? ?? 0;
      final reason = result['reason'] as String?;

      Log.info('Rate limit check', {
        'allowed': allowed,
        'retryAfter': retryAfter,
        'reason': reason,
        'endpoint': endpoint,
      });

      if (!allowed) {
        return RateLimitResult(
          allowed: false,
          retryAfter: retryAfter,
          reason: _parseReason(reason),
        );
      }

      return const RateLimitResult(allowed: true);
    } catch (e) {
      Log.error('Rate limit check failed, using local fallback', e);
      // Fail closed with local fallback - don't allow unlimited on server error
      return _checkLocalRateLimit();
    }
  }

  /// Local rate limiting fallback when server is unavailable.
  ///
  /// Uses a sliding window counter persisted to SharedPreferences.
  /// More conservative than server limits to prevent abuse.
  Future<RateLimitResult> _checkLocalRateLimit() async {
    await _ensureInitialized();

    final now = DateTime.now();
    final windowStart = now.subtract(_localWindowDuration);

    // Remove expired timestamps
    _localRequestTimestamps.removeWhere((ts) => ts.isBefore(windowStart));

    // Check if within limit
    if (_localRequestTimestamps.length >= _localMaxRequests) {
      // Calculate retry time based on oldest request in window
      final oldestInWindow = _localRequestTimestamps.first;
      final retryAfter = oldestInWindow
          .add(_localWindowDuration)
          .difference(now)
          .inSeconds;

      Log.warning('Local rate limit exceeded', {
        'requestsInWindow': _localRequestTimestamps.length,
        'maxRequests': _localMaxRequests,
        'retryAfter': retryAfter,
      });

      return RateLimitResult(
        allowed: false,
        retryAfter: retryAfter > 0 ? retryAfter : 1,
        reason: RateLimitReason.localFallback,
      );
    }

    // Record this request and persist
    _localRequestTimestamps.add(now);
    await _persistTimestamps();

    Log.info('Local rate limit check passed', {
      'requestsInWindow': _localRequestTimestamps.length,
      'maxRequests': _localMaxRequests,
    });

    return const RateLimitResult(
      allowed: true,
      reason: RateLimitReason.localFallback,
    );
  }

  /// Clear local rate limit history (for testing)
  Future<void> clearLocalHistory() async {
    _localRequestTimestamps.clear();
    _initialized = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }

  RateLimitReason? _parseReason(String? reason) {
    if (reason == null) return null;
    switch (reason) {
      case 'user_limit':
        return RateLimitReason.userLimit;
      case 'device_limit':
        return RateLimitReason.deviceLimit;
      case 'ip_limit':
        return RateLimitReason.ipLimit;
      case 'global_limit':
        return RateLimitReason.globalLimit;
      default:
        return RateLimitReason.unknown;
    }
  }
}

/// Result of a rate limit check
class RateLimitResult {
  const RateLimitResult({
    required this.allowed,
    this.retryAfter = 0,
    this.reason,
  });

  /// Whether the request is allowed
  final bool allowed;

  /// Seconds until the rate limit window resets (if blocked)
  final int retryAfter;

  /// Why the request was blocked (if blocked)
  final RateLimitReason? reason;

  /// User-friendly error message
  String get errorMessage {
    if (allowed) return '';
    if (retryAfter > 0) {
      return 'Too many requests. Please try again in $retryAfter seconds.';
    }
    return 'Too many requests. Please try again later.';
  }

  @override
  String toString() =>
      'RateLimitResult(allowed: $allowed, retryAfter: $retryAfter, reason: $reason)';
}

/// Reasons for rate limit status
enum RateLimitReason {
  /// Per-user rate limit exceeded
  userLimit,

  /// Per-device rate limit exceeded
  deviceLimit,

  /// Per-IP rate limit exceeded (shared networks)
  ipLimit,

  /// Global rate limit exceeded (emergency brake)
  globalLimit,

  /// Using local fallback (server unavailable)
  localFallback,

  /// Unknown reason
  unknown,
}
