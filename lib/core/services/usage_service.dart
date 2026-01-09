import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_fingerprint_service.dart';
import 'log_service.dart';
import 'rate_limit_service.dart';

/// Tracks generation usage with server-side persistence via Supabase.
///
/// Free tier usage is stored in Supabase to survive app reinstalls.
/// Local cache (SharedPreferences) provides fast reads; server is source of truth.
///
/// ## Architecture
/// - **Rate limiting**: [RateLimitService] prevents API abuse (20 req/min/user)
/// - **Server-side enforcement**: [checkAndIncrementServerSide] validates and
///   increments atomically via Supabase RPC - REQUIRED for authenticated users
/// - **Device fingerprinting**: [DeviceFingerprintService] tracks device-level
///   free tier usage to prevent abuse via reinstalls or account switching
/// - **Client-side cache**: Local SharedPreferences for UI display (remaining
///   counts) and offline/anonymous fallback
///
/// ## Flow
/// 1. User signs in -> syncFromServer() fetches their usage
/// 2. User generates -> checkAndIncrementServerSide() validates + increments
/// 3. Rate limit checked first -> Device fingerprint checked -> Usage incremented
/// 4. Local cache updated from RPC response
/// 5. User reinstalls -> signs in -> gets their existing usage from server
///
/// ## Security
/// Authenticated users MUST use [checkAndIncrementServerSide] which:
/// 1. Checks rate limits (prevents abuse)
/// 2. Checks device fingerprint (prevents reinstall abuse)
/// 3. Calls `check_and_increment_usage` Supabase RPC (prevents client tampering)
class UsageService {
  UsageService(this._prefs, this._deviceFingerprint, this._rateLimit);

  final SharedPreferences _prefs;
  final DeviceFingerprintService _deviceFingerprint;
  final RateLimitService _rateLimit;

  // Local cache keys
  static const _keyTotalCount = 'total_generation_count';
  static const _keyMonthlyCount = 'monthly_generation_count';
  static const _keyMonthlyDate = 'monthly_generation_month';
  static const _keyLastSyncUserId = 'last_sync_user_id';
  // Device-level flag - survives account deletion (fraud prevention, not user data)
  static const _keyDeviceUsedFreeTier = 'device_used_free_tier';

  // Limits
  static const int freeLifetimeLimit = 1;
  static const int proMonthlyLimit = 500;

  /// Network timeout for Supabase calls (prevents indefinite hangs)
  static const _timeout = Duration(seconds: 30);

  // Supabase table and columns
  static const _table = 'user_usage';

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

  // ===========================================================================
  // READ OPERATIONS (from local cache for speed)
  // ===========================================================================

  /// Get total all-time generation count
  int getTotalCount() {
    return _prefs.getInt(_keyTotalCount) ?? 0;
  }

  /// Get this month's generation count (for Pro users)
  int getMonthlyCount() {
    final thisMonth = _monthString();
    final savedMonth = _prefs.getString(_keyMonthlyDate);

    if (savedMonth != thisMonth) {
      return 0;
    }

    return _prefs.getInt(_keyMonthlyCount) ?? 0;
  }

  /// Check if user can generate (free tier - lifetime limit)
  /// This is a QUICK LOCAL CHECK for UI responsiveness.
  /// For actual generation, use [checkDeviceFreeTierServerSide] or
  /// [checkAndIncrementServerSide].
  ///
  /// Also checks local device-level flag as fallback.
  bool canGenerateFree() {
    // Local device flag (fallback if server check fails)
    final deviceUsed = _prefs.getBool(_keyDeviceUsedFreeTier) == true;
    if (deviceUsed) {
      Log.info('Free tier blocked - local device flag set');
      return false;
    }
    return getTotalCount() < freeLifetimeLimit;
  }

