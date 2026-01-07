import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'log_service.dart';

/// Tracks generation usage with server-side persistence via Supabase.
///
/// Free tier usage is stored in Supabase to survive app reinstalls.
/// Local cache (SharedPreferences) provides fast reads; server is source of truth.
///
/// Flow:
/// 1. User signs in -> syncFromServer() fetches their usage
/// 2. User generates -> recordGeneration() updates both local + server
/// 3. User reinstalls -> signs in -> gets their existing usage from server
class UsageService {
  UsageService(this._prefs);

  final SharedPreferences _prefs;

  // Local cache keys
  static const _keyTotalCount = 'total_generation_count';
  static const _keyMonthlyCount = 'monthly_generation_count';
  static const _keyMonthlyDate = 'monthly_generation_month';
  static const _keyLastSyncUserId = 'last_sync_user_id';

  // Limits
  static const int freeLifetimeLimit = 1;
  static const int proMonthlyLimit = 500;

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
  bool canGenerateFree() {
    return getTotalCount() < freeLifetimeLimit;
  }

  /// Check if user can generate (pro tier)
  bool canGeneratePro() {
    return getMonthlyCount() < proMonthlyLimit;
  }

  /// Get remaining free generations (lifetime)
  int getRemainingFree() {
    final used = getTotalCount();
    return (freeLifetimeLimit - used).clamp(0, freeLifetimeLimit);
  }

  /// Get remaining pro generations this month
  int getRemainingProMonthly() {
    final used = getMonthlyCount();
    return (proMonthlyLimit - used).clamp(0, proMonthlyLimit);
  }

  // ===========================================================================
  // WRITE OPERATIONS (local + server)
  // ===========================================================================

  /// Record a generation - updates local cache AND server
  Future<void> recordGeneration() async {
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
          .select()
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
