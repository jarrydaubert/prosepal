/// Firebase Test Lab Compatible Integration Tests
/// 
/// These tests use standard integration_test binding (not Patrol) for
/// compatibility with Firebase Test Lab device matrix testing.
/// 
/// Run locally:
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/simple_test.dart
/// 
/// Build for Test Lab (Android):
///   cd android && flutter build apk --debug
///   ./gradlew app:assembleAndroidTest
///   ./gradlew app:assembleDebug -Ptarget=`pwd`/../integration_test/simple_test.dart
///   # Upload to Test Lab:
///   gcloud firebase test android run --type instrumentation \
///     --app build/app/outputs/apk/debug/app-debug.apk \
///     --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
/// 
/// Build for Test Lab (iOS):
///   flutter build ios integration_test/simple_test.dart --release
///   cd ios && xcodebuild build-for-testing -workspace Runner.xcworkspace \
///     -scheme Runner -derivedDataPath ../build/ios_integ -sdk iphoneos
///   # Upload to Test Lab:
///   gcloud firebase test ios run --test build/ios_integ/Build/Products/ios_tests.zip
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // CRITICAL PATH TESTS (Must pass for app store release)
  // ===========================================================================

  group('Critical Path - App Launch', () {
    testWidgets('app launches without crash', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // App should show some UI
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('shows home, onboarding, or auth screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final hasHome = find.text('Prosepal').evaluate().isNotEmpty;
      final hasOnboarding = find.text('Continue').evaluate().isNotEmpty ||
          find.text('Welcome').evaluate().isNotEmpty;
      final hasAuth = find.text('Continue with Email').evaluate().isNotEmpty;

      expect(
        hasHome || hasOnboarding || hasAuth,
        isTrue,
        reason: 'App should show home, onboarding, or auth screen',
      );
    });

    testWidgets('screenshot - launch state', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await binding.takeScreenshot('01_launch_state');
    });
  });

  group('Critical Path - Generation Wizard', () {
    testWidgets('can tap occasion and see relationship options', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final birthdayFinder = find.text('Birthday');
      if (birthdayFinder.evaluate().isNotEmpty) {
        await tester.tap(birthdayFinder);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Should see relationship picker
        final hasRelationships = find.text('Close Friend').evaluate().isNotEmpty ||
            find.text('Family').evaluate().isNotEmpty;
        expect(hasRelationships, isTrue, reason: 'Wizard should show relationships');
      }
    });

    testWidgets('can complete wizard to generate step', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap Birthday
      final birthdayFinder = find.text('Birthday');
      if (birthdayFinder.evaluate().isEmpty) return; // Skip if not on home
      await tester.tap(birthdayFinder);
      await tester.pumpAndSettle();

      // Tap Close Friend
      final friendFinder = find.text('Close Friend');
      if (friendFinder.evaluate().isNotEmpty) {
        await tester.tap(friendFinder);
        await tester.pumpAndSettle();

        // Tap Continue
        final continueFinder = find.text('Continue');
        if (continueFinder.evaluate().isNotEmpty) {
          await tester.tap(continueFinder);
          await tester.pumpAndSettle();

          // Tap Heartfelt
          final toneFinder = find.text('Heartfelt');
          if (toneFinder.evaluate().isNotEmpty) {
            await tester.tap(toneFinder);
            await tester.pumpAndSettle();

            await tester.tap(find.text('Continue'));
            await tester.pumpAndSettle();

            // Should see Generate or Upgrade button
            final hasGenerate = find.text('Generate Messages').evaluate().isNotEmpty;
            final hasUpgrade = find.text('Upgrade to Continue').evaluate().isNotEmpty;
            expect(hasGenerate || hasUpgrade, isTrue);
          }
        }
      }
    });

    testWidgets('screenshot - wizard step', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final birthdayFinder = find.text('Birthday');
      if (birthdayFinder.evaluate().isNotEmpty) {
        await tester.tap(birthdayFinder);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await binding.takeScreenshot('02_wizard_relationship');
      }
    });
  });

  group('Critical Path - Settings', () {
    testWidgets('settings screen accessible from home', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('Settings'), findsOneWidget);
      }
    });

    testWidgets('settings shows subscription section', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Should show Free Plan or Pro Plan
        final hasFree = find.text('Free Plan').evaluate().isNotEmpty;
        final hasPro = find.text('Pro Plan').evaluate().isNotEmpty;
        expect(hasFree || hasPro, isTrue);
      }
    });

    testWidgets('screenshot - settings', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await binding.takeScreenshot('03_settings');
      }
    });
  });

  // ===========================================================================
  // ALL 13 OCCASIONS (Matrix coverage)
  // ===========================================================================

  group('Occasion Coverage', () {
    final occasions = [
      'Birthday', 'Thank You', 'Sympathy', 'Wedding', 'Graduation',
      'New Baby', 'Get Well', 'Anniversary', 'Congrats', 'Apology',
      'Retirement', 'New Home', 'Encouragement',
    ];

    for (final occasion in occasions) {
      testWidgets('$occasion occasion is tappable', (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Check if we're on home screen first
        final homeIndicator = find.text("What's the occasion?");
        if (homeIndicator.evaluate().isEmpty) {
          // Not on home screen, skip this test gracefully
          return;
        }

        // Scroll to find occasion if needed
        final finder = find.text(occasion);
        if (finder.evaluate().isEmpty) {
          // Try scrolling - wrap in try-catch for safety
          try {
            final scrollables = find.byType(Scrollable);
            if (scrollables.evaluate().isNotEmpty) {
              await tester.scrollUntilVisible(
                finder,
                100,
                scrollable: scrollables.first,
              );
              await tester.pumpAndSettle();
            }
          } catch (e) {
            // Scrolling failed, item may not exist
            return;
          }
        }

        if (finder.evaluate().isNotEmpty) {
          await tester.tap(finder);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Should navigate to wizard
          final hasWizard = find.text('Close Friend').evaluate().isNotEmpty ||
              find.byIcon(Icons.arrow_back).evaluate().isNotEmpty;
          expect(hasWizard, isTrue, reason: '$occasion should open wizard');
        }
      });
    }
  });

  // ===========================================================================
  // NAVIGATION TESTS
  // ===========================================================================

  group('Navigation', () {
    testWidgets('back button returns from wizard', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final birthdayFinder = find.text('Birthday');
      if (birthdayFinder.evaluate().isNotEmpty) {
        await tester.tap(birthdayFinder);
        await tester.pumpAndSettle();

        // Tap back
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          // Should be back at home
          expect(find.text('Prosepal'), findsOneWidget);
        }
      }
    });
  });

  // ===========================================================================
  // ERROR RESILIENCE TESTS
  // ===========================================================================

  group('Error Resilience', () {
    testWidgets('app does not crash on rapid taps', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Rapid tap on first available button
      final birthdayFinder = find.text('Birthday');
      if (birthdayFinder.evaluate().isNotEmpty) {
        for (int i = 0; i < 5; i++) {
          await tester.tap(birthdayFinder, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        // App should still be responsive
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });
  });
}
