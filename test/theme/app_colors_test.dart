import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/shared/theme/app_colors.dart';

void main() {
  group('AppColors primary palette', () {
    test('should have primary color defined', () {
      expect(AppColors.primary, isA<Color>());
      expect(AppColors.primary, equals(const Color(0xFFE57373)));
    });

    test('should have primaryLight color defined', () {
      expect(AppColors.primaryLight, isA<Color>());
      expect(AppColors.primaryLight, equals(const Color(0xFFFFAB91)));
    });

    test('should have primaryDark color defined', () {
      expect(AppColors.primaryDark, isA<Color>());
      expect(AppColors.primaryDark, equals(const Color(0xFFD32F2F)));
    });
  });

  group('AppColors secondary palette', () {
    test('should have secondary color defined', () {
      expect(AppColors.secondary, isA<Color>());
      expect(AppColors.secondary, equals(const Color(0xFF4DB6AC)));
    });

    test('should have secondaryLight color defined', () {
      expect(AppColors.secondaryLight, isA<Color>());
    });

    test('should have secondaryDark color defined', () {
      expect(AppColors.secondaryDark, isA<Color>());
    });
  });

  group('AppColors accent palette', () {
    test('should have accent color defined', () {
      expect(AppColors.accent, isA<Color>());
    });

    test('should have accentDark color defined', () {
      expect(AppColors.accentDark, isA<Color>());
    });
  });

  group('AppColors backgrounds', () {
    test('should have background color defined', () {
      expect(AppColors.background, isA<Color>());
    });

    test('should have surface color defined', () {
      expect(AppColors.surface, isA<Color>());
    });

    test('should have surfaceVariant color defined', () {
      expect(AppColors.surfaceVariant, isA<Color>());
    });
  });

  group('AppColors text colors', () {
    test('should have textPrimary color defined', () {
      expect(AppColors.textPrimary, isA<Color>());
    });

    test('should have textSecondary color defined', () {
      expect(AppColors.textSecondary, isA<Color>());
    });

    test('should have textHint color defined', () {
      expect(AppColors.textHint, isA<Color>());
    });

    test('should have textOnPrimary color defined', () {
      expect(AppColors.textOnPrimary, isA<Color>());
      expect(AppColors.textOnPrimary, equals(const Color(0xFFFFFFFF)));
    });
  });

  group('AppColors semantic colors', () {
    test('should have success color defined', () {
      expect(AppColors.success, isA<Color>());
    });

    test('should have warning color defined', () {
      expect(AppColors.warning, isA<Color>());
    });

    test('should have error color defined', () {
      expect(AppColors.error, isA<Color>());
    });

    test('should have info color defined', () {
      expect(AppColors.info, isA<Color>());
    });
  });

  group('AppColors occasion colors', () {
    test('should have birthday color defined', () {
      expect(AppColors.birthday, isA<Color>());
    });

    test('should have thankYou color defined', () {
      expect(AppColors.thankYou, isA<Color>());
    });

    test('should have sympathy color defined', () {
      expect(AppColors.sympathy, isA<Color>());
    });

    test('should have wedding color defined', () {
      expect(AppColors.wedding, isA<Color>());
    });

    test('should have graduation color defined', () {
      expect(AppColors.graduation, isA<Color>());
    });

    test('should have baby color defined', () {
      expect(AppColors.baby, isA<Color>());
    });

    test('should have getWell color defined', () {
      expect(AppColors.getWell, isA<Color>());
    });

    test('should have anniversary color defined', () {
      expect(AppColors.anniversary, isA<Color>());
    });

    test('should have congrats color defined', () {
      expect(AppColors.congrats, isA<Color>());
    });

    test('should have apology color defined', () {
      expect(AppColors.apology, isA<Color>());
    });

    test('all occasion colors should be unique', () {
      final occasionColors = [
        AppColors.birthday,
        AppColors.thankYou,
        AppColors.sympathy,
        AppColors.wedding,
        AppColors.graduation,
        AppColors.baby,
        AppColors.getWell,
        AppColors.anniversary,
        AppColors.congrats,
        AppColors.apology,
      ];
      final uniqueColors = occasionColors.toSet();
      expect(uniqueColors.length, equals(occasionColors.length));
    });
  });

  group('AppColors gradients', () {
    test('should have primaryGradient defined', () {
      expect(AppColors.primaryGradient, isA<LinearGradient>());
      expect(AppColors.primaryGradient.colors.length, equals(2));
    });

    test('should have premiumGradient defined', () {
      expect(AppColors.premiumGradient, isA<LinearGradient>());
      expect(AppColors.premiumGradient.colors.length, equals(2));
    });

    test('primaryGradient should use primary colors', () {
      expect(AppColors.primaryGradient.colors, contains(AppColors.primary));
      expect(AppColors.primaryGradient.colors, contains(AppColors.primaryLight));
    });

    test('premiumGradient should use accent colors', () {
      expect(AppColors.premiumGradient.colors, contains(AppColors.accent));
      expect(AppColors.premiumGradient.colors, contains(AppColors.accentDark));
    });
  });

  group('AppColors accessibility', () {
    test('textPrimary should have sufficient contrast on background', () {
      // Dark text on light background
      expect(AppColors.textPrimary.computeLuminance(), lessThan(0.5));
      expect(AppColors.background.computeLuminance(), greaterThan(0.5));
    });

    test('textOnPrimary should be readable on primary', () {
      // White text on coral background
      expect(AppColors.textOnPrimary, equals(Colors.white));
    });
  });
}
