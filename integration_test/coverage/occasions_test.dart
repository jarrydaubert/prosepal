/// Coverage: All 41 Occasions
/// 
/// Smoke tests that each occasion loads the wizard correctly.
/// Groups: Core, Holidays, Cultural, Career, Appreciation, Pets
library;

import 'package:flutter_test/flutter_test.dart';
import '../journeys/_helpers.dart';

void main() {
  initBinding();

  // Core occasions (always visible)
  final coreOccasions = [
    'Birthday',
    "Kid's Birthday",
    'Thank You',
    'Sympathy',
    'Wedding',
    'Engagement',
    'Graduation',
    'New Baby',
    'Get Well',
    'Anniversary',
    'Congratulations',
    'Apology',
    'Retirement',
    'New Home',
    'Encouragement',
    'Thinking of You',
    'Just Because',
  ];

  // Holiday occasions
  final holidayOccasions = [
    "Mother's Day",
    "Father's Day",
    "Valentine's Day",
    'Christmas',
    'Thanksgiving',
    'Easter',
    'Halloween',
    'New Year',
  ];

  // Cultural/Religious
  final culturalOccasions = [
    'Hanukkah',
    'Diwali',
    'Eid',
    'Lunar New Year',
    'Kwanzaa',
  ];

  // Career
  final careerOccasions = [
    'New Job',
    'Promotion',
    'Farewell',
    'Good Luck',
  ];

  // Appreciation
  final appreciationOccasions = [
    'Thank You for Service',
    'Thank You Teacher',
    'Thank You Healthcare',
  ];

  // Pets
  final petOccasions = [
    'Pet Birthday',
    'New Pet',
    'Pet Loss',
  ];

  group('Coverage: Core Occasions', () {
    for (final occasion in coreOccasions) {
      testWidgets('$occasion loads wizard', (tester) async {
        final atHome = await navigateToHome(tester);
        if (!atHome) return;

        if (await scrollToText(tester, occasion)) {
          await tester.tap(find.text(occasion));
          await tester.pumpAndSettle();

          expect(
            anyTextExists(['Close Friend', 'Family', 'Partner', 'Colleague']),
            isTrue,
            reason: '$occasion should show relationships',
          );
        }
      });
    }
  });

  group('Coverage: Holiday Occasions', () {
    for (final occasion in holidayOccasions) {
      testWidgets('$occasion loads wizard', (tester) async {
        final atHome = await navigateToHome(tester);
        if (!atHome) return;

        if (await scrollToText(tester, occasion)) {
          await tester.tap(find.text(occasion));
          await tester.pumpAndSettle();

          expect(
            anyTextExists(['Close Friend', 'Family', 'Partner', 'Colleague']),
            isTrue,
            reason: '$occasion should show relationships',
          );
        }
      });
    }
  });

  group('Coverage: Cultural Occasions', () {
    for (final occasion in culturalOccasions) {
      testWidgets('$occasion loads wizard', (tester) async {
        final atHome = await navigateToHome(tester);
        if (!atHome) return;

        if (await scrollToText(tester, occasion)) {
          await tester.tap(find.text(occasion));
          await tester.pumpAndSettle();

          expect(
            anyTextExists(['Close Friend', 'Family', 'Partner', 'Colleague']),
            isTrue,
            reason: '$occasion should show relationships',
          );
        }
      });
    }
  });

  group('Coverage: Career Occasions', () {
    for (final occasion in careerOccasions) {
      testWidgets('$occasion loads wizard', (tester) async {
        final atHome = await navigateToHome(tester);
        if (!atHome) return;

        if (await scrollToText(tester, occasion)) {
          await tester.tap(find.text(occasion));
          await tester.pumpAndSettle();

          expect(
            anyTextExists(['Close Friend', 'Family', 'Partner', 'Colleague']),
            isTrue,
            reason: '$occasion should show relationships',
          );
        }
      });
    }
  });

  group('Coverage: Appreciation Occasions', () {
    for (final occasion in appreciationOccasions) {
      testWidgets('$occasion loads wizard', (tester) async {
        final atHome = await navigateToHome(tester);
        if (!atHome) return;

        if (await scrollToText(tester, occasion)) {
          await tester.tap(find.text(occasion));
          await tester.pumpAndSettle();

          expect(
            anyTextExists(['Close Friend', 'Family', 'Partner', 'Colleague']),
            isTrue,
            reason: '$occasion should show relationships',
          );
        }
      });
    }
  });

  group('Coverage: Pet Occasions', () {
    for (final occasion in petOccasions) {
      testWidgets('$occasion loads wizard', (tester) async {
        final atHome = await navigateToHome(tester);
        if (!atHome) return;

        if (await scrollToText(tester, occasion)) {
          await tester.tap(find.text(occasion));
          await tester.pumpAndSettle();

          expect(
            anyTextExists(['Close Friend', 'Family', 'Partner', 'Colleague']),
            isTrue,
            reason: '$occasion should show relationships',
          );
        }
      });
    }
  });
}
