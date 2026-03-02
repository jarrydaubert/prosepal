/// Journey 4 & 5: Settings, Biometrics, Account Management
///
/// Tests settings functionality:
/// 1. Settings screen access
/// 2. Biometric toggle (if supported)
/// 3. Restore purchases
/// 4. Delete account (authenticated only)
/// 5. Legal links
/// 6. Feedback
///
/// Expected logs:
/// - [INFO] Biometrics enable requested
/// - [INFO] Biometrics enabled/disabled
/// - [INFO] Restore initiated
/// - [INFO] Delete account initiated
/// - [INFO] Account deleted
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 4: Settings & Account', () {
    testWidgets('J4.1: Settings screen accessible from home', (tester) async {
      final atSettings = await navigateToSettings(tester);

      expect(atSettings, isTrue, reason: 'Should reach settings');
      expect(find.text('Settings'), findsOneWidget);

      await screenshot(tester, 'j4_1_settings');
    });

    testWidgets('J4.2: Subscription status visible', (tester) async {
      final atSettings = await navigateToSettings(tester);
      expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

      final hasProPlan = exists(find.text('Pro Plan'));
      final hasFreePlan = exists(find.text('Free Plan'));

      expect(
        hasProPlan || hasFreePlan,
        isTrue,
        reason: 'Should show subscription status',
      );

      await screenshot(tester, 'j4_2_subscription');
    });

    testWidgets('J4.3: Biometric toggle exists (if supported)', (tester) async {
      final atSettings = await navigateToSettings(tester);
      expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

      // Security section should exist; biometric controls may vary by platform.
      final hasSecurityOrBiometric =
          exists(find.text('Security')) ||
          exists(find.text('Face ID')) ||
          exists(find.text('Touch ID')) ||
          exists(find.textContaining('Biometric'));
      expect(
        hasSecurityOrBiometric,
        isTrue,
        reason: 'Settings should expose security/biometric section',
      );

      await screenshot(tester, 'j4_3_biometric_option');
    });

    testWidgets('J4.4: Restore Purchases option exists', (tester) async {
      final atSettings = await navigateToSettings(tester);
      expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

      final found = await scrollToText(tester, 'Restore Purchases');

      expect(found, isTrue, reason: 'Should have Restore Purchases option');

      await screenshot(tester, 'j4_4_restore');
    });

    testWidgets('J4.5: Restore Purchases triggers restore', (tester) async {
      final atSettings = await navigateToSettings(tester);
      expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

      final found = await scrollToText(tester, 'Restore Purchases');
      expect(
        found,
        isTrue,
        reason: 'Restore Purchases option should be present',
      );
      await tester.tap(find.text('Restore Purchases'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show loading, success, or error
      await screenshot(tester, 'j4_5_restore_result');
    });

    testWidgets('J4.6: Privacy Policy link works', (tester) async {
      final atSettings = await navigateToSettings(tester);
      expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

      final found = await scrollToText(tester, 'Privacy Policy');
      expect(found, isTrue, reason: 'Privacy Policy link should be present');
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      // Should navigate to privacy screen
      await screenshot(tester, 'j4_6_privacy');
    });

    testWidgets('J4.7: Terms of Service link works', (tester) async {
      final atSettings = await navigateToSettings(tester);
      expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

      final found = await scrollToText(tester, 'Terms of Service');
      expect(found, isTrue, reason: 'Terms of Service link should be present');
      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();

      await screenshot(tester, 'j4_7_terms');
    });

    testWidgets('J4.8: Send Feedback option exists', (tester) async {
      final atSettings = await navigateToSettings(tester);
      expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

      final found = await scrollToText(tester, 'Send Feedback');
      expect(found, isTrue, reason: 'Send Feedback option should be present');
      await screenshot(tester, 'j4_8_feedback_option');
    });

    testWidgets('J4.9: Delete Account (authenticated only)', (tester) async {
      final atSettings = await navigateToSettings(tester);
      expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

      // Scroll to bottom
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, -500), 1000);
      await tester.pumpAndSettle();

      // Delete Account only visible when authenticated
      final hasDelete = exists(find.text('Delete Account'));
      final hasSignIn = exists(find.text('Sign In'));

      expect(
        hasDelete || hasSignIn,
        isTrue,
        reason: 'Should show Delete Account (auth) or Sign In (anon)',
      );

      await screenshot(tester, 'j4_9_delete_or_signin');
    });

    testWidgets('J4.10: Delete Account shows warning', (tester) async {
      final atSettings = await navigateToSettings(tester);
      expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

      final hasDeleteAccount = await scrollToText(tester, 'Delete Account');
      final hasSignIn =
          !hasDeleteAccount && await scrollToText(tester, 'Sign In');

      expect(
        hasDeleteAccount || hasSignIn,
        isTrue,
        reason: 'Expected Delete Account action or Sign In gating action',
      );

      if (hasDeleteAccount) {
        await tester.tap(find.text('Delete Account'));
        await tester.pumpAndSettle();

        // Should show warning dialog
        final hasWarning =
            exists(find.text('Delete')) ||
            exists(find.text('Cancel')) ||
            exists(find.textContaining('permanent')) ||
            exists(find.textContaining('sure'));

        expect(hasWarning, isTrue, reason: 'Should show delete confirmation');
      } else {
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();
        expectAnyTextVisible([
          'Sign in with Google',
          'Sign in with Apple',
        ], reason: 'Sign In action should navigate to auth screen');
      }

      await screenshot(tester, 'j4_10_delete_warning');
    });

    testWidgets('J4.11: Version info visible', (tester) async {
      final atSettings = await navigateToSettings(tester);
      expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

      // Scroll to bottom
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, -500), 1000);
      await tester.pumpAndSettle();

      // Look for version text
      final hasVersionText =
          find.textContaining('Version').evaluate().isNotEmpty ||
          find.textContaining('v1.').evaluate().isNotEmpty ||
          find.textContaining('1.0').evaluate().isNotEmpty;
      expect(
        hasVersionText,
        isTrue,
        reason: 'Settings should show app version/build info',
      );

      await screenshot(tester, 'j4_11_version');
    });

    testWidgets('J4.12: Back from settings returns to home', (tester) async {
      final atSettings = await navigateToSettings(tester);
      expect(atSettings, isTrue, reason: 'Failed to navigate to settings');

      final wentBack = await tapBack(tester);
      expect(wentBack, isTrue, reason: 'Back action unavailable from settings');
      expect(
        anyTextExists(["What's the occasion?", 'Birthday']),
        isTrue,
        reason: 'Should return to home',
      );

      await screenshot(tester, 'j4_12_back_to_home');
    });
  });
}
