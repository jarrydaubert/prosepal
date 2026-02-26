import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_fingerprint_service.dart';
import 'log_service.dart';
import 'rate_limit_service.dart';

/// Represents a pending sync operation that failed and needs retry.
///
/// Stored in SharedPreferences as JSON for persistence across app restarts.
class PendingSync {
  PendingSync({
    required this.userId,
    required this.totalCount,
    required this.monthlyCount,
    required this.monthKey,
    required this.createdAt,
    this.retryCount = 0,
  });

  factory PendingSync.fromJson(Map<String, dynamic> json) => PendingSync(
    userId: json['userId'] as String,
    totalCount: json['totalCount'] as int,
    monthlyCount: json['monthlyCount'] as int,
    monthKey: json['monthKey'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
  );

  final String userId;
  final int totalCount;
  final int monthlyCount;
  final String monthKey;
  final DateTime createdAt;
  int retryCount;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'totalCount': totalCount,
    'monthlyCount': monthlyCount,
    'monthKey': monthKey,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  /// Create a copy with incremented retry count.
  PendingSync incrementRetry() => PendingSync(
    userId: userId,
    totalCount: totalCount,
    monthlyCount: monthlyCount,
    monthKey: monthKey,
    createdAt: createdAt,
    retryCount: retryCount + 1,
  );
}

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
  // Pending sync queue persistence
  static const _keyPendingSyncs = 'pending_usage_syncs';

  // Limits
  static const int freeLifetimeLimit = 1;
  static const int proMonthlyLimit = 500;

  /// Network timeout for Supabase calls (prevents indefinite hangs)
  static const _timeout = Duration(seconds: 30);

  // Retry queue configuration
  /// Maximum number of retry attempts before giving up on a sync.
  static const int _maxRetries = 5;

  /// Base delay for exponential backoff (doubles with each retry).
  static const Duration _baseRetryDelay = Duration(seconds: 2);

  /// Maximum age for pending syncs before they're discarded.
  static const Duration _maxPendingSyncAge = Duration(days: 7);

  /// Timer for periodic retry processing.
  Timer? _retryTimer;

  // Supabase table and columns
  static const _table = 'user_usage';