  /// Check device free tier eligibility on server.
  ///
  /// This is the PRIMARY method for checking if a device can use the free tier.
  /// It queries the server to check if the device fingerprint has been used.
  ///
  /// Use this for anonymous users before generation.
  /// For authenticated users, [checkAndIncrementServerSide] handles both
  /// user-level and device-level checks.
  Future<DeviceCheckResult> checkDeviceFreeTierServerSide() async {
    return _deviceFingerprint.canUseFreeTier();
  }

  /// Mark device as having used free tier (fraud prevention)
  /// Updates BOTH local cache and server-side tracking.
  ///
  /// This survives:
  /// - App reinstalls (server-side tracking)
  /// - Account deletion (device tracking is separate from user data)
  /// - Data clearing (server-side tracking)
  Future<void> markDeviceUsedFreeTier() async {
    // Update local cache (for immediate UI feedback)
    await _prefs.setBool(_keyDeviceUsedFreeTier, true);

    // Update server-side (survives reinstalls)
    await _deviceFingerprint.markFreeTierUsed();

    Log.info('Device marked as used free tier (local + server)');
  }

  /// Check if user can generate (pro tier)
  bool canGeneratePro() {
    return getMonthlyCount() < proMonthlyLimit;
  }

  /// Get remaining free generations (lifetime)
  /// Checks device flag first (survives sign out), then falls back to count.
  int getRemainingFree() {
    // Device flag takes priority - survives sign out and account changes
    final deviceUsed = _prefs.getBool(_keyDeviceUsedFreeTier) == true;
    if (deviceUsed) {
      return 0;
    }
    final used = getTotalCount();
    return (freeLifetimeLimit - used).clamp(0, freeLifetimeLimit);
  }

  /// Get remaining pro generations this month
  int getRemainingProMonthly() {
    final used = getMonthlyCount();
    return (proMonthlyLimit - used).clamp(0, proMonthlyLimit);
  }

  // ===========================================================================
  // SERVER-SIDE ENFORCEMENT (REQUIRED for authenticated users)
  // ===========================================================================

  /// Check limits and increment usage atomically on the server.
  ///
  /// This is the PRIMARY method for usage validation. It performs:
  /// 1. Rate limit check (prevents API abuse)
  /// 2. Device fingerprint check (for free tier - prevents reinstall abuse)
  /// 3. User-level usage check via Supabase RPC (with row-level locking)
  /// 4. Atomic increment if allowed
  ///
  /// Returns [UsageCheckResult] with:
  /// - [allowed]: true if generation can proceed
  /// - [remaining]: remaining generations
  /// - [errorMessage]: user-friendly error if not allowed
  ///
  /// Throws [UsageCheckException] on network/server errors.
  Future<UsageCheckResult> checkAndIncrementServerSide({
    required bool isPro,
  }) async {
    final userId = _userId;
    final supabase = _supabase;

    if (userId == null || supabase == null) {
      Log.warning('Server-side check failed: user not authenticated');
      throw UsageCheckException('Please sign in to continue');
    }

    // 1. Check rate limits first (prevents abuse)
    final rateLimitResult = await _rateLimit.checkRateLimit();
    if (!rateLimitResult.allowed) {
      Log.info('Generation blocked by rate limit', {
        'reason': rateLimitResult.reason?.name,
        'retryAfter': rateLimitResult.retryAfter,
      });
      return UsageCheckResult(
        allowed: false,
        remaining: 0,
        errorMessage: rateLimitResult.errorMessage,
      );
    }

    // 2. For free tier users, check device fingerprint
    // This prevents abuse via account switching or reinstalls
    if (!isPro) {
      final deviceCheck = await _deviceFingerprint.canUseFreeTier();
      if (!deviceCheck.allowed) {
        Log.info('Free tier blocked by device fingerprint', {
          'reason': deviceCheck.reason.name,
        });
        return const UsageCheckResult(
          allowed: false,
          remaining: 0,
          errorMessage:
              'This device has already used its free message. '
              'Upgrade to Pro for unlimited access!',
        );
      }
    }

    final monthKey = _monthString();

    try {
      final response = await supabase.rpc(
        'check_and_increment_usage',
        params: {
          'p_user_id': userId,
          'p_is_pro': isPro,
          'p_month_key': monthKey,
        },
      ).timeout(_timeout);

      final result = response as Map<String, dynamic>;
      final allowed = result['allowed'] as bool? ?? false;
      final totalCount = result['total_count'] as int? ?? 0;
      final monthlyCount = result['monthly_count'] as int? ?? 0;
      final remaining = result['remaining'] as int? ?? 0;
      final limit =
          result['limit'] as int? ??
          (isPro ? proMonthlyLimit : freeLifetimeLimit);

      Log.info('Server-side usage check', {
        'allowed': allowed,
        'totalCount': totalCount,
        'monthlyCount': monthlyCount,
        'remaining': remaining,
        'isPro': isPro,
      });

      // Update local cache to match server (for UI display)
      await _prefs.setInt(_keyTotalCount, totalCount);
      await _prefs.setInt(_keyMonthlyCount, monthlyCount);
      await _prefs.setString(_keyMonthlyDate, monthKey);

      // Mark device as having used free tier (both local + server)
      if (allowed && !isPro) {
        await markDeviceUsedFreeTier();
      }

      if (!allowed) {
        final message = isPro
            ? 'You\'ve reached your monthly limit of $limit messages'
            : 'You\'ve used your free message. Upgrade to Pro for more!';
        return UsageCheckResult(
          allowed: false,
          remaining: 0,
          errorMessage: message,
        );
      }

      return UsageCheckResult(allowed: true, remaining: remaining);
    } catch (e) {
      Log.error('Server-side usage check failed', e);
      throw UsageCheckException(
        'Unable to verify usage. Please check your connection.',
      );
    }
  }

