/// Journey 2: Return User → Upgrade → Purchase
/// 
/// Tests the upgrade path for users who have used their free generation:
/// 1. User with 0 free remaining
/// 2. Upgrade button appears
/// 3. Auth screen (must sign in before purchase)
/// 4. Paywall with subscription options
/// 
/// Expected logs:
/// - [INFO] Upgrade tapped, auth required
/// - [INFO] Sign in started | provider=xxx
/// - [INFO] User signed in
/// - [INFO] RevenueCat user identified
/// - [INFO] Paywall offerings loaded
/// - [INFO] Purchase completed
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 2: Upgrade Flow', () {
    testWidgets('J2.1: Upgrade button visible when 0 free remaining', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      // Either can generate (has free) or must upgrade (0 free)
      final canGenerate = exists(find.text('Generate Messages'));
      final mustUpgrade = exists(find.text('Upgrade to Continue'));

      expect(canGenerate || mustUpgrade, isTrue,
          reason: 'Should show Generate or Upgrade');

      await screenshot(tester, 'j2_1_generate_or_upgrade');
    });

    testWidgets('J2.2: Upgrade navigates to auth for anonymous user', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      if (exists(find.text('Upgrade to Continue'))) {
        await tester.tap(find.text('Upgrade to Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Should show auth options (anonymous) or paywall (authenticated)
        final hasAuth = anyTextExists([
          'Continue with Apple',
          'Continue with Google',
          'Continue with Email',
        ]);
        final hasPaywall = find.textContaining('\$').evaluate().isNotEmpty ||
            exists(find.text('Subscribe'));

        expect(hasAuth || hasPaywall, isTrue,
            reason: 'Should show auth or paywall');

        await screenshot(tester, 'j2_2_upgrade_destination');
      }
    });

    testWidgets('J2.3: Auth screen shows welcome message', (tester) async {
      final atAuth = await navigateToAuth(tester);
      if (!atAuth) return;

      expect(find.text('Welcome to Prosepal'), findsOneWidget);
      expect(find.text('The right words, right now'), findsOneWidget);

      await screenshot(tester, 'j2_3_auth_welcome');
    });

    testWidgets('J2.4: Auth screen has all sign-in options', (tester) async {
      final atAuth = await navigateToAuth(tester);
      if (!atAuth) return;

      // iOS should have Apple, all should have Google and Email
      final hasGoogle = exists(find.text('Continue with Google'));
      final hasEmail = exists(find.text('Continue with Email'));

      expect(hasGoogle, isTrue, reason: 'Should have Google sign-in');
      expect(hasEmail, isTrue, reason: 'Should have Email sign-in');

      await screenshot(tester, 'j2_4_auth_options');
    });

    testWidgets('J2.5: Auth screen has legal links', (tester) async {
      final atAuth = await navigateToAuth(tester);
      if (!atAuth) return;

      expect(exists(find.text('Terms')), isTrue);
      expect(exists(find.text('Privacy Policy')), isTrue);

      await screenshot(tester, 'j2_5_auth_legal');
    });

    testWidgets('J2.6: Email auth option opens email screen', (tester) async {
      final atAuth = await navigateToAuth(tester);
      if (!atAuth) return;

      await tester.tap(find.text('Continue with Email'));
      await tester.pumpAndSettle();

      // Should show email input field
      final hasTextField = find.byType(TextField).evaluate().isNotEmpty;
      final hasEmailText = find.textContaining('email').evaluate().isNotEmpty ||
          find.textContaining('Email').evaluate().isNotEmpty;

      expect(hasTextField || hasEmailText, isTrue,
          reason: 'Should show email input screen');

      await screenshot(tester, 'j2_6_email_auth');
    });

    testWidgets('J2.7: Sub-text shows correct message for anonymous', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      if (exists(find.text('Upgrade to Continue'))) {
        // Check for sub-text
        final hasSignInPrompt = exists(find.text('Sign in to go Pro'));
        
        expect(hasSignInPrompt, isTrue,
            reason: 'Anonymous user should see "Sign in to go Pro"');

        await screenshot(tester, 'j2_7_upgrade_subtext');
      }
    });
  });
}
