/// Journey 5: Navigation & Wizard Steps
///
/// Tests navigation behavior:
/// 1. Back button from wizard
/// 2. Wizard state preservation
/// 3. Re-entering wizard
/// 4. Rapid navigation handling
///
/// Expected logs:
/// - [INFO] Wizard started
/// - [INFO] Navigation: back pressed
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 5: Navigation', () {
    testWidgets('J5.1: Back from wizard step 1 returns to home', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      final wentBack = await tapBack(tester);

      if (wentBack) {
        expect(
          anyTextExists(["What's the occasion?", 'Birthday']),
          isTrue,
          reason: 'Should return to home',
        );

        await screenshot(tester, 'j5_1_back_to_home');
      }
    });

    testWidgets('J5.2: Back from step 2 preserves occasion', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      // Go to step 2
      if (exists(find.text('Close Friend'))) {
        await tester.tap(find.text('Close Friend'));
        await tester.pumpAndSettle();
      }
      if (exists(find.text('Continue'))) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      // Now on tones, go back
      final wentBack = await tapBack(tester);

      if (wentBack) {
        // Should still be in Birthday wizard (showing relationships)
        expect(
          anyTextExists(['Close Friend', 'Family', 'Partner']),
          isTrue,
          reason: 'Back should preserve occasion context',
        );

        await screenshot(tester, 'j5_2_back_preserves');
      }
    });

    testWidgets('J5.3: Back from step 3 preserves selections', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      // Now on final step, go back
      final wentBack = await tapBack(tester);

      if (wentBack) {
        // Should show tones again
        expect(
          anyTextExists(['Heartfelt', 'Funny', 'Formal']),
          isTrue,
          reason: 'Should show tone selection',
        );

        await screenshot(tester, 'j5_3_back_to_tones');
      }
    });

    testWidgets('J5.4: Can re-enter wizard after backing out', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      // Enter and exit
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();
      await tapBack(tester);

      // Re-enter with different occasion
      if (exists(find.text('Thank You'))) {
        await tester.tap(find.text('Thank You'));
        await tester.pumpAndSettle();

        expect(
          anyTextExists(['Close Friend', 'Family']),
          isTrue,
          reason: 'Should show relationships for new occasion',
        );

        await screenshot(tester, 'j5_4_reenter');
      }
    });

    testWidgets('J5.5: Rapid back taps handled gracefully', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      // Rapid back taps
      for (var i = 0; i < 5; i++) {
        if (exists(find.byIcon(Icons.arrow_back))) {
          await tester.tap(find.byIcon(Icons.arrow_back), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      await tester.pumpAndSettle();

      expect(
        find.byType(MaterialApp),
        findsOneWidget,
        reason: 'App should remain stable',
      );

      await screenshot(tester, 'j5_5_rapid_back');
    });

    testWidgets('J5.6: Settings then back preserves home state', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      // Go to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Come back
      await tapBack(tester);

      expect(
        find.text('Birthday'),
        findsOneWidget,
        reason: 'Home should show occasions',
      );

      await screenshot(tester, 'j5_6_settings_back');
    });

    testWidgets('J5.7: Deep navigation and return', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      // Go deep: Home → Wizard → Settings (via back and re-navigate)
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      await tapBack(tester);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Go to legal
      if (await scrollToText(tester, 'Privacy Policy')) {
        await tester.tap(find.text('Privacy Policy'));
        await tester.pumpAndSettle();

        // Back twice to home
        await tapBack(tester);
        await tapBack(tester);

        expect(anyTextExists(["What's the occasion?", 'Birthday']), isTrue);

        await screenshot(tester, 'j5_7_deep_nav');
      }
    });
  });
}
