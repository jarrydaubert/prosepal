import 'package:flutter/material.dart';

/// Prosepal Brand Color System
///
/// Simplified 3-color palette for consistency:
/// - Primary (Coral): CTAs, links, selection states, brand identity
/// - Text (Charcoal): All text for maximum readability
/// - Background (Warm White): Clean, warm canvas
///
/// WCAG AA Contrast Ratios:
/// - textPrimary on background: 12.6:1 ✓
/// - textSecondary on background: 4.6:1 ✓
/// - primary on white: 3.2:1 (use for large text/icons only)
/// - textOnPrimary on primary: 4.5:1 ✓
class AppColors {
  AppColors._();

  // ===========================================================================
  // CORE BRAND COLORS (Use these 95% of the time)
  // ===========================================================================

  /// Primary brand color - Warm coral
  /// Use for: CTAs, links, selected states, icons, brand moments
  static const Color primary = Color(0xFFE57373);

  /// Lighter variant for subtle backgrounds and hover states
  static const Color primaryLight = Color(0xFFFFCDD2);

  /// Darker variant for pressed states and emphasis
  static const Color primaryDark = Color(0xFFD32F2F);

  // ===========================================================================
  // TEXT COLORS (High contrast for accessibility)
  // ===========================================================================

  /// Primary text - Near black for maximum readability
  /// Contrast ratio on white: 12.6:1 (WCAG AAA)
  static const Color textPrimary = Color(0xFF2D3436);

  /// Secondary text - Dark gray for supporting content
  /// Contrast ratio on white: 4.6:1 (WCAG AA)
  static const Color textSecondary = Color(0xFF636E72);

  /// Hint/placeholder text - Medium gray
  /// Use sparingly, only for placeholders
  static const Color textHint = Color(0xFF9E9E9E);

  /// Text on primary color backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Text on dark backgrounds (splash, privacy screen)
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ===========================================================================
  // SPLASH / LOADING COLORS
  // ===========================================================================

  /// Splash screen background - Dark charcoal matching logo
  /// RGB: 45, 45, 55
  static const Color splash = Color(0xFF2D2D37);

  // ===========================================================================
  // BACKGROUNDS & SURFACES
  // ===========================================================================

  /// Main app background - Warm off-white
  static const Color background = Color(0xFFFAFAFA);

  /// Card/surface background - Pure white
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle surface variant for sections/cards
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // ===========================================================================
  // SEMANTIC COLORS (Use only for specific purposes)
  // ===========================================================================

  /// Success states, confirmations
  static const Color success = Color(0xFF4CAF50);

  /// Warning states, caution
  static const Color warning = Color(0xFFFF9800);

  /// Error states, destructive actions
  static const Color error = Color(0xFFE53935);

  /// Informational states
  static const Color info = Color(0xFF2196F3);

  // ===========================================================================
  // OCCASION COLORS
  // ===========================================================================
  // Occasion-specific colors are now defined in the Occasion enum with
  // explicit per-variant opacity values (reorder-safe).
  // See: lib/core/models/occasion.dart

  // ===========================================================================
  // GRADIENTS
  // ===========================================================================

  /// Primary brand gradient - use for CTAs and hero moments
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFFEF9A9A)],
  );

  /// Bold background gradient - for screen backgrounds
  static LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary.withValues(alpha: 0.15), background],
  );

  /// Hero section gradient - bolder for key screens
  static LinearGradient get heroGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFEBEE), // primaryLight tint
      Color(0xFFFFF8F8),
      Color(0xFFFFFFFF),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ===========================================================================
  // LEGACY SUPPORT (Deprecated - remove after migration)
  // ===========================================================================

  @Deprecated('Use primary instead')
  static const Color secondary = Color(0xFF636E72);

  @Deprecated('Use primaryLight instead')
  static const Color secondaryLight = Color(0xFFB2BEC3);

  @Deprecated('Use textSecondary instead')
  static const Color secondaryDark = Color(0xFF2D3436);

  @Deprecated('Use primary instead')
  static const Color accent = Color(0xFFE57373);

  @Deprecated('Use primaryDark instead')
  static const Color accentDark = Color(0xFFD32F2F);

  // Legacy occasion colors - now all map to primary
  @Deprecated('Use occasionBackground(index) instead')
  static const Color birthday = primary;
  @Deprecated('Use occasionBackground(index) instead')
  static const Color thankYou = primary;
  @Deprecated('Use occasionBackground(index) instead')
  static const Color sympathy = primary;
  @Deprecated('Use occasionBackground(index) instead')
  static const Color wedding = primary;
  @Deprecated('Use occasionBackground(index) instead')
  static const Color graduation = primary;
  @Deprecated('Use occasionBackground(index) instead')
  static const Color baby = primary;
  @Deprecated('Use occasionBackground(index) instead')
  static const Color getWell = primary;
  @Deprecated('Use occasionBackground(index) instead')
  static const Color anniversary = primary;
  @Deprecated('Use occasionBackground(index) instead')
  static const Color congrats = primary;
  @Deprecated('Use occasionBackground(index) instead')
  static const Color apology = primary;

  @Deprecated('Use primaryGradient instead')
  static const LinearGradient premiumGradient = primaryGradient;
}
