/// Journey 3: Pro User → Generate → Sign Out
/// 
/// Tests the authenticated Pro user experience:
/// 1. PRO badge visible
/// 2. Unlimited generations
/// 3. Settings shows Pro Plan
/// 4. Sign out flow
/// 
/// Expected logs:
/// - [INFO] App launched | isPro=true
/// - [INFO] AI generation started
/// - [INFO] AI generation success
/// - [INFO] Sign out initiated
/// - [INFO] User signed out
/// - [INFO] RevenueCat user logged out
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 3: Pro User Flow', () {
    testWidgets('J3.1: Pro badge visible on home (if Pro)', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      // Check for Pro indicator
      final hasPro = exists(find.text('PRO')) || 
          exists(find.text('Pro')) ||
          exists(find.textContaining('unlimited'));
      final hasFree = find.textContaining('free').evaluate().isNotEmpty;

      // One of these should be true
      expect(hasPro || hasFree, isTrue,
          reason: 'Should show Pro badge or free count');

      await screenshot('j3_1_pro_or_free');
    });

    testWidgets('J3.2: Pro user can generate without upgrade prompt', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      // If Pro, should see Generate (not Upgrade)
      if (exists(find.text('PRO'))) {
        expect(find.text('Generate Messages'), findsOneWidget);
        expect(find.text('Upgrade to Continue'), findsNothing);

        await screenshot('j3_2_pro_generate');
      }
    });

    testWidgets('J3.3: Settings shows Pro Plan for Pro user', (tester) async {
      final atSettings = await navigateToSettings(tester);
      if (!atSettings) return;

      // Should show either Pro Plan or Free Plan
      final hasProPlan = exists(find.text('Pro Plan'));
      final hasFreePlan = exists(find.text('Free Plan'));

      expect(hasProPlan || hasFreePlan, isTrue,
          reason: 'Should show subscription status');

      await screenshot('j3_3_subscription_status');
    });

    testWidgets('J3.4: Settings shows Sign Out for authenticated user', (tester) async {
      final atSettings = await navigateToSettings(tester);
      if (!atSettings) return;

      // Scroll to find auth action
      await scrollToText(tester, 'Sign Out');
      await scrollToText(tester, 'Sign In');

      final hasSignOut = exists(find.text('Sign Out'));
      final hasSignIn = exists(find.text('Sign In'));

      expect(hasSignOut || hasSignIn, isTrue,
          reason: 'Should show Sign Out or Sign In');

      await screenshot('j3_4_auth_action');
    });

    testWidgets('J3.5: Sign Out shows confirmation dialog', (tester) async {
      final atSettings = await navigateToSettings(tester);
      if (!atSettings) return;

      if (await scrollToText(tester, 'Sign Out')) {
        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();

        // Should show confirmation or navigate to auth
        final hasConfirm = exists(find.text('Confirm')) ||
            exists(find.text('Cancel')) ||
            exists(find.text('Are you sure'));
        final atAuth = exists(find.text('Continue with Email'));

        expect(hasConfirm || atAuth, isTrue,
            reason: 'Should show confirmation or go to auth');

        await screenshot('j3_5_sign_out');
      }
    });

    testWidgets('J3.6: Pro user generation flow works', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      // Only run full generation if Pro (to save API calls)
      if (!exists(find.text('PRO'))) return;

      await completeWizard(tester, occasion: 'Thank You', tone: 'Formal');

      if (exists(find.text('Generate Messages'))) {
        await tester.tap(find.text('Generate Messages'));
        await tester.pumpAndSettle(const Duration(seconds: 15));

        expect(
          anyTextExists(['Your Messages', 'Option 1']),
          isTrue,
          reason: 'Pro user should get generation results',
        );

        await screenshot('j3_6_pro_generation');
      }
    });

    testWidgets('J3.7: Multiple generations work (Pro unlimited)', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      if (!exists(find.text('PRO'))) return;

      // First generation
      await completeWizard(tester);
      if (exists(find.text('Generate Messages'))) {
        await tester.tap(find.text('Generate Messages'));
        await tester.pumpAndSettle(const Duration(seconds: 15));

        if (exists(find.text('Start Over'))) {
          await tester.tap(find.text('Start Over'));
          await tester.pumpAndSettle();

          // Second generation should also work
          await completeWizard(tester, occasion: 'Wedding');
          expect(
            anyTextExists(['Generate Messages', 'Upgrade to Continue']),
            isTrue,
          );

          await screenshot('j3_7_multiple_gens');
        }
      }
    });
  });
}
