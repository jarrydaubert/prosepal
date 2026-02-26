import 'package:shared_preferences/shared_preferences.dart';

class UsageService {
  UsageService(this._prefs);

  final SharedPreferences _prefs;

  static const _keyTotalCount = 'total_generation_count';
  static const _keyMonthlyCount = 'monthly_generation_count';
  static const _keyMonthlyDate = 'monthly_generation_month';

  // Limits
  static const int freeLifetimeLimit = 3; // 3 total ever, then paywall
  static const int proDailyLimit = 50;
  static const int proMonthlyLimit = 500;

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

  /// Record a generation
  Future<void> recordGeneration() async {
    final thisMonth = _monthString();

    // Increment total count
    final totalCount = _prefs.getInt(_keyTotalCount) ?? 0;
    await _prefs.setInt(_keyTotalCount, totalCount + 1);

    // Increment monthly count (for Pro fair use)
    final savedMonth = _prefs.getString(_keyMonthlyDate);
    var monthlyCount = 0;
    if (savedMonth == thisMonth) {
      monthlyCount = _prefs.getInt(_keyMonthlyCount) ?? 0;
    }
    await _prefs.setString(_keyMonthlyDate, thisMonth);
    await _prefs.setInt(_keyMonthlyCount, monthlyCount + 1);
  }

  /// Reset monthly usage (for Pro users, called on subscription renewal)
  Future<void> resetMonthlyUsage() async {
    await _prefs.remove(_keyMonthlyCount);
    await _prefs.remove(_keyMonthlyDate);
  }

  String _monthString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
