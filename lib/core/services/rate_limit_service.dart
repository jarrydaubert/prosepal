import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_fingerprint_service.dart';
import 'log_service.dart';

/// Service for server-side rate limiting.
///
/// Prevents API abuse by tracking request frequency per user and device.
/// Uses Supabase RPC function `check_rate_limit` which implements sliding
/// window rate limiting.
///
/// ## Rate Limits (configurable in database)
/// - User: 20 requests/minute
/// - Device: 30 requests/minute
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
  /// Graceful degradation: Returns allowed=true if server check fails.
  Future<RateLimitResult> checkRateLimit({
    String endpoint = 'generation',
  }) async {
    final supabase = _supabase;

    if (supabase == null) {
      Log.warning('Rate limit check skipped: Supabase not initialized');
      return const RateLimitResult(allowed: true);
    }

    final userId = _userId;
    final deviceFingerprint = await _deviceFingerprint.getDeviceFingerprint();

    // If we have neither user nor device, allow (can't track)
    if (userId == null && deviceFingerprint == null) {
      Log.warning('Rate limit check skipped: no identifier available');
      return const RateLimitResult(allowed: true);
    }

    try {
      final response = await supabase.rpc('check_rate_limit', params: {
        'p_user_id': userId,
        'p_device_fingerprint': deviceFingerprint,
        'p_endpoint': endpoint,
      });

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
      Log.error('Rate limit check failed', e);
      // Graceful degradation - allow on error
      return const RateLimitResult(
        allowed: true,
        reason: RateLimitReason.serverError,
      );
    }
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

/// Reasons for rate limit denial
enum RateLimitReason {
  /// Per-user rate limit exceeded
  userLimit,

  /// Per-device rate limit exceeded
  deviceLimit,

  /// Per-IP rate limit exceeded (shared networks)
  ipLimit,

  /// Global rate limit exceeded (emergency brake)
  globalLimit,

  /// Server error during check
  serverError,

  /// Unknown reason
  unknown,
}
