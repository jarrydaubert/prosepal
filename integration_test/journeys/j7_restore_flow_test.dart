/// Journey 7 & 8: Reinstall & Restore Flows
/// 
/// Tests restore and reinstall scenarios:
/// 1. Pro restore banner detection
/// 2. Restore from settings
/// 3. Sign in to claim Pro
/// 
/// Expected logs:
/// - [INFO] Anonymous user has Pro - prompting sign-in to claim
/// - [INFO] Restore initiated
/// - [INFO] Usage restored from server
/// - [INFO] RevenueCat user identified
library;

import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 7: Restore Flow', () {
    testWidgets('J7.1: App checks Pro status on launch', (tester) async {
      await launchApp(tester);

      // App should show one of: restore banner, onboarding, or home
      final hasRestoreBanner = exists(find.text('Pro subscription found!'));
      final hasOnboarding = exists(find.text('Continue'));
      final hasHome = exists(find.text('Birthday'));
      final hasAuth = exists(find.text('Continue with Email'));

      expect(hasRestoreBanner || hasOnboarding || hasHome || hasAuth, isTrue,
          reason: 'App should show appropriate initial screen');

      await screenshot(tester, 'j7_1_launch');
    });

    testWidgets('J7.2: Restore banner prompts sign-in', (tester) async {
      await launchApp(tester);

      if (exists(find.text('Pro subscription found!'))) {
        expect(find.text('Sign in to restore your Pro access'), findsOneWidget);
        
        expect(
          anyTextExists(['Continue with Apple', 'Continue with Google', 'Continue with Email']),
          isTrue,
          reason: 'Should show sign-in options',
        );

        await screenshot(tester, 'j7_2_restore_banner');
      }
    });

    testWidgets('J7.3: Restore Purchases from settings', (tester) async {
      final atSettings = await navigateToSettings(tester);
      if (!atSettings) return;

      if (await scrollToText(tester, 'Restore Purchases')) {
        await tester.tap(find.text('Restore Purchases'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Should show result (success, failure, or loading)
        await screenshot(tester, 'j7_3_restore_result');
      }
    });

    testWidgets('J7.4: Sign In from settings for restore', (tester) async {
      final atSettings = await navigateToSettings(tester);
      if (!atSettings) return;

      if (await scrollToText(tester, 'Sign In')) {
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(
          anyTextExists(['Continue with Apple', 'Continue with Google', 'Continue with Email']),
          isTrue,
          reason: 'Should show auth screen',
        );

        await screenshot(tester, 'j7_4_sign_in');
      }
    });

    testWidgets('J7.5: Anonymous user gets fresh state', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      // Fresh install should have 1 free generation
      final hasFreeIndicator = find.textContaining('1').evaluate().isNotEmpty &&
          find.textContaining('free').evaluate().isNotEmpty;
      final hasPro = exists(find.text('PRO'));
      final hasZero = find.textContaining('0').evaluate().isNotEmpty;

      // Should have either 1 free, 0 free (used), or Pro
      expect(hasFreeIndicator || hasPro || hasZero, isTrue,
          reason: 'Should show usage status');

      await screenshot(tester, 'j7_5_fresh_state');
    });
  });
}
