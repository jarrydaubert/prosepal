import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/shared/theme/app_spacing.dart';

void main() {
  group('AppSpacing base units', () {
    test('should have xxs spacing defined', () {
      expect(AppSpacing.xxs, equals(2));
    });

    test('should have xs spacing defined', () {
      expect(AppSpacing.xs, equals(4));
    });

    test('should have sm spacing defined', () {
      expect(AppSpacing.sm, equals(8));
    });

    test('should have md spacing defined', () {
      expect(AppSpacing.md, equals(12));
    });

    test('should have lg spacing defined', () {
      expect(AppSpacing.lg, equals(16));
    });

    test('should have xl spacing defined', () {
      expect(AppSpacing.xl, equals(24));
    });

    test('should have xxl spacing defined', () {
      expect(AppSpacing.xxl, equals(32));
    });

    test('should have xxxl spacing defined', () {
      expect(AppSpacing.xxxl, equals(48));
    });

    test('base spacing values should be in ascending order', () {
      expect(AppSpacing.xxs, lessThan(AppSpacing.xs));
      expect(AppSpacing.xs, lessThan(AppSpacing.sm));
      expect(AppSpacing.sm, lessThan(AppSpacing.md));
      expect(AppSpacing.md, lessThan(AppSpacing.lg));
      expect(AppSpacing.lg, lessThan(AppSpacing.xl));
      expect(AppSpacing.xl, lessThan(AppSpacing.xxl));
      expect(AppSpacing.xxl, lessThan(AppSpacing.xxxl));
    });
  });

  group('AppSpacing semantic values', () {
    test('should have cardPadding defined', () {
      expect(AppSpacing.cardPadding, equals(AppSpacing.lg));
      expect(AppSpacing.cardPadding, equals(16));
    });

    test('should have screenPadding defined', () {
      expect(AppSpacing.screenPadding, equals(AppSpacing.lg));
      expect(AppSpacing.screenPadding, equals(16));
    });

    test('should have sectionGap defined', () {
      expect(AppSpacing.sectionGap, equals(AppSpacing.xl));
      expect(AppSpacing.sectionGap, equals(24));
    });

    test('should have itemGap defined', () {
      expect(AppSpacing.itemGap, equals(AppSpacing.sm));
      expect(AppSpacing.itemGap, equals(8));
    });
  });

  group('AppSpacing component sizes', () {
    test('should have buttonHeight defined', () {
      expect(AppSpacing.buttonHeight, equals(56));
    });

    test('should have buttonHeightSmall defined', () {
      expect(AppSpacing.buttonHeightSmall, equals(44));
    });

    test('buttonHeight should meet touch target guidelines', () {
      // Apple HIG recommends 44pt minimum
      expect(AppSpacing.buttonHeight, greaterThanOrEqualTo(44));
      expect(AppSpacing.buttonHeightSmall, greaterThanOrEqualTo(44));
    });

    test('should have iconSize defined', () {
      expect(AppSpacing.iconSize, equals(24));
    });

    test('should have iconSizeSmall defined', () {
      expect(AppSpacing.iconSizeSmall, equals(20));
    });

    test('should have iconSizeLarge defined', () {
      expect(AppSpacing.iconSizeLarge, equals(32));
    });

    test('icon sizes should be in ascending order', () {
      expect(AppSpacing.iconSizeSmall, lessThan(AppSpacing.iconSize));
      expect(AppSpacing.iconSize, lessThan(AppSpacing.iconSizeLarge));
    });
  });

  group('AppSpacing border radius', () {
    test('should have radiusSmall defined', () {
      expect(AppSpacing.radiusSmall, equals(8));
    });

    test('should have radiusMedium defined', () {
      expect(AppSpacing.radiusMedium, equals(12));
    });

    test('should have radiusLarge defined', () {
      expect(AppSpacing.radiusLarge, equals(16));
    });

    test('should have radiusXLarge defined', () {
      expect(AppSpacing.radiusXLarge, equals(24));
    });

    test('should have radiusFull defined', () {
      expect(AppSpacing.radiusFull, equals(999));
    });

    test('radius values should be in ascending order', () {
      expect(AppSpacing.radiusSmall, lessThan(AppSpacing.radiusMedium));
      expect(AppSpacing.radiusMedium, lessThan(AppSpacing.radiusLarge));
      expect(AppSpacing.radiusLarge, lessThan(AppSpacing.radiusXLarge));
      expect(AppSpacing.radiusXLarge, lessThan(AppSpacing.radiusFull));
    });
  });

  group('AppSpacing 8px grid system', () {
    test('base spacing values should be multiples of 4 (half-grid)', () {
      expect(AppSpacing.xxs % 2, equals(0));
      expect(AppSpacing.xs % 4, equals(0));
      expect(AppSpacing.sm % 4, equals(0));
      expect(AppSpacing.lg % 4, equals(0));
      expect(AppSpacing.xl % 4, equals(0));
      expect(AppSpacing.xxl % 4, equals(0));
      expect(AppSpacing.xxxl % 4, equals(0));
    });

    test('larger spacing values should be multiples of 8', () {
      expect(AppSpacing.sm % 8, equals(0));
      expect(AppSpacing.lg % 8, equals(0));
      expect(AppSpacing.xl % 8, equals(0));
      expect(AppSpacing.xxl % 8, equals(0));
      expect(AppSpacing.xxxl % 8, equals(0));
    });
  });
}