  // ===========================================================================
  // CLIENT-SIDE FALLBACK (for anonymous users only)
  // ===========================================================================

  /// Record a generation - updates local cache AND server
  /// [isPro] - if false, marks device as having used free tier
  ///
  /// NOTE: For authenticated users, use [checkAndIncrementServerSide] instead.
  /// This method is for anonymous users or offline fallback only.
  Future<void> recordGeneration({bool isPro = false}) async {
    // Mark device as having used free tier (survives account deletion)
    if (!isPro) {
      await markDeviceUsedFreeTier();
    }

    final thisMonth = _monthString();

    // Update local cache first (for immediate UI feedback)
    final totalCount = (_prefs.getInt(_keyTotalCount) ?? 0) + 1;
    await _prefs.setInt(_keyTotalCount, totalCount);

    final savedMonth = _prefs.getString(_keyMonthlyDate);
    var monthlyCount = 1;
    if (savedMonth == thisMonth) {
      monthlyCount = (_prefs.getInt(_keyMonthlyCount) ?? 0) + 1;
    }
    await _prefs.setString(_keyMonthlyDate, thisMonth);
    await _prefs.setInt(_keyMonthlyCount, monthlyCount);

    // Sync to server (non-blocking, fire and forget with retry)
    _syncToServer(totalCount, monthlyCount, thisMonth);
  }

