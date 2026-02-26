import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Prosepal "Spotlight Cinematic" Typography
///
/// - Playfair Display: Elegant serif for headings
/// - Inter: Clean sans-serif for body text
class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => TextTheme(
    // Display - Playfair Display (large headers)
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 40,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.playfairDisplay(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    displaySmall: GoogleFonts.playfairDisplay(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),

    // Headlines - Playfair Display
    headlineLarge: GoogleFonts.playfairDisplay(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.playfairDisplay(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    headlineSmall: GoogleFonts.playfairDisplay(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),

    // Titles - Inter (section headers, card titles)
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.15,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.1,
    ),

    // Body - Inter
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.6,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.6,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textHint,
      height: 1.5,
    ),

    // Labels - Inter
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.textHint,
      letterSpacing: 0.5,
    ),
  );
}
