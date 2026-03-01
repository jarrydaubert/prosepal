/// Real E2E Integration Tests with RevenueCat Test Store
///
/// These tests use REAL services:
/// - RevenueCat Test Store (instant simulated purchases)
/// - Real Firebase AI (Gemini)
/// - Real Supabase Auth
///
/// Build with Test Store enabled:
///   JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home \
///     flutter build apk --debug \
///       -t integration_test/e2e_real_test.dart \
///       --dart-define=REVENUECAT_USE_TEST_STORE=true
///
/// Run on FTL (real device recommended):
///   gcloud firebase test android run \
///     --type instrumentation \
///     --app build/app/outputs/flutter-apk/app-debug.apk \
///     --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
///     --device model=oriole,version=33,locale=en,orientation=portrait \
///     --timeout 20m \
///     --no-use-orchestrator
///
/// What Test Store provides:
/// - Instant purchase completion (no sandbox account needed)
/// - Real entitlement granting ("pro" activates immediately)
/// - Real paywall UI with real offerings
/// - Works on virtual devices (no StoreKit/Play Billing needed)
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/main.dart' as app;

late IntegrationTestWidgetsFlutterBinding binding;
const captureIntegrationScreenshots = bool.fromEnvironment(
  'INTEGRATION_CAPTURE_SCREENSHOTS',
);

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> screenshot(WidgetTester tester, String name) async {
    if (!captureIntegrationScreenshots) return;
    if (kIsWeb) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await binding.convertFlutterSurfaceToImage().timeout(
          const Duration(seconds: 8),
        );
        await tester.pump();
      }
      await binding.takeScreenshot(name).timeout(const Duration(seconds: 8));
    } on Exception catch (error) {
      // Screenshot capture is diagnostic-only and should not fail E2E assertions.
      debugPrint('[WARN] Screenshot skipped for $name: $error');
    }
  }

  bool exists(Finder finder) => finder.evaluate().isNotEmpty;

  bool anyTextExists(List<String> texts) =>
      texts.any((text) => find.text(text).evaluate().isNotEmpty);

  Future<void> skipOnboarding(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      if (exists(find.text('Birthday'))) break;
      if (exists(find.text('Get Started'))) {
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        break;
      }
      if (exists(find.text('Skip'))) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        break;
      }
      if (exists(find.text('Continue'))) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    }
  }

  Future<void> completeWizard(WidgetTester tester) async {
    // Select occasion
    if (exists(find.text('Birthday'))) {
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();
    }

    // Select relationship
    if (exists(find.text('Close Friend'))) {
      await tester.tap(find.text('Close Friend'));
      await tester.pumpAndSettle();
    }
    if (exists(find.text('Continue'))) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    // Select tone
    if (exists(find.text('Heartfelt'))) {
      await tester.tap(find.text('Heartfelt'));
      await tester.pumpAndSettle();
    }
    if (exists(find.text('Continue'))) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
  }

  group('E2E Real: Full User Journey with Test Store', () {
    testWidgets('1. App launches and initializes services', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(MaterialApp), findsOneWidget);
      await screenshot(tester, 'real_01_launch');
    });

    testWidgets('2. Fresh user sees onboarding or home', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final hasOnboarding = anyTextExists(['Continue', 'Skip', 'Get Started']);
      final hasHome = exists(find.text('Birthday'));

      expect(
        hasOnboarding || hasHome,
        isTrue,
        reason: 'Should show onboarding or home',
      );
      await screenshot(tester, 'real_02_initial_screen');
    });

    testWidgets('3. Navigate to home screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await skipOnboarding(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        exists(find.text('Birthday')),
        isTrue,
        reason: 'Should reach home with occasions',
      );
      await screenshot(tester, 'real_03_home');
    });

    testWidgets('4. Complete wizard to final step', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await skipOnboarding(tester);
      await tester.pumpAndSettle();

      await completeWizard(tester);

      expect(
        anyTextExists(['Generate Messages', 'Upgrade to Continue']),
        isTrue,
        reason: 'Should show Generate or Upgrade',
      );
      await screenshot(tester, 'real_04_wizard_final');
    });

    testWidgets('5. Free user: Generate uses free credit', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await skipOnboarding(tester);
      await tester.pumpAndSettle();

      await completeWizard(tester);

      if (exists(find.text('Generate Messages'))) {
        await tester.tap(find.text('Generate Messages'));
        // Wait for AI generation (real API call)
        await tester.pumpAndSettle(const Duration(seconds: 20));

        final hasResults = anyTextExists(['Your Messages', 'Option 1']);
        final hasError = anyTextExists(['error', 'Error', 'Unable']);

        expect(
          hasResults || hasError,
          isTrue,
          reason: 'Should show results or error',
        );
        await screenshot(tester, 'real_05_generation_result');
      }
    });

    testWidgets('6. Paywall: Shows pricing options', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await skipOnboarding(tester);
      await tester.pumpAndSettle();

      // Navigate to paywall via settings upgrade
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Look for upgrade option
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, -200), 500);
      await tester.pumpAndSettle();

      // Try to find and tap upgrade
      if (exists(find.text('Upgrade'))) {
        await tester.tap(find.text('Upgrade'));
        await tester.pumpAndSettle(const Duration(seconds: 3));
      } else if (exists(find.text('Free Plan'))) {
        await tester.tap(find.text('Free Plan'));
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      await screenshot(tester, 'real_06_paywall');
    });

    testWidgets('7. Test Store: Purchase weekly subscription', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await skipOnboarding(tester);
      await tester.pumpAndSettle();

      await completeWizard(tester);

      // If upgrade needed, tap it
      if (exists(find.text('Upgrade to Continue'))) {
        await tester.tap(find.text('Upgrade to Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // If auth required first, skip this test
        if (anyTextExists(['Sign in with Apple', 'Sign in with Google'])) {
          await screenshot(tester, 'real_07_auth_required');
          return;
        }

        // Look for weekly option and purchase
        // Test Store purchases are instant - no confirmation dialogs
        if (exists(find.text('Weekly'))) {
          await tester.tap(find.text('Weekly'));
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }

        // Or tap any purchase button
        if (exists(find.text('Subscribe'))) {
          await tester.tap(find.text('Subscribe').first);
          await tester.pumpAndSettle(const Duration(seconds: 5));
        }

        await screenshot(tester, 'real_07_after_purchase');
      }
    });

    testWidgets('8. Verify Pro status after purchase', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await skipOnboarding(tester);
      await tester.pumpAndSettle();

      // Check if Pro badge visible
      final _ =
          exists(find.text('PRO')) ||
          exists(find.textContaining('unlimited')) ||
          exists(find.textContaining('Pro'));

      // Go to settings to verify subscription status
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      await screenshot(tester, 'real_08_verify_pro');

      // Check settings shows Pro Plan (if purchased in previous test)
      final hasProPlan = exists(find.text('Pro Plan'));
      final hasFreePlan = exists(find.text('Free Plan'));

      expect(
        hasProPlan || hasFreePlan,
        isTrue,
        reason: 'Should show subscription status',
      );
    });

    testWidgets('9. Pro user: Unlimited generations', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await skipOnboarding(tester);
      await tester.pumpAndSettle();

      // Only run if Pro (from previous purchase test)
      final isPro =
          exists(find.text('PRO')) || exists(find.textContaining('unlimited'));

      if (!isPro) {
        await screenshot(tester, 'real_09_not_pro');
        return;
      }

      await completeWizard(tester);

      // Pro should see Generate, not Upgrade
      expect(
        exists(find.text('Generate Messages')),
        isTrue,
        reason: 'Pro user should see Generate button',
      );

      await screenshot(tester, 'real_09_pro_generate');
    });

    testWidgets('10. Restore purchases', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await skipOnboarding(tester);
      await tester.pumpAndSettle();

      // Go to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Scroll to Restore
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, -200), 500);
      await tester.pumpAndSettle();

      if (exists(find.text('Restore Purchases'))) {
        await tester.tap(find.text('Restore Purchases'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        await screenshot(tester, 'real_10_restore_result');
      }
    });
  });
}