  /// Sync usage TO server (called after each generation)
  Future<void> _syncToServer(
    int totalCount,
    int monthlyCount,
    String monthKey,
  ) async {
    final userId = _userId;
    final supabase = _supabase;

    if (userId == null || supabase == null) {
      Log.warning('Cannot sync usage to server: user not authenticated', {
        'totalCount': totalCount,
      });
      return;
    }

    try {
      await supabase.from(_table).upsert({
        'user_id': userId,
        'total_count': totalCount,
        'monthly_count': monthlyCount,
        'month_key': monthKey,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      Log.info('Usage synced to server', {
        'totalCount': totalCount,
        'monthlyCount': monthlyCount,
      });
    } catch (e) {
      // Log but don't fail - local cache is still accurate
      Log.error('Failed to sync usage to server', e);
    }
  }

  // ===========================================================================
  // SYNC OPERATIONS (called on login)
  // ===========================================================================

  /// Sync usage FROM server - call this after user signs in
  ///
  /// This ensures reinstalled apps get the user's existing usage.
  /// Server is source of truth; local cache is updated to match.
  Future<void> syncFromServer() async {
    final userId = _userId;
    final supabase = _supabase;

    if (userId == null || supabase == null) {
      Log.warning('Cannot sync from server: user not authenticated');
      return;
    }

    // Check if we already synced for this user (avoid redundant syncs)
    final lastSyncUserId = _prefs.getString(_keyLastSyncUserId);
    if (lastSyncUserId == userId) {
      Log.info('Usage already synced for this user');
      return;
    }

    try {
      final response = await supabase
          .from(_table)
          .select('total_count, monthly_count, month_key')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        // User has existing usage - restore it
        final serverTotal = response['total_count'] as int? ?? 0;
        final serverMonthly = response['monthly_count'] as int? ?? 0;
        final serverMonthKey = response['month_key'] as String? ?? '';

        // Take the HIGHER of local vs server (prevents gaming by reinstall)
        final localTotal = _prefs.getInt(_keyTotalCount) ?? 0;
        final finalTotal = serverTotal > localTotal ? serverTotal : localTotal;

        await _prefs.setInt(_keyTotalCount, finalTotal);

        // For monthly, only use server value if same month
        final thisMonth = _monthString();
        if (serverMonthKey == thisMonth) {
          final localMonthly = getMonthlyCount();
          final finalMonthly = serverMonthly > localMonthly
              ? serverMonthly
              : localMonthly;
          await _prefs.setInt(_keyMonthlyCount, finalMonthly);
          await _prefs.setString(_keyMonthlyDate, thisMonth);
        }

        Log.info('Usage restored from server', {
          'serverTotal': serverTotal,
          'localTotal': localTotal,
          'finalTotal': finalTotal,
        });

        // If local was higher, sync back to server
        if (localTotal > serverTotal) {
          _syncToServer(finalTotal, getMonthlyCount(), thisMonth);
        }
      } else {
        // New user on server - push local usage if any
        final localTotal = _prefs.getInt(_keyTotalCount) ?? 0;
        if (localTotal > 0) {
          await _syncToServer(localTotal, getMonthlyCount(), _monthString());
          Log.info('Existing local usage pushed to server for new user', {
            'localTotal': localTotal,
          });
        }
      }

      // Mark this user as synced
      await _prefs.setString(_keyLastSyncUserId, userId);
    } catch (e) {
      Log.error('Failed to sync usage from server', e);
      // Continue with local cache - better than blocking
    }
  }

  /// Clear sync marker (call on sign out)
  Future<void> clearSyncMarker() async {
    await _prefs.remove(_keyLastSyncUserId);
  }

  /// Clear ALL usage data (call on sign out - internet cafe test)
  /// Leaves no trace of previous user's activity
  Future<void> clearAllUsage() async {
    await _prefs.remove(_keyTotalCount);
    await _prefs.remove(_keyMonthlyCount);
    await _prefs.remove(_keyMonthlyDate);
    await _prefs.remove(_keyLastSyncUserId);
    Log.info('Usage cleared');
  }

  // ===========================================================================
  // UTILITIES
  // ===========================================================================

  /// Reset monthly usage (for Pro users)
  Future<void> resetMonthlyUsage() async {
    await _prefs.remove(_keyMonthlyCount);
    await _prefs.remove(_keyMonthlyDate);
  }

  String _monthString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// RESULT TYPES
// =============================================================================

/// Result of server-side usage check
class UsageCheckResult {
  const UsageCheckResult({
    required this.allowed,
    required this.remaining,
    this.errorMessage,
  });

  /// Whether the generation is allowed
  final bool allowed;

  /// Remaining generations after this one
  final int remaining;

  /// User-friendly error message if not allowed
  final String? errorMessage;
}

/// Exception thrown when server-side usage check fails
class UsageCheckException implements Exception {
  const UsageCheckException(this.message);

  final String message;

  @override
  String toString() => message;
}
