/// Journey 5: Navigation & Wizard Steps
///
/// Keeps explicit state-preservation checks for wizard navigation.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 5: Navigation', () {
    testWidgets('J5.1: Back from wizard step 1 returns to home', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      final wentBack = await tapBack(tester);
      expect(wentBack, isTrue, reason: 'Back action unavailable on step 1');
      expect(
        anyTextExists(["What's the occasion?", 'Birthday']),
        isTrue,
        reason: 'Should return to home',
      );

      await screenshot(tester, 'j5_1_back_to_home');
    });

    testWidgets('J5.2: Back from step 2 preserves occasion context', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      await tapTextOrFail(
        tester,
        'Close Friend',
        reason: 'Relationship selection should include Close Friend',
      );
      await tapTextOrFail(
        tester,
        'Continue',
        reason: 'Continue CTA should be present after relationship selection',
      );

      final wentBack = await tapBack(tester);
      expect(wentBack, isTrue, reason: 'Back action unavailable on step 2');
      expect(
        anyTextExists(['Close Friend', 'Family', 'Partner']),
        isTrue,
        reason: 'Back should preserve occasion context',
      );

      await screenshot(tester, 'j5_2_back_preserves');
    });

    testWidgets('J5.3: Back from final step preserves tone selection state', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizardOrFail(tester);

      final wentBack = await tapBack(tester);
      expect(wentBack, isTrue, reason: 'Back action unavailable on final step');
      expect(
        anyTextExists(['Heartfelt', 'Funny', 'Formal']),
        isTrue,
        reason: 'Should show tone selection',
      );

      await screenshot(tester, 'j5_3_back_to_tones');
    });

    testWidgets('J5.4: Re-entering wizard starts a new occasion path', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();
      await tapBack(tester);

      await tapTextOrFail(
        tester,
        'Thank You',
        reason: 'Expected to re-enter wizard with Thank You occasion',
      );

      expect(
        anyTextExists(['Close Friend', 'Family']),
        isTrue,
        reason: 'Should show relationships for new occasion',
      );

      await screenshot(tester, 'j5_4_reenter');
    });

    testWidgets('J5.7: Deep legal navigation can return safely to home', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();
      await tapBack(tester);

      final settingsButton = find.byKey(const ValueKey('home_settings_button'));
      expect(
        settingsButton.evaluate().isNotEmpty,
        isTrue,
        reason: 'Home settings button should be visible',
      );
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      final foundPrivacy = await scrollToText(tester, 'Privacy Policy');
      expect(
        foundPrivacy,
        isTrue,
        reason: 'Privacy Policy link should be present',
      );
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      await tapBack(tester);
      await tapBack(tester);

      expect(
        anyTextExists(["What's the occasion?", 'Birthday']),
        isTrue,
        reason: 'Deep navigation should be able to return to home',
      );

      await screenshot(tester, 'j5_7_deep_nav');
    });
  });
}
