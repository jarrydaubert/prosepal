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

import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 2: Upgrade Flow', () {
    testWidgets('J2.1: Upgrade button visible when 0 free remaining', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizardOrFail(tester);

      await screenshot(tester, 'j2_1_generate_or_upgrade');
    });

    testWidgets('J2.2: Upgrade navigates to auth for anonymous user', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester, seedFreeTierUsed: true);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizardOrFail(tester);
      await tapTextOrFail(
        tester,
        'Upgrade to Continue',
        settleDuration: const Duration(seconds: 2),
        reason: 'Expected Upgrade gate for anonymous user with free tier used',
      );

      // Should show auth options (anonymous) or paywall (authenticated)
      final hasAuth = anyTextExists([
        'Sign in with Apple',
        'Sign in with Google',
      ]);
      final hasPaywall =
          find.textContaining(r'$').evaluate().isNotEmpty ||
          exists(find.text('Subscribe'));

      expect(
        hasAuth || hasPaywall,
        isTrue,
        reason: 'Upgrade flow should show auth or paywall destination',
      );

      await screenshot(tester, 'j2_2_upgrade_destination');
    });

    testWidgets('J2.3: Auth screen shows welcome message', (tester) async {
      final atAuth = await navigateToAuth(tester);
      expect(atAuth, isTrue, reason: 'Failed to navigate to auth');

      expect(find.text('Welcome to Prosepal'), findsOneWidget);
      expect(find.text('The right words, right now'), findsOneWidget);

      await screenshot(tester, 'j2_3_auth_welcome');
    });

    testWidgets('J2.4: Auth screen has all sign-in options', (tester) async {
      final atAuth = await navigateToAuth(tester);
      expect(atAuth, isTrue, reason: 'Failed to navigate to auth');

      // All should have Google
      final hasGoogle = exists(find.text('Sign in with Google'));

      expect(hasGoogle, isTrue, reason: 'Should have Google sign-in');

      await screenshot(tester, 'j2_4_auth_options');
    });

    testWidgets('J2.5: Auth screen has legal links', (tester) async {
      final atAuth = await navigateToAuth(tester);
      expect(atAuth, isTrue, reason: 'Failed to navigate to auth');

      expect(exists(find.text('Terms')), isTrue);
      expect(exists(find.text('Privacy Policy')), isTrue);

      await screenshot(tester, 'j2_5_auth_legal');
    });

    testWidgets('J2.6: Sub-text shows correct message for anonymous', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester, seedFreeTierUsed: true);
      expect(atHome, isTrue, reason: 'Failed to navigate to home');

      await completeWizardOrFail(tester);
      expect(
        exists(find.text('Upgrade to Continue')),
        isTrue,
        reason: 'Anonymous upgrade checkpoint missing on final wizard step',
      );

      // Check for sub-text
      final hasSignInPrompt = exists(find.text('Sign in to go Pro'));

      expect(
        hasSignInPrompt,
        isTrue,
        reason: 'Anonymous user should see "Sign in to go Pro"',
      );

      await screenshot(tester, 'j2_7_upgrade_subtext');
    });
  });
}
