import 'package:shared_preferences/shared_preferences.dart';

class UsageService {
  UsageService(this._prefs);

  final SharedPreferences _prefs;

  static const _keyDailyCount = 'daily_generation_count';
  static const _keyDailyDate = 'daily_generation_date';
  static const _keyMonthlyCount = 'monthly_generation_count';
  static const _keyMonthlyDate = 'monthly_generation_month';
  static const _keyTotalCount = 'total_generation_count';

  // Limits
  static const int freeDailyLimit = 3;
  static const int proDailyLimit = 50;
  static const int proMonthlyLimit = 500;

  /// Get today's generation count
  int getDailyCount() {
    final today = _todayString();
    final savedDate = _prefs.getString(_keyDailyDate);

    if (savedDate != today) {
      // New day, reset count
      return 0;
    }

    return _prefs.getInt(_keyDailyCount) ?? 0;
  }

  /// Get this month's generation count
  int getMonthlyCount() {
    final thisMonth = _monthString();
    final savedMonth = _prefs.getString(_keyMonthlyDate);

    if (savedMonth != thisMonth) {
      // New month, reset count
      return 0;
    }

    return _prefs.getInt(_keyMonthlyCount) ?? 0;
  }

  /// Get total all-time generation count
  int getTotalCount() {
    return _prefs.getInt(_keyTotalCount) ?? 0;
  }

  /// Check if user can generate (free tier)
  bool canGenerateFree() {
    return getDailyCount() < freeDailyLimit;
  }

  /// Check if user can generate (pro tier)
  bool canGeneratePro() {
    return getDailyCount() < proDailyLimit &&
        getMonthlyCount() < proMonthlyLimit;
  }

  /// Get remaining free generations today
  int getRemainingFree() {
    final used = getDailyCount();
    return (freeDailyLimit - used).clamp(0, freeDailyLimit);
  }

  /// Get remaining pro generations today
  int getRemainingProDaily() {
    final used = getDailyCount();
    return (proDailyLimit - used).clamp(0, proDailyLimit);
  }

  /// Get remaining pro generations this month
  int getRemainingProMonthly() {
    final used = getMonthlyCount();
    return (proMonthlyLimit - used).clamp(0, proMonthlyLimit);
  }

  /// Record a generation
  Future<void> recordGeneration() async {
    final today = _todayString();
    final thisMonth = _monthString();

    // Check if we need to reset daily count
    final savedDate = _prefs.getString(_keyDailyDate);
    int dailyCount = 0;
    if (savedDate == today) {
      dailyCount = _prefs.getInt(_keyDailyCount) ?? 0;
    }

    // Check if we need to reset monthly count
    final savedMonth = _prefs.getString(_keyMonthlyDate);
    int monthlyCount = 0;
    if (savedMonth == thisMonth) {
      monthlyCount = _prefs.getInt(_keyMonthlyCount) ?? 0;
    }

    // Increment counts
    await _prefs.setString(_keyDailyDate, today);
    await _prefs.setInt(_keyDailyCount, dailyCount + 1);

    await _prefs.setString(_keyMonthlyDate, thisMonth);
    await _prefs.setInt(_keyMonthlyCount, monthlyCount + 1);

    final totalCount = _prefs.getInt(_keyTotalCount) ?? 0;
    await _prefs.setInt(_keyTotalCount, totalCount + 1);
  }

  /// Reset all usage (for testing or subscription changes)
  Future<void> resetUsage() async {
    await _prefs.remove(_keyDailyCount);
    await _prefs.remove(_keyDailyDate);
    await _prefs.remove(_keyMonthlyCount);
    await _prefs.remove(_keyMonthlyDate);
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _monthString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
