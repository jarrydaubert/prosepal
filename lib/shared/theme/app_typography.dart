import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Prosepal "Spotlight Cinematic" Typography
///
/// - Playfair Display: Elegant serif for headings
/// - Inter: Clean sans-serif for body text
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(ColorScheme scheme) => TextTheme(
    // Display - Playfair Display (large headers)
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 40,
      fontWeight: FontWeight.w400,
      color: scheme.onSurface,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.playfairDisplay(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      color: scheme.onSurface,
    ),
    displaySmall: GoogleFonts.playfairDisplay(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      color: scheme.onSurface,
    ),

    // Headlines - Playfair Display
    headlineLarge: GoogleFonts.playfairDisplay(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      color: scheme.onSurface,
    ),
    headlineMedium: GoogleFonts.playfairDisplay(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: scheme.onSurface,
    ),
    headlineSmall: GoogleFonts.playfairDisplay(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: scheme.onSurface,
    ),

    // Titles - Inter (section headers, card titles)
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      letterSpacing: 0.15,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      letterSpacing: 0.1,
    ),

    // Body - Inter
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: scheme.onSurface,
      height: 1.6,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
      height: 1.6,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: scheme.outline,
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
      color: scheme.outline,
      letterSpacing: 0.5,
    ),
  );
}
