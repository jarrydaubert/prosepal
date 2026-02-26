/// Animation duration tokens for consistent timing across the app
class AppDurations {
  AppDurations._();

  /// Quick micro-interactions (button press, icon change)
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transitions (fade, slide)
  static const Duration normal = Duration(milliseconds: 250);

  /// Emphasized animations (page transitions, overlays)
  static const Duration slow = Duration(milliseconds: 400);

  /// Stagger delay for list items
  static const Duration stagger = Duration(milliseconds: 40);
}
