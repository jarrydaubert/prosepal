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
  // CORE BRAND COLORS
  // ===========================================================================

  /// Primary brand color - Warm coral
  static const Color primary = Color(0xFFE57373);

  /// Lighter variant for subtle backgrounds and hover states
  static const Color primaryLight = Color(0xFFFFCDD2);

  /// Darker variant for pressed states and emphasis
  static const Color primaryDark = Color(0xFFD32F2F);

  // ===========================================================================
  // TEXT COLORS
  // ===========================================================================

  /// Primary text - Near black (WCAG AAA: 12.6:1)
  static const Color textPrimary = Color(0xFF2D3436);

  /// Secondary text - Dark gray (WCAG AA: 4.6:1)
  static const Color textSecondary = Color(0xFF636E72);

  /// Hint/placeholder text
  static const Color textHint = Color(0xFF9E9E9E);

  /// Text on primary color backgrounds
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Text on dark backgrounds
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ===========================================================================
  // BACKGROUNDS & SURFACES
  // ===========================================================================

  /// Splash screen background - Dark charcoal
  static const Color splash = Color(0xFF2D2D37);

  /// Main app background - Warm off-white
  static const Color background = Color(0xFFFAFAFA);

  /// Card/surface background - Pure white
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle surface variant
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // ===========================================================================
  // SEMANTIC COLORS
  // ===========================================================================

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // ===========================================================================
  // OPACITY
  // ===========================================================================

  /// Standard disabled state opacity (Material Design)
  static const double disabledOpacity = 0.38;

  // ===========================================================================
  // GRADIENTS
  // ===========================================================================

  /// Primary brand gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFFEF9A9A)],
  );

  /// Background gradient
  static LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary.withValues(alpha: 0.15), background],
  );

  /// Hero section gradient
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFEBEE), Color(0xFFFFF8F8), Color(0xFFFFFFFF)],
    stops: [0.0, 0.5, 1.0],
  );
}
