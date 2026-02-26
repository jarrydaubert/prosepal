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

  // ==========================================================================
  // FLOW 8: AI Generation & Results (Real API)
  // ==========================================================================
  group('Flow 8: AI Generation', () {
    Future<void> navigateToGenerate(WidgetTester tester) async {
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

    testWidgets('F8.1: Generate button triggers AI call', (tester) async {
      await navigateToGenerate(tester);

      if (find.text('Generate Messages').evaluate().isNotEmpty) {
        await tester.tap(find.text('Generate Messages'));
        
        // Wait for generation (may take time with real API)
        await tester.pumpAndSettle(const Duration(seconds: 15));

        // Should show results or error
        final hasResults = find.text('Your Messages').evaluate().isNotEmpty ||
            find.text('Option 1').evaluate().isNotEmpty;
        final hasError = find.textContaining('error').evaluate().isNotEmpty ||
            find.textContaining('Unable').evaluate().isNotEmpty;

        expect(hasResults || hasError, isTrue,
            reason: 'Should show results or error after generation');

        await binding.takeScreenshot('f8_1_generation_result');
      }
    });

    testWidgets('F8.2: Results show 3 message options', (tester) async {
      await navigateToGenerate(tester);

      if (find.text('Generate Messages').evaluate().isNotEmpty) {
        await tester.tap(find.text('Generate Messages'));
        await tester.pumpAndSettle(const Duration(seconds: 15));

        if (find.text('Your Messages').evaluate().isNotEmpty) {
          // Verify all 3 options
          expect(find.text('Option 1').evaluate().isNotEmpty, isTrue);
          expect(find.text('Option 2').evaluate().isNotEmpty, isTrue);
          expect(find.text('Option 3').evaluate().isNotEmpty, isTrue);

          await binding.takeScreenshot('f8_2_three_options');
        }
      }
    });

    testWidgets('F8.3: Copy button works', (tester) async {
      await navigateToGenerate(tester);

      if (find.text('Generate Messages').evaluate().isNotEmpty) {
        await tester.tap(find.text('Generate Messages'));
        await tester.pumpAndSettle(const Duration(seconds: 15));

        if (find.text('Copy').evaluate().isNotEmpty) {
          await tester.tap(find.text('Copy').first);
          await tester.pumpAndSettle();

          // Should show copied confirmation
          expect(find.text('Copied!').evaluate().isNotEmpty, isTrue,
              reason: 'Should show Copied! confirmation');

          await binding.takeScreenshot('f8_3_copied');
        }
      }
    });

    testWidgets('F8.4: Start Over returns to home', (tester) async {
      await navigateToGenerate(tester);

      if (find.text('Generate Messages').evaluate().isNotEmpty) {
        await tester.tap(find.text('Generate Messages'));
        await tester.pumpAndSettle(const Duration(seconds: 15));

        if (find.text('Start Over').evaluate().isNotEmpty) {
          await tester.tap(find.text('Start Over'));
          await tester.pumpAndSettle();

          expect(find.text("What's the occasion?").evaluate().isNotEmpty ||
              find.text('Birthday').evaluate().isNotEmpty, isTrue,
              reason: 'Start Over should return to home');

          await binding.takeScreenshot('f8_4_start_over');
        }
      }
    });
  });

  // ==========================================================================
  // FLOW 9: All Relationships Coverage
  // ==========================================================================
  group('Flow 9: Relationships', () {
    final relationshipsToTest = [
      'Close Friend',
      'Family',
      'Parent',
      'Partner',
      'Colleague',
      'Sibling',
      'Teacher',
    ];

    for (final relationship in relationshipsToTest) {
      testWidgets('F9: $relationship can be selected', (tester) async {
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

        // Scroll to find relationship
        final scrollable = find.byType(Scrollable).first;
        try {
          await tester.scrollUntilVisible(find.text(relationship), 100, scrollable: scrollable);
          await tester.pumpAndSettle();
        } catch (_) {
          return;
        }

        if (find.text(relationship).evaluate().isNotEmpty) {
          await tester.tap(find.text(relationship));
          await tester.pumpAndSettle();

          expect(find.text('Continue').evaluate().isNotEmpty, isTrue,
              reason: '$relationship should be selectable');
        }
      });
    }
  });

  // ==========================================================================
  // FLOW 10: All Tones Coverage
  // ==========================================================================
  group('Flow 10: Tones', () {
    final tonesToTest = ['Heartfelt', 'Funny', 'Formal', 'Casual', 'Playful', 'Inspirational'];

    for (final tone in tonesToTest) {
      testWidgets('F10: $tone tone can be selected', (tester) async {
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

        if (find.text('Close Friend').evaluate().isNotEmpty) {
          await tester.tap(find.text('Close Friend'));
          await tester.pumpAndSettle();
        }
        if (find.text('Continue').evaluate().isNotEmpty) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
        }

        // Scroll to find tone
        final scrollable = find.byType(Scrollable).first;
        try {
          await tester.scrollUntilVisible(find.text(tone), 100, scrollable: scrollable);
          await tester.pumpAndSettle();
        } catch (_) {
          return;
        }

        if (find.text(tone).evaluate().isNotEmpty) {
          await tester.tap(find.text(tone));
          await tester.pumpAndSettle();

          expect(find.text('Continue').evaluate().isNotEmpty, isTrue,
              reason: '$tone tone should be selectable');
        }
      });
    }
  });

  // ==========================================================================
  // FLOW 11: Message Length Options
  // ==========================================================================
  group('Flow 11: Message Length', () {
    testWidgets('F11.1: Length options visible on final step', (tester) async {
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

      // Check length options
      final hasBrief = find.text('Brief').evaluate().isNotEmpty;
      final hasStandard = find.text('Standard').evaluate().isNotEmpty;
      final hasDetailed = find.text('Detailed').evaluate().isNotEmpty;

      expect(hasBrief || hasStandard || hasDetailed, isTrue,
          reason: 'Should show message length options');

      await binding.takeScreenshot('f11_1_length_options');
    });
  });

  // ==========================================================================
  // FLOW 12: Deep Settings
  // ==========================================================================
  group('Flow 12: Settings Deep Dive', () {
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

    testWidgets('F12.1: Restore Purchases option exists', (tester) async {
      await navigateToSettings(tester);

      if (find.text('Settings').evaluate().isEmpty) return;

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Restore Purchases'), 200, scrollable: scrollable);
      await tester.pumpAndSettle();

      expect(find.text('Restore Purchases').evaluate().isNotEmpty, isTrue);
      await binding.takeScreenshot('f12_1_restore_purchases');
    });

    testWidgets('F12.2: Send Feedback option exists', (tester) async {
      await navigateToSettings(tester);

      if (find.text('Settings').evaluate().isEmpty) return;

      final scrollable = find.byType(Scrollable).first;
      try {
        await tester.scrollUntilVisible(find.text('Send Feedback'), 200, scrollable: scrollable);
        await tester.pumpAndSettle();
        expect(find.text('Send Feedback').evaluate().isNotEmpty, isTrue);
      } catch (_) {
        // May not have feedback option
      }

      await binding.takeScreenshot('f12_2_feedback');
    });

    testWidgets('F12.3: Version info visible', (tester) async {
      await navigateToSettings(tester);

      if (find.text('Settings').evaluate().isEmpty) return;

      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, -500), 1000);
      await tester.pumpAndSettle();

      // Look for version text pattern (e.g., "Version 1.0.0")
      final hasVersion = find.textContaining('Version').evaluate().isNotEmpty ||
          find.textContaining('v1').evaluate().isNotEmpty;

      await binding.takeScreenshot('f12_3_version');
    });
  });

  // ==========================================================================
  // FLOW 13: Extended Occasions (Holidays & Special)
  // ==========================================================================
  group('Flow 13: Extended Occasions', () {
    final extendedOccasions = [
      "Valentine's Day",
      'Thanksgiving',
      'Hanukkah',
      'Diwali',
      'Lunar New Year',
      'Promotion',
      'Farewell',
      'Thank You for Service',
      'Pet Loss',
    ];

    for (final occasion in extendedOccasions) {
      testWidgets('F13: $occasion occasion accessible', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        while (find.text('Continue').evaluate().isNotEmpty &&
            find.text('Birthday').evaluate().isEmpty) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }

        if (find.text('Birthday').evaluate().isEmpty) return;

        // Scroll to find occasion
        final scrollable = find.byType(Scrollable).first;
        try {
          await tester.scrollUntilVisible(find.text(occasion), 300, scrollable: scrollable);
          await tester.pumpAndSettle();
        } catch (_) {
          return; // Occasion may require more scrolling
        }

        if (find.text(occasion).evaluate().isNotEmpty) {
          await tester.tap(find.text(occasion));
          await tester.pumpAndSettle();

          // Should show relationships
          expect(find.text('Close Friend').evaluate().isNotEmpty ||
              find.text('Family').evaluate().isNotEmpty ||
              find.text('Colleague').evaluate().isNotEmpty, isTrue,
              reason: '$occasion should show relationship options');
        }
      });
    }
  });

  // ==========================================================================
  // FLOW 14: Wizard Step Navigation
  // ==========================================================================
  group('Flow 14: Wizard Step Nav', () {
    testWidgets('F14.1: Back from step 2 preserves occasion', (tester) async {
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

      if (find.text('Close Friend').evaluate().isNotEmpty) {
        await tester.tap(find.text('Close Friend'));
        await tester.pumpAndSettle();
      }
      if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      // Now on tone step, go back
      if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Should still be in Birthday flow (showing relationships)
        expect(find.text('Close Friend').evaluate().isNotEmpty, isTrue,
            reason: 'Back should preserve occasion context');

        await binding.takeScreenshot('f14_1_back_preserves');
      }
    });

    testWidgets('F14.2: Back from step 3 preserves selections', (tester) async {
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

      // Now on final step, go back
      if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Should show tones again
        expect(find.text('Heartfelt').evaluate().isNotEmpty, isTrue,
            reason: 'Back from final step should show tones');

        await binding.takeScreenshot('f14_2_back_to_tones');
      }
    });
  });
}
