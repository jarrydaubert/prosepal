import 'package:flutter/material.dart';

/// Prosepal Material 3 Color System
///
/// Coral primary with gold reserved for Pro accents.
///
/// WCAG Contrast Ratios are validated during visual QA and golden review.
class AppColors {
  AppColors._();

  // ===========================================================================
  // BACKGROUNDS
  // ===========================================================================

  /// Deepest background - slate charcoal
  static const Color bgDeep = Color(0xFF151C26);

  /// Standard dark background
  static const Color bgDark = Color(0xFF1D2633);

  /// Card/surface background
  static const Color surface = Color(0xFF222E3D);

  /// Elevated surface (modals, sheets)
  static const Color surfaceElevated = Color(0xFF283648);

  /// Surface variant for subtle differentiation
  static const Color surfaceVariant = Color(0xFF324458);

  /// Light surface used for cards on dark backgrounds
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Muted light surface for badges/placeholders
  static const Color surfaceLightMuted = Color(0xFFF4F4F4);

  /// Splash screen background
  static const Color splash = bgDark;

  /// Main app background
  static const Color background = bgDark;

  // ===========================================================================
  // BRAND COLORS - Coral
  // ===========================================================================

  /// Primary brand color - Coral
  static const Color primary = Color(0xFFD4736B);

  /// Lighter coral for highlights
  static const Color primaryLight = Color(0xFFFCE9E7);

  /// Darker coral for pressed states
  static const Color primaryDark = Color(0xFFA5564F);

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

  /// Secondary text on dark surfaces
  static const Color textSecondary = Color(0xFFB1BBC8);

  /// Dim/hint text on dark surfaces
  static const Color textHint = Color(0xFF8B96A6);

  /// Text on primary (purple) backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Text on pro gold backgrounds
  static const Color textOnPro = Color(0xFF1C1B1F);

  /// Text on light cards/surfaces
  static const Color textOnLight = Color(0xFF1C1B1F);

  /// Secondary text on light cards/surfaces
  static const Color textOnLightSecondary = Color(0xFF666666);

  /// Hint text on light cards/surfaces
  static const Color textOnLightHint = Color(0xFF727272);

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

  /// Border color for light cards/surfaces
  static const Color borderOnLight = Color(0xFFD9D9D9);

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
    colors: [bgDark, bgDeep],
  );

  /// Hero section gradient
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, bgDeep, bgDeep],
    stops: [0.0, 0.5, 1.0],
  );
}
