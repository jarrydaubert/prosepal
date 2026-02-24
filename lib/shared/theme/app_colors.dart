import 'package:flutter/material.dart';

/// Prosepal Material 3 Color System
///
/// Coral primary with gold reserved for Pro accents.
///
/// WCAG Contrast Ratios:
/// - textPrimary (#FFF) on bgDeep (#050505): 21:1 ✓
/// - textSecondary (#888) on bgDeep: 5.6:1 ✓
/// - accentGold (#FBBF24) on bgDeep: 11.3:1 ✓
class AppColors {
  AppColors._();

  // ===========================================================================
  // BACKGROUNDS
  // ===========================================================================

  /// Deepest background - near black
  static const Color bgDeep = Color(0xFF050505);

  /// Standard dark background
  static const Color bgDark = Color(0xFF0A0A0A);

  /// Card/surface background
  static const Color surface = Color(0xFF111111);

  /// Elevated surface (modals, sheets)
  static const Color surfaceElevated = Color(0xFF1A1A1A);

  /// Surface variant for subtle differentiation
  static const Color surfaceVariant = Color(0xFF1F1F1F);

  /// Splash screen background
  static const Color splash = Color(0xFF050505);

  /// Main app background
  static const Color background = Color(0xFF050505);

  // ===========================================================================
  // BRAND COLORS - Coral
  // ===========================================================================

  /// Primary brand color - Coral
  static const Color primary = Color(0xFFD4736B);

  /// Lighter coral for highlights
  static const Color primaryLight = Color(0xFFFCE9E7);

  /// Darker coral for pressed states
  static const Color primaryDark = Color(0xFFB95E57);

  /// Pro gold for badges and payment CTAs
  static const Color proGold = Color(0xFFFBBF24);

  /// Darker gold for pressed states
  static const Color proGoldDark = Color(0xFFC4960A);

  /// Legacy alias for coral
  static const Color accentRose = primary;

  // ===========================================================================
  // TEXT COLORS
  // ===========================================================================

  /// Primary text - Pure white
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text - Medium gray
  static const Color textSecondary = Color(0xFF888888);

  /// Dim/hint text - Dark gray
  static const Color textHint = Color(0xFF555555);

  /// Text on primary (purple) backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Text on pro gold backgrounds
  static const Color textOnPro = Color(0xFF1C1B1F);

  /// Text on light cards/surfaces
  static const Color textOnLight = Color(0xFF1C1B1F);

  /// Text on dark backgrounds (same as primary for dark theme)
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ===========================================================================
  // BORDERS
  // ===========================================================================

  /// Subtle border - 5% white
  static const Color borderSubtle = Color(0x0DFFFFFF);

  /// Light border - 10% white
  static const Color borderLight = Color(0x1AFFFFFF);

  /// Medium border - 15% white
  static const Color borderMedium = Color(0x26FFFFFF);

  // ===========================================================================
  // SEMANTIC COLORS
  // ===========================================================================

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ===========================================================================
  // OPACITY
  // ===========================================================================

  /// Standard disabled state opacity
  static const double disabledOpacity = 0.38;

  // ===========================================================================
  // GRADIENTS
  // ===========================================================================

  /// Primary brand gradient (coral)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Spotlight gradient for hero effects
  static const RadialGradient spotlightGradient = RadialGradient(
    center: Alignment.topCenter,
    radius: 1.5,
    colors: [
      Color(0x33D4736B), // Coral 20%
      Color(0x00D4736B), // Coral 0%
    ],
  );

  /// Background gradient (subtle)
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), bgDeep],
  );

  /// Hero section gradient
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111111), bgDeep, bgDeep],
    stops: [0.0, 0.5, 1.0],
  );
}
