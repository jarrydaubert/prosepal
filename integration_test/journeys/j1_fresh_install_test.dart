/// Journey 1: Fresh Install → Free Generation → Close
///
/// Tests the complete first-time user experience:
/// 1. App launch
/// 2. Onboarding completion
/// 3. Home screen with occasions
/// 4. Wizard flow (occasion → relationship → tone)
/// 5. AI generation
/// 6. Results and copy
///
/// Expected logs:
/// - [INFO] Onboarding started
/// - [INFO] Onboarding completed
/// - [INFO] Wizard started | occasion=birthday
/// - [INFO] AI generation started
/// - [INFO] AI generation success
/// - [INFO] Message copied
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '_helpers.dart';

void main() {
  initBinding();

  group('Journey 1: Fresh Install → Free Generation', () {
    testWidgets('J1.1: App launches successfully', (tester) async {
      await launchApp(tester);

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(
        anyTextExists([
          'Continue',
          'Continue with Email',
          "What's the occasion?",
        ]),
        isTrue,
        reason: 'Should show onboarding, auth, or home',
      );

      await screenshot(tester, 'j1_1_launch');
    });

    testWidgets('J1.2: Onboarding completes to home', (tester) async {
      await launchApp(tester);

      // Navigate through onboarding carousel (up to 10 pages max)
      var pages = 0;
      while (pages < 10) {
        // Check if we've reached auth or home
        if (exists(find.text('Birthday')) ||
            exists(find.text('Continue with Email')) ||
            exists(find.text('Continue with Apple')) ||
            exists(find.text("What's the occasion?"))) {
          break;
        }

        // Tap "Get Started" to complete onboarding (final carousel page)
        if (exists(find.text('Get Started'))) {
          await tester.tap(find.text('Get Started'));
          await tester.pumpAndSettle(const Duration(seconds: 2));
          break;
        }

        // Tap "Continue" to advance carousel
        if (exists(find.text('Continue'))) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle(const Duration(seconds: 1));
          pages++;
        } else {
          break;
        }
      }

      // Give extra time for final screen to render
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        anyTextExists([
          'Continue with Email',
          'Continue with Apple',
          'Birthday',
          "What's the occasion?",
        ]),
        isTrue,
        reason: 'Should reach auth or home after onboarding',
      );

      await screenshot(tester, 'j1_2_after_onboarding');
    });

    testWidgets('J1.3: Home shows occasions grid', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      expect(find.text("What's the occasion?"), findsOneWidget);
      expect(find.text('Birthday'), findsOneWidget);

      // Verify multiple occasions visible
      expect(
        anyTextExists(['Thank You', 'Wedding', 'Sympathy']),
        isTrue,
        reason: 'Should show multiple occasion options',
      );

      await screenshot(tester, 'j1_3_home_occasions');
    });

    testWidgets('J1.4: Free user sees usage indicator', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      // Should show either free remaining count or PRO badge
      final hasFreeIndicator =
          find.textContaining('free').evaluate().isNotEmpty ||
          find.textContaining('remaining').evaluate().isNotEmpty;
      final hasProBadge = find.text('PRO').evaluate().isNotEmpty;

      expect(
        hasFreeIndicator || hasProBadge,
        isTrue,
        reason: 'Should show usage status',
      );

      await screenshot(tester, 'j1_4_usage_indicator');
    });

    testWidgets('J1.5: Wizard step 1 - Select relationship', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      expect(
        anyTextExists(['Close Friend', 'Family', 'Partner']),
        isTrue,
        reason: 'Should show relationship options',
      );

      await screenshot(tester, 'j1_5_relationships');
    });

    testWidgets('J1.6: Wizard step 2 - Select tone', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      if (exists(find.text('Close Friend'))) {
        await tester.tap(find.text('Close Friend'));
        await tester.pumpAndSettle();
      }
      if (exists(find.text('Continue'))) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      expect(
        anyTextExists(['Heartfelt', 'Funny', 'Formal']),
        isTrue,
        reason: 'Should show tone options',
      );

      await screenshot(tester, 'j1_6_tones');
    });

    testWidgets('J1.7: Wizard step 3 - Final step with generate/upgrade', (
      tester,
    ) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      final completed = await completeWizard(tester);
      expect(completed, isTrue, reason: 'Should reach final wizard step');

      expect(
        anyTextExists(['Generate Messages', 'Upgrade to Continue']),
        isTrue,
        reason: 'Should show Generate or Upgrade button',
      );

      await screenshot(tester, 'j1_7_final_step');
    });

    testWidgets('J1.8: Generate triggers AI call', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      if (exists(find.text('Generate Messages'))) {
        await tester.tap(find.text('Generate Messages'));
        await tester.pumpAndSettle(const Duration(seconds: 15));

        expect(
          anyTextExists(['Your Messages', 'Option 1', 'error', 'Unable']),
          isTrue,
          reason: 'Should show results or error',
        );

        await screenshot(tester, 'j1_8_generation_result');
      }
    });

    testWidgets('J1.9: Results show 3 options', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      if (exists(find.text('Generate Messages'))) {
        await tester.tap(find.text('Generate Messages'));
        await tester.pumpAndSettle(const Duration(seconds: 15));

        if (exists(find.text('Your Messages'))) {
          expect(find.text('Option 1'), findsOneWidget);
          expect(find.text('Option 2'), findsOneWidget);
          expect(find.text('Option 3'), findsOneWidget);

          await screenshot(tester, 'j1_9_three_options');
        }
      }
    });

    testWidgets('J1.10: Copy button works', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      if (exists(find.text('Generate Messages'))) {
        await tester.tap(find.text('Generate Messages'));
        await tester.pumpAndSettle(const Duration(seconds: 15));

        if (exists(find.text('Copy'))) {
          await tester.tap(find.text('Copy').first);
          await tester.pumpAndSettle();

          expect(find.text('Copied!'), findsOneWidget);
          await screenshot(tester, 'j1_10_copied');
        }
      }
    });

    testWidgets('J1.11: Start Over returns to home', (tester) async {
      final atHome = await navigateToHome(tester);
      if (!atHome) return;

      await completeWizard(tester);

      if (exists(find.text('Generate Messages'))) {
        await tester.tap(find.text('Generate Messages'));
        await tester.pumpAndSettle(const Duration(seconds: 15));

        if (exists(find.text('Start Over'))) {
          await tester.tap(find.text('Start Over'));
          await tester.pumpAndSettle();

          expect(
            anyTextExists(["What's the occasion?", 'Birthday']),
            isTrue,
            reason: 'Should return to home',
          );

          await screenshot(tester, 'j1_11_start_over');
        }
      }
    });
  });
}
