import 'package:flutter/material.dart';

/// Prosepal color palette - warm, friendly, trustworthy
class AppColors {
  AppColors._();

  // Primary - Warm coral/salmon (friendly, approachable)
  static const Color primary = Color(0xFFE57373);
  static const Color primaryLight = Color(0xFFFFAB91);
  static const Color primaryDark = Color(0xFFD32F2F);

  // Secondary - Soft teal (calm, trustworthy)
  static const Color secondary = Color(0xFF4DB6AC);
  static const Color secondaryLight = Color(0xFF80CBC4);
  static const Color secondaryDark = Color(0xFF00897B);

  // Accent - Warm gold (premium feel)
  static const Color accent = Color(0xFFFFD54F);
  static const Color accentDark = Color(0xFFFFC107);

  // Backgrounds
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // Occasion colors (for visual distinction)
  static const Color birthday = Color(0xFFE91E63);
  static const Color thankYou = Color(0xFF4CAF50);
  static const Color sympathy = Color(0xFF7E57C2);
  static const Color wedding = Color(0xFFEC407A);
  static const Color graduation = Color(0xFF5C6BC0);
  static const Color baby = Color(0xFF26C6DA);
  static const Color getWell = Color(0xFFFFCA28);
  static const Color anniversary = Color(0xFFEF5350);
  static const Color congrats = Color(0xFFFF7043);
  static const Color apology = Color(0xFF78909C);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );
}
