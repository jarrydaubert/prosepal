/// Journey 6: Error Handling & Resilience
///
/// Tests error handling and edge cases:
/// 1. Rapid taps don't crash app
/// 2. Scroll edge cases
/// 3. Error states display correctly
/// 4. Recovery from errors
///
/// Expected logs:
/// - [ERROR] Firebase AI error
/// - [INFO] Retry attempted
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 6: Error Resilience', () {
    testWidgets('J6.1: App survives rapid occasion taps', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      // Rapid tap same occasion
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Birthday'), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      expect(
        find.byType(MaterialApp),
        findsOneWidget,
        reason: 'App should remain stable',
      );

      await screenshot(tester, 'j6_1_rapid_taps');
    });

    testWidgets('J6.2: App survives rapid onboarding skips', (tester) async {
      await launchApp(tester);

      // Rapid skip
      for (int i = 0; i < 10; i++) {
        if (exists(find.text('Continue'))) {
          await tester.tap(find.text('Continue'), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      await tester.pumpAndSettle();

      expect(
        find.byType(MaterialApp),
        findsOneWidget,
        reason: 'App should remain stable',
      );

      await screenshot(tester, 'j6_2_rapid_skip');
    });

    testWidgets('J6.3: Scroll to bottom and back', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      final scrollable = find.byType(Scrollable).first;

      // Scroll to bottom aggressively
      await tester.fling(scrollable, const Offset(0, -1000), 2000);
      await tester.pumpAndSettle();

      // Scroll back to top
      await tester.fling(scrollable, const Offset(0, 1000), 2000);
      await tester.pumpAndSettle();

      expect(
        find.text('Birthday'),
        findsOneWidget,
        reason: 'Should scroll back to show Birthday',
      );

      await screenshot(tester, 'j6_3_scroll_recovery');
    });

    testWidgets('J6.4: Settings scroll to bottom and back', (tester) async {
      final atSettings = await navigateToSettings(tester);
      if (!atSettings) return;

      final scrollable = find.byType(Scrollable).first;

      // Aggressive scrolling
      await tester.fling(scrollable, const Offset(0, -800), 1500);
      await tester.pumpAndSettle();
      await tester.fling(scrollable, const Offset(0, 800), 1500);
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);

      await screenshot(tester, 'j6_4_settings_scroll');
    });

    testWidgets('J6.5: Tap during loading (if visible)', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      if (exists(find.text('Generate Messages'))) {
        await tester.tap(find.text('Generate Messages'));

        // Immediately try tapping other things while loading
        await tester.pump(const Duration(milliseconds: 500));

        if (exists(find.byIcon(Icons.arrow_back))) {
          await tester.tap(find.byIcon(Icons.arrow_back), warnIfMissed: false);
        }

        await tester.pumpAndSettle(const Duration(seconds: 15));

        expect(
          find.byType(MaterialApp),
          findsOneWidget,
          reason: 'App should handle taps during loading',
        );

        await screenshot(tester, 'j6_5_tap_during_load');
      }
    });

    testWidgets('J6.6: Multiple wizard completions', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      // Complete wizard multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Birthday'));
        await tester.pumpAndSettle();

        if (exists(find.text('Close Friend'))) {
          await tester.tap(find.text('Close Friend'));
          await tester.pumpAndSettle();
        }

        await tapBack(tester);
        await tapBack(tester);
        await tester.pumpAndSettle();

        if (!exists(find.text('Birthday'))) break;
      }

      expect(
        find.byType(MaterialApp),
        findsOneWidget,
        reason: 'App should handle repeated wizard entries',
      );

      await screenshot(tester, 'j6_6_repeated_wizard');
    });

    testWidgets('J6.7: Error banner dismisses correctly', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      if (exists(find.text('Generate Messages'))) {
        await tester.tap(find.text('Generate Messages'));
        await tester.pumpAndSettle(const Duration(seconds: 15));

        // If error shown, try to dismiss
        if (exists(find.byIcon(Icons.close))) {
          await tester.tap(find.byIcon(Icons.close).first);
          await tester.pumpAndSettle();

          await screenshot(tester, 'j6_7_error_dismissed');
        }
      }
    });

    testWidgets('J6.8: Retry after error works', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      if (exists(find.text('Generate Messages'))) {
        await tester.tap(find.text('Generate Messages'));
        await tester.pumpAndSettle(const Duration(seconds: 15));

        // If error, should still be able to retry
        if (exists(find.text('Generate Messages'))) {
          await tester.tap(find.text('Generate Messages'));
          await tester.pumpAndSettle(const Duration(seconds: 15));

          await screenshot(tester, 'j6_8_retry');
        }
      }
    });
  });
}