  /// Get Supabase client (may be null if not initialized)
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } on Exception catch (_) {
      return null;
    }
  }

  /// Get current user ID (null if not authenticated)
  String? get _userId => _supabase?.auth.currentUser?.id;

  // ===========================================================================
  // READ OPERATIONS (from local cache for speed)
  // ===========================================================================

  /// Get total all-time generation count
  int getTotalCount() => _prefs.getInt(_keyTotalCount) ?? 0;

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
    final deviceUsed = _prefs.getBool(_keyDeviceUsedFreeTier) ?? false;
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
  Future<DeviceCheckResult> checkDeviceFreeTierServerSide() async =>
      _deviceFingerprint.canUseFreeTier();

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
  bool canGeneratePro() => getMonthlyCount() < proMonthlyLimit;

  /// Get remaining free generations (lifetime)
  /// Checks device flag first (survives sign out), then falls back to count.
  int getRemainingFree() {
    // Device flag takes priority - survives sign out and account changes
    final deviceUsed = _prefs.getBool(_keyDeviceUsedFreeTier) ?? false;
    if (deviceUsed) {
      return 0;
    }
    final used = getTotalCount();
    return (freeLifetimeLimit - used).clamp(0, freeLifetimeLimit);
  }

  /// Check if this device has used the free tier before.
  /// Survives sign out, app reinstalls (server-side), and account deletion.
  /// Use this to detect returning users for auto-restore flow.
  bool hasDeviceUsedFreeTier() =>
      _prefs.getBool(_keyDeviceUsedFreeTier) ?? false;

  /// Sync device state from server during app startup.
  /// Updates local cache to match server - call this in splash screen.
  /// This ensures accurate state is shown immediately after reinstall.
  Future<void> syncDeviceStateFromServer() async {
    try {
      final result = await checkDeviceFreeTierServerSide().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          Log.warning('Device state sync timed out after 5s');
          // Return "allowed" on timeout - graceful degradation
          return const DeviceCheckResult(
            allowed: true,
            reason: DeviceCheckReason.serverUnavailable,
          );
        },
      );
      Log.info('Device state synced from server', {
        'allowed': result.allowed,
        'reason': result.reason.toString(),
      });

      // If server says device already used free tier, update local cache
      if (!result.allowed && result.reason == DeviceCheckReason.alreadyUsed) {
        await _prefs.setBool(_keyDeviceUsedFreeTier, true);
        Log.info('Local cache updated: device has used free tier');
      }
    } on Exception catch (e) {
      Log.warning('Failed to sync device state from server', {'error': '$e'});
      // Continue without syncing - local cache may be stale but app still works
    }
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
      throw const UsageCheckException('Please sign in to continue');
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
              'Upgrade to Pro for 500 messages/month!',
        );
      }
    }

    final monthKey = _monthString();

    try {
      final response = await supabase
          .rpc(
            'check_and_increment_usage',
            params: {
              'p_user_id': userId,
              'p_is_pro': isPro,
              'p_month_key': monthKey,
            },
          )
          .timeout(_timeout);

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
            ? "You've reached your monthly limit of $limit messages"
            : "You've used your free message. Upgrade to Pro for more!";
        return UsageCheckResult(
          allowed: false,
          remaining: 0,
          errorMessage: message,
        );
      }

      return UsageCheckResult(allowed: true, remaining: remaining);
    } on PostgrestException catch (e) {
      Log.error('Server-side usage check failed', e);
      throw const UsageCheckException(
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

  /// Sync usage TO server (called after each generation).
  ///
  /// Uses RPC instead of direct upsert to prevent abuse (users can't reset counts).
  /// The RPC only allows INCREASING counts, never decreasing.
  ///
  /// On failure, adds to retry queue for later processing.
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
      // Queue for retry when user signs in
      await _addPendingSync(
        PendingSync(
          userId: userId ?? 'anonymous',
          totalCount: totalCount,
          monthlyCount: monthlyCount,
          monthKey: monthKey,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }

    try {
      await supabase.rpc(
        'sync_user_usage',
        params: {
          'p_user_id': userId,
          'p_total_count': totalCount,
          'p_monthly_count': monthlyCount,
          'p_month_key': monthKey,
        },
      );

      Log.info('Usage synced to server', {
        'totalCount': totalCount,
        'monthlyCount': monthlyCount,
      });
    } on PostgrestException catch (e) {
      // Network or server error - queue for retry
      Log.warning('Failed to sync usage to server, queuing for retry', {
        'error': e.message,
        'totalCount': totalCount,
      });
      await _addPendingSync(
        PendingSync(
          userId: userId,
          totalCount: totalCount,
          monthlyCount: monthlyCount,
          monthKey: monthKey,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  // ===========================================================================
  // RETRY QUEUE MANAGEMENT
  // ===========================================================================

  /// Add a sync operation to the pending queue.
  Future<void> _addPendingSync(PendingSync sync) async {
    final pending = await _getPendingSyncs();

    // Deduplicate: if we have a newer sync for the same user, keep only the newest
    pending.removeWhere((s) => s.userId == sync.userId);
    pending.add(sync);

    await _savePendingSyncs(pending);
    Log.info('Added pending sync to queue', {
      'queueSize': pending.length,
      'userId': sync.userId.substring(0, 8),
    });

    // Schedule retry processing
    _scheduleRetryProcessing();
  }

  /// Get all pending syncs from storage.
  Future<List<PendingSync>> _getPendingSyncs() async {
    final json = _prefs.getString(_keyPendingSyncs);
    if (json == null || json.isEmpty) return [];

    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => PendingSync.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception catch (e) {
      Log.warning('Failed to parse pending syncs', {'error': '$e'});
      return [];
    }
  }

  /// Save pending syncs to storage.
  Future<void> _savePendingSyncs(List<PendingSync> syncs) async {
    final json = jsonEncode(syncs.map((s) => s.toJson()).toList());
    await _prefs.setString(_keyPendingSyncs, json);
  }

  /// Schedule retry processing with exponential backoff.
  void _scheduleRetryProcessing() {
    // Cancel existing timer to avoid duplicates
    _retryTimer?.cancel();

    // Schedule retry after base delay
    _retryTimer = Timer(_baseRetryDelay, () {
      processPendingSyncs();
    });
  }

  /// Process all pending syncs with retry logic.
  ///
  /// Call this on app startup and when connectivity is restored.
  /// Syncs are processed with exponential backoff and discarded after
  /// [_maxRetries] attempts or if older than [_maxPendingSyncAge].
  Future<void> processPendingSyncs() async {
    final supabase = _supabase;
    if (supabase == null) {
      Log.info('Cannot process pending syncs: Supabase not available');
      return;
    }

    final pending = await _getPendingSyncs();
    if (pending.isEmpty) return;

    Log.info('Processing pending syncs', {'count': pending.length});

    final now = DateTime.now();
    final stillPending = <PendingSync>[];
    var successCount = 0;
    var discardedCount = 0;

    for (final sync in pending) {
      // Discard stale syncs
      if (now.difference(sync.createdAt) > _maxPendingSyncAge) {
        Log.info('Discarding stale pending sync', {
          'userId': sync.userId.substring(0, 8),
          'age': now.difference(sync.createdAt).inDays,
        });
        discardedCount++;
        continue;
      }

      // Discard after max retries
      if (sync.retryCount >= _maxRetries) {
        Log.warning('Discarding pending sync after max retries', {
          'userId': sync.userId.substring(0, 8),
          'retries': sync.retryCount,
        });
        discardedCount++;
        continue;
      }

      // Skip syncs for other users (will process when they sign in)
      final currentUserId = _userId;
      if (sync.userId != currentUserId && sync.userId != 'anonymous') {
        stillPending.add(sync);
        continue;
      }

      // Update anonymous syncs with current user ID
      final effectiveUserId =
          sync.userId == 'anonymous' && currentUserId != null
          ? currentUserId
          : sync.userId;

      if (effectiveUserId == 'anonymous') {
        // Still no user - keep in queue
        stillPending.add(sync);
        continue;
      }

      // Attempt sync with exponential backoff delay
      final delay = _baseRetryDelay * (1 << sync.retryCount);
      await Future<void>.delayed(delay);

      try {
        await supabase.rpc(
          'sync_user_usage',
          params: {
            'p_user_id': effectiveUserId,
            'p_total_count': sync.totalCount,
            'p_monthly_count': sync.monthlyCount,
            'p_month_key': sync.monthKey,
          },
        );

        successCount++;
        Log.info('Pending sync succeeded', {
          'userId': effectiveUserId.substring(0, 8),
          'totalCount': sync.totalCount,
          'retryCount': sync.retryCount,
        });
      } on PostgrestException catch (e) {
        Log.warning('Pending sync retry failed', {
          'error': e.message,
          'retryCount': sync.retryCount,
        });
        stillPending.add(sync.incrementRetry());
      }
    }

    // Save remaining pending syncs
    await _savePendingSyncs(stillPending);

    Log.info('Pending sync processing complete', {
      'success': successCount,
      'discarded': discardedCount,
      'remaining': stillPending.length,
    });

    // Schedule another retry if there are still pending syncs
    if (stillPending.isNotEmpty) {
      _scheduleRetryProcessing();
    }
  }

  /// Get count of pending syncs (for diagnostics).
  Future<int> getPendingSyncCount() async {
    final pending = await _getPendingSyncs();
    return pending.length;
  }

  /// Clear all pending syncs (for testing or data reset).
  Future<void> clearPendingSyncs() async {
    _retryTimer?.cancel();
    await _prefs.remove(_keyPendingSyncs);
    Log.info('Pending syncs cleared');
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

        // If user has account usage, mark device as used (prevents "1 free" showing
        // when user reinstalls and signs in with existing account usage)
        if (finalTotal > 0 && !hasDeviceUsedFreeTier()) {
          await _prefs.setBool(_keyDeviceUsedFreeTier, true);
          Log.info('Device marked used (user has account usage)');
        }

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

      // Process any pending syncs that were queued while offline
      await processPendingSyncs();
    } on PostgrestException catch (e) {
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
