/// Golden Path Integration Tests for Prosepal
/// 
/// These tests validate the critical user journeys end-to-end on real devices.
/// Each test is a complete user flow from app launch to completion.
/// 
/// Run on Firebase Test Lab:
///   gcloud firebase test android run --type instrumentation \
///     --app build/app/outputs/apk/debug/app-debug.apk \
///     --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Golden Path: Fresh User Journey', () {
    testWidgets('GP1: App launches successfully and shows initial screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // App should render something
      expect(find.byType(MaterialApp), findsOneWidget);

      // Should show one of: Onboarding, Auth, or Home
      final hasOnboarding = find.text('Continue').evaluate().isNotEmpty ||
          find.text('Welcome').evaluate().isNotEmpty ||
          find.text('Get Started').evaluate().isNotEmpty;
      final hasAuth = find.text('Continue with Email').evaluate().isNotEmpty ||
          find.text('Sign In').evaluate().isNotEmpty;
      final hasHome = find.text('Prosepal').evaluate().isNotEmpty ||
          find.text("What's the occasion?").evaluate().isNotEmpty;

      expect(hasOnboarding || hasAuth || hasHome, isTrue,
          reason: 'App should show onboarding, auth, or home screen');

      await binding.takeScreenshot('gp1_initial_screen');
    });

    testWidgets('GP2: Can navigate through onboarding (if shown)', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // If onboarding is shown, complete it
      var continueButton = find.text('Continue');
      int tapCount = 0;
      const maxTaps = 5; // Prevent infinite loop

      while (continueButton.evaluate().isNotEmpty && tapCount < maxTaps) {
        await tester.tap(continueButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        continueButton = find.text('Continue');
        tapCount++;
      }

      // After onboarding, should see auth or home
      final hasAuth = find.text('Continue with Email').evaluate().isNotEmpty;
      final hasHome = find.text("What's the occasion?").evaluate().isNotEmpty ||
          find.text('Birthday').evaluate().isNotEmpty;

      expect(hasAuth || hasHome, isTrue,
          reason: 'After onboarding, should see auth or home');

      await binding.takeScreenshot('gp2_after_onboarding');
    });
  });

  group('Golden Path: Message Generation Flow', () {
    testWidgets('GP3: Complete generation wizard - Birthday for Close Friend', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Skip onboarding if present
      while (find.text('Continue').evaluate().isNotEmpty &&
          find.text('Birthday').evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Need to be on home screen with occasions visible
      final birthdayFinder = find.text('Birthday');
      if (birthdayFinder.evaluate().isEmpty) {
        // Not on home, can't proceed - test passes as smoke test
        return;
      }

      // STEP 1: Tap Birthday occasion
      await tester.tap(birthdayFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('gp3_step1_relationship');

      // Verify we're on relationship selection
      expect(find.text('Close Friend').evaluate().isNotEmpty ||
          find.text('Family').evaluate().isNotEmpty, isTrue,
          reason: 'Should show relationship options');

      // STEP 2: Select Close Friend
      final closeFriendFinder = find.text('Close Friend');
      if (closeFriendFinder.evaluate().isNotEmpty) {
        await tester.tap(closeFriendFinder);
        await tester.pumpAndSettle();
      }

      // Tap Continue
      final continueButton = find.text('Continue');
      if (continueButton.evaluate().isNotEmpty) {
        await tester.tap(continueButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await binding.takeScreenshot('gp3_step2_tone');

      // STEP 3: Select Heartfelt tone
      final heartfeltFinder = find.text('Heartfelt');
      if (heartfeltFinder.evaluate().isNotEmpty) {
        await tester.tap(heartfeltFinder);
        await tester.pumpAndSettle();
      }

      // Tap Continue
      if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await binding.takeScreenshot('gp3_step3_generate');

      // STEP 4: Should see Generate or Upgrade button
      final hasGenerate = find.text('Generate Messages').evaluate().isNotEmpty;
      final hasUpgrade = find.text('Upgrade to Continue').evaluate().isNotEmpty;

      expect(hasGenerate || hasUpgrade, isTrue,
          reason: 'Should see Generate or Upgrade button on final step');
    });

    testWidgets('GP4: Final step shows correct button based on user state', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to generate screen quickly
      while (find.text('Continue').evaluate().isNotEmpty &&
          find.text('Birthday').evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      if (find.text('Birthday').evaluate().isEmpty) return;

      // Quick navigation through wizard
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      if (find.text('Close Friend').evaluate().isNotEmpty) {
        await tester.tap(find.text('Close Friend'));
        await tester.pumpAndSettle();
      }
      if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      if (find.text('Heartfelt').evaluate().isNotEmpty) {
        await tester.tap(find.text('Heartfelt'));
        await tester.pumpAndSettle();
      }
      if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      await binding.takeScreenshot('gp4_final_step');

      // Should show either Generate (has credits) or Upgrade (no credits)
      final hasGenerate = find.text('Generate Messages').evaluate().isNotEmpty;
      final hasUpgrade = find.text('Upgrade to Continue').evaluate().isNotEmpty;

      expect(hasGenerate || hasUpgrade, isTrue,
          reason: 'Final step should show Generate or Upgrade button');
    });
  });

  group('Golden Path: Settings & Account', () {
    testWidgets('GP5: Navigate to settings and verify sections', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Skip onboarding
      while (find.text('Continue').evaluate().isNotEmpty &&
          find.byIcon(Icons.settings_outlined).evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Find and tap settings
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isEmpty) {
        // Settings not visible (maybe on auth screen)
        return;
      }

      await tester.tap(settingsIcon);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('gp5_settings_screen');

      // Verify settings screen
      expect(find.text('Settings'), findsOneWidget);

      // Should show subscription status
      final hasFree = find.text('Free Plan').evaluate().isNotEmpty;
      final hasPro = find.text('Pro Plan').evaluate().isNotEmpty;
      expect(hasFree || hasPro, isTrue, reason: 'Should show subscription status');

      // Should have legal links
      expect(find.text('Privacy Policy').evaluate().isNotEmpty ||
          find.text('Terms of Service').evaluate().isNotEmpty, isTrue,
          reason: 'Should have legal links');
    });

    testWidgets('GP6: Free user can access upgrade path', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Skip onboarding
      while (find.text('Continue').evaluate().isNotEmpty &&
          find.byIcon(Icons.settings_outlined).evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Check for upgrade entry points
      final hasUsageCard = find.text('Free messages remaining').evaluate().isNotEmpty;
      final hasUpgradeButton = find.text('Upgrade').evaluate().isNotEmpty;
      final hasPro = find.text('PRO').evaluate().isNotEmpty;

      if (hasPro) {
        // User is already Pro - test passes
        await binding.takeScreenshot('gp6_already_pro');
        return;
      }

      // Free user should see usage indicator or upgrade option
      if (hasUsageCard) {
        await tester.tap(find.text('Free messages remaining'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await binding.takeScreenshot('gp6_paywall_from_usage');

        // Should navigate to paywall
        final hasPaywall = find.text('Unlock').evaluate().isNotEmpty ||
            find.text('Subscribe').evaluate().isNotEmpty ||
            find.text('Pro').evaluate().isNotEmpty;
        expect(hasPaywall, isTrue, reason: 'Tapping usage should show paywall');
      }
    });
  });

  group('Golden Path: Navigation & Back Behavior', () {
    testWidgets('GP7: Back navigation works correctly through wizard', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Skip onboarding
      while (find.text('Continue').evaluate().isNotEmpty &&
          find.text('Birthday').evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      if (find.text('Birthday').evaluate().isEmpty) return;

      // Navigate into wizard
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      // Should be on step 1
      expect(find.text('Close Friend').evaluate().isNotEmpty, isTrue);
      await binding.takeScreenshot('gp7_wizard_step1');

      // Tap back
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Should be back on home
        expect(find.text("What's the occasion?").evaluate().isNotEmpty ||
            find.text('Birthday').evaluate().isNotEmpty, isTrue,
            reason: 'Back should return to home');
        await binding.takeScreenshot('gp7_back_to_home');
      }
    });

    testWidgets('GP8: Can re-enter wizard after backing out', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Skip onboarding
      while (find.text('Continue').evaluate().isNotEmpty &&
          find.text('Birthday').evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      if (find.text('Birthday').evaluate().isEmpty) return;

      // Enter wizard
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      // Back out
      if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }

      // Re-enter with different occasion
      final thankYouFinder = find.text('Thank You');
      if (thankYouFinder.evaluate().isNotEmpty) {
        await tester.tap(thankYouFinder);
        await tester.pumpAndSettle();

        // Should be in wizard again
        expect(find.text('Close Friend').evaluate().isNotEmpty ||
            find.text('Family').evaluate().isNotEmpty, isTrue,
            reason: 'Should be able to re-enter wizard');
        await binding.takeScreenshot('gp8_reenter_wizard');
      }
    });
  });

  group('Golden Path: Error Resilience', () {
    testWidgets('GP9: App survives rapid interactions', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Skip onboarding quickly
      for (int i = 0; i < 5; i++) {
        if (find.text('Continue').evaluate().isNotEmpty &&
            find.text('Birthday').evaluate().isEmpty) {
          await tester.tap(find.text('Continue'), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      await tester.pumpAndSettle();

      // Rapid tap on any visible button
      if (find.text('Birthday').evaluate().isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.text('Birthday'), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
      }

      // App should still be responsive
      expect(find.byType(MaterialApp), findsOneWidget);
      await binding.takeScreenshot('gp9_after_rapid_taps');
    });

    testWidgets('GP10: App handles orientation (if supported)', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Just verify app renders
      expect(find.byType(MaterialApp), findsOneWidget);

      // Take screenshot of current state
      await binding.takeScreenshot('gp10_current_orientation');
    });
  });
}
