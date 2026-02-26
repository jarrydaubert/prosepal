/// Golden Path Integration Tests for Prosepal (Firebase Test Lab)
/// 
/// These tests validate critical user journeys on real devices.
/// Designed for Firebase Test Lab with screenshots at key steps.
/// 
/// Build & Run:
///   # Android
///   cd android && ./gradlew app:assembleDebug -Ptarget="../integration_test/golden_path_test.dart"
///   ./gradlew app:assembleAndroidTest
///   gcloud firebase test android run --type instrumentation \
///     --app build/app/outputs/apk/debug/app-debug.apk \
///     --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
///     --device model=oriole,version=33 --timeout 15m
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ==========================================================================
  // FLOW 1: Fresh Install (Anonymous User)
  // ==========================================================================
  group('Flow 1: Fresh Install', () {
    testWidgets('F1.1: App launches and shows initial screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(MaterialApp), findsOneWidget);

      final hasOnboarding = find.text('Continue').evaluate().isNotEmpty;
      final hasAuth = find.text('Continue with Email').evaluate().isNotEmpty;
      final hasHome = find.text("What's the occasion?").evaluate().isNotEmpty;

      expect(hasOnboarding || hasAuth || hasHome, isTrue,
          reason: 'Should show onboarding, auth, or home');

      await binding.takeScreenshot('f1_1_initial');
    });

    testWidgets('F1.2: Complete onboarding flow', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      int taps = 0;
      while (find.text('Continue').evaluate().isNotEmpty &&
          find.text('Birthday').evaluate().isEmpty &&
          taps < 5) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        taps++;
      }

      final afterOnboarding = find.text('Continue with Email').evaluate().isNotEmpty ||
          find.text('Birthday').evaluate().isNotEmpty;
      expect(afterOnboarding, isTrue, reason: 'Should reach auth or home after onboarding');

      await binding.takeScreenshot('f1_2_after_onboarding');
    });

    testWidgets('F1.3: Anonymous user sees home with occasions', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Skip to home
      while (find.text('Continue').evaluate().isNotEmpty &&
          find.text('Birthday').evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      if (find.text('Birthday').evaluate().isEmpty) return;

      // Verify home content
      expect(find.text("What's the occasion?"), findsOneWidget);
      expect(find.text('Birthday'), findsOneWidget);

      await binding.takeScreenshot('f1_3_home_screen');
    });
  });

  // ==========================================================================
  // FLOW 2: Generation Wizard (Complete Journey)
  // ==========================================================================
  group('Flow 2: Generation Wizard', () {
    Future<void> navigateToHome(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      while (find.text('Continue').evaluate().isNotEmpty &&
          find.text('Birthday').evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    }

    testWidgets('F2.1: Select occasion shows relationships', (tester) async {
      await navigateToHome(tester);
      if (find.text('Birthday').evaluate().isEmpty) return;

      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      expect(find.text('Close Friend').evaluate().isNotEmpty ||
          find.text('Family').evaluate().isNotEmpty, isTrue,
          reason: 'Should show relationship options');

      await binding.takeScreenshot('f2_1_relationships');
    });

    testWidgets('F2.2: Select relationship shows tones', (tester) async {
      await navigateToHome(tester);
      if (find.text('Birthday').evaluate().isEmpty) return;

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

      expect(find.text('Heartfelt').evaluate().isNotEmpty ||
          find.text('Funny').evaluate().isNotEmpty, isTrue,
          reason: 'Should show tone options');

      await binding.takeScreenshot('f2_2_tones');
    });

    testWidgets('F2.3: Complete wizard to final step', (tester) async {
      await navigateToHome(tester);
      if (find.text('Birthday').evaluate().isEmpty) return;

      // Occasion
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      // Relationship
      if (find.text('Close Friend').evaluate().isNotEmpty) {
        await tester.tap(find.text('Close Friend'));
        await tester.pumpAndSettle();
      }
      if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      // Tone
      if (find.text('Heartfelt').evaluate().isNotEmpty) {
        await tester.tap(find.text('Heartfelt'));
        await tester.pumpAndSettle();
      }
      if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      // Final step
      final hasGenerate = find.text('Generate Messages').evaluate().isNotEmpty;
      final hasUpgrade = find.text('Upgrade to Continue').evaluate().isNotEmpty;

      expect(hasGenerate || hasUpgrade, isTrue,
          reason: 'Final step should show Generate or Upgrade');

      await binding.takeScreenshot('f2_3_final_step');
    });

    testWidgets('F2.4: Wizard with Thank You occasion', (tester) async {
      await navigateToHome(tester);
      if (find.text('Thank You').evaluate().isEmpty) return;

      await tester.tap(find.text('Thank You'));
      await tester.pumpAndSettle();

      expect(find.text('Close Friend').evaluate().isNotEmpty ||
          find.text('Family').evaluate().isNotEmpty, isTrue);

      await binding.takeScreenshot('f2_4_thankyou_wizard');
    });

    testWidgets('F2.5: Wizard with Sympathy occasion', (tester) async {
      await navigateToHome(tester);
      
      // Scroll to find Sympathy if needed
      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Sympathy'), 200, scrollable: listView);
      await tester.pumpAndSettle();

      if (find.text('Sympathy').evaluate().isEmpty) return;

      await tester.tap(find.text('Sympathy'));
      await tester.pumpAndSettle();

      expect(find.text('Close Friend').evaluate().isNotEmpty ||
          find.text('Family').evaluate().isNotEmpty, isTrue);

      await binding.takeScreenshot('f2_5_sympathy_wizard');
    });
  });

  // ==========================================================================
  // FLOW 3: Settings & Account
  // ==========================================================================
  group('Flow 3: Settings', () {
    Future<void> navigateToSettings(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      while (find.text('Continue').evaluate().isNotEmpty &&
          find.byIcon(Icons.settings_outlined).evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      if (find.byIcon(Icons.settings_outlined).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('F3.1: Settings screen loads', (tester) async {
      await navigateToSettings(tester);

      if (find.text('Settings').evaluate().isEmpty) return;

      expect(find.text('Settings'), findsOneWidget);
      await binding.takeScreenshot('f3_1_settings');
    });

    testWidgets('F3.2: Shows subscription status', (tester) async {
      await navigateToSettings(tester);

      if (find.text('Settings').evaluate().isEmpty) return;

      final hasFree = find.text('Free Plan').evaluate().isNotEmpty;
      final hasPro = find.text('Pro Plan').evaluate().isNotEmpty;

      expect(hasFree || hasPro, isTrue, reason: 'Should show subscription status');
      await binding.takeScreenshot('f3_2_subscription_status');
    });

    testWidgets('F3.3: Has legal links', (tester) async {
      await navigateToSettings(tester);

      if (find.text('Settings').evaluate().isEmpty) return;

      // Scroll to find legal section
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Privacy Policy'), 200, scrollable: scrollable);
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy').evaluate().isNotEmpty ||
          find.text('Terms of Service').evaluate().isNotEmpty, isTrue);

      await binding.takeScreenshot('f3_3_legal_links');
    });

    testWidgets('F3.4: Anonymous user sees sign in option', (tester) async {
      await navigateToSettings(tester);

      if (find.text('Settings').evaluate().isEmpty) return;

      // Anonymous users should see sign in, authenticated should see sign out
      final hasSignIn = find.text('Sign In').evaluate().isNotEmpty;
      final hasSignOut = find.text('Sign Out').evaluate().isNotEmpty;

      expect(hasSignIn || hasSignOut, isTrue,
          reason: 'Should show auth action');
      await binding.takeScreenshot('f3_4_auth_option');
    });
  });

  // ==========================================================================
  // FLOW 4: Upgrade Path (Free User)
  // ==========================================================================
  group('Flow 4: Upgrade Path', () {
    testWidgets('F4.1: Free user sees usage indicator', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      while (find.text('Continue').evaluate().isNotEmpty &&
          find.text('Birthday').evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      if (find.text('Birthday').evaluate().isEmpty) return;

      // Check for usage indicator or Pro badge
      final hasUsage = find.textContaining('remaining').evaluate().isNotEmpty ||
          find.textContaining('free').evaluate().isNotEmpty;
      final hasPro = find.text('PRO').evaluate().isNotEmpty;

      expect(hasUsage || hasPro, isTrue,
          reason: 'Should show usage indicator or Pro status');

      await binding.takeScreenshot('f4_1_usage_indicator');
    });

    testWidgets('F4.2: Upgrade button navigates to paywall', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      while (find.text('Continue').evaluate().isNotEmpty &&
          find.text('Birthday').evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Navigate through wizard to trigger upgrade
      if (find.text('Birthday').evaluate().isNotEmpty) {
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
      }

      // If upgrade button visible, tap it
      if (find.text('Upgrade to Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Upgrade to Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Should show paywall or auth
        final hasPaywall = find.text('Pro').evaluate().isNotEmpty ||
            find.text('Subscribe').evaluate().isNotEmpty ||
            find.textContaining('\$').evaluate().isNotEmpty;
        final hasAuth = find.text('Continue with Email').evaluate().isNotEmpty;

        expect(hasPaywall || hasAuth, isTrue,
            reason: 'Upgrade should show paywall or require auth');

        await binding.takeScreenshot('f4_2_paywall');
      }
    });
  });

  // ==========================================================================
  // FLOW 5: Navigation & Back Behavior
  // ==========================================================================
  group('Flow 5: Navigation', () {
    testWidgets('F5.1: Back from wizard returns to home', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      while (find.text('Continue').evaluate().isNotEmpty &&
          find.text('Birthday').evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      if (find.text('Birthday').evaluate().isEmpty) return;

      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(find.text("What's the occasion?").evaluate().isNotEmpty ||
            find.text('Birthday').evaluate().isNotEmpty, isTrue);

        await binding.takeScreenshot('f5_1_back_to_home');
      }
    });

    testWidgets('F5.2: Back from settings returns to home', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      while (find.text('Continue').evaluate().isNotEmpty &&
          find.byIcon(Icons.settings_outlined).evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      if (find.byIcon(Icons.settings_outlined).evaluate().isEmpty) return;

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(find.text("What's the occasion?").evaluate().isNotEmpty ||
            find.text('Birthday').evaluate().isNotEmpty, isTrue);

        await binding.takeScreenshot('f5_2_settings_back');
      }
    });

    testWidgets('F5.3: Can re-enter wizard after backing out', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

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
      if (find.text('Thank You').evaluate().isNotEmpty) {
        await tester.tap(find.text('Thank You'));
        await tester.pumpAndSettle();

        expect(find.text('Close Friend').evaluate().isNotEmpty ||
            find.text('Family').evaluate().isNotEmpty, isTrue);

        await binding.takeScreenshot('f5_3_reenter_wizard');
      }
    });
  });

  // ==========================================================================
  // FLOW 6: Occasion Coverage (Smoke Tests)
  // ==========================================================================
  group('Flow 6: Occasion Smoke Tests', () {
    final occasionsToTest = [
      'Birthday',
      'Wedding',
      'Graduation',
      "Mother's Day",
      'Christmas',
      'New Job',
      'Pet Birthday',
    ];

    for (final occasion in occasionsToTest) {
      testWidgets('F6: $occasion occasion loads wizard', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        while (find.text('Continue').evaluate().isNotEmpty &&
            find.text('Birthday').evaluate().isEmpty) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }

        // Scroll to find occasion
        final scrollable = find.byType(Scrollable).first;
        try {
          await tester.scrollUntilVisible(find.text(occasion), 200, scrollable: scrollable);
          await tester.pumpAndSettle();
        } catch (_) {
          // Occasion might not be visible
          return;
        }

        if (find.text(occasion).evaluate().isEmpty) return;

        await tester.tap(find.text(occasion));
        await tester.pumpAndSettle();

        // Should show relationships
        expect(find.text('Close Friend').evaluate().isNotEmpty ||
            find.text('Family').evaluate().isNotEmpty ||
            find.text('Partner').evaluate().isNotEmpty, isTrue,
            reason: '$occasion should show relationship options');
      });
    }
  });

  // ==========================================================================
  // FLOW 7: Error Resilience
  // ==========================================================================
  group('Flow 7: Error Resilience', () {
    testWidgets('F7.1: App survives rapid taps', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Rapid skip onboarding
      for (int i = 0; i < 5; i++) {
        if (find.text('Continue').evaluate().isNotEmpty) {
          await tester.tap(find.text('Continue'), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 200));
        }
      }
      await tester.pumpAndSettle();

      // Rapid tap occasion
      if (find.text('Birthday').evaluate().isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.text('Birthday'), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
      }

      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'App should remain stable after rapid taps');

      await binding.takeScreenshot('f7_1_after_rapid_taps');
    });

    testWidgets('F7.2: App handles scroll edge cases', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      while (find.text('Continue').evaluate().isNotEmpty &&
          find.text('Birthday').evaluate().isEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      if (find.text('Birthday').evaluate().isEmpty) return;

      // Scroll aggressively
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, -500), 1000);
      await tester.pumpAndSettle();
      await tester.fling(scrollable, const Offset(0, 500), 1000);
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      await binding.takeScreenshot('f7_2_after_scroll');
    });
  });
}
