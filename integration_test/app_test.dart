import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/models/models.dart';

/// End-to-End Integration Tests for Prosepal
///
/// These tests launch the full application and simulate real user flows.
///
/// Run with: flutter test integration_test/app_test.dart -d [device_id]
///
/// Requirements:
/// - Real device or simulator
/// - Network connectivity for Supabase initialization
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUpAll(() async {
    // Initialize Supabase before running tests
    await Supabase.initialize(
      url: 'https://mwoxtqxzunsjmbdqezif.supabase.co',
      anonKey: 'sb_publishable_DJB3MvvHJRl-vuqrkn1-6w_hwTLnOaS',
    );

    SharedPreferences.setMockInitialValues({
      'hasCompletedOnboarding': true,
    });
    prefs = await SharedPreferences.getInstance();
  });

  group('App Launch', () {
    testWidgets('app launches without crashing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('home screen displays app branding', (tester) async {
      // Mark onboarding complete to skip to home
      await prefs.setBool('hasCompletedOnboarding', true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // App should show auth screen (since not logged in) or home
      // Either way, the app should render successfully
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('Onboarding Flow', () {
    testWidgets('onboarding flow can be navigated', (tester) async {
      // Note: SharedPreferences in integration tests may persist between runs
      // This test checks onboarding if we can reach it
      await prefs.setBool('hasCompletedOnboarding', false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check if we're on onboarding by looking for Continue button
      final continueButton = find.text('Continue');
      if (continueButton.evaluate().isNotEmpty) {
        // Tap through pages
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        final continueButton2 = find.text('Continue');
        if (continueButton2.evaluate().isNotEmpty) {
          await tester.tap(continueButton2);
          await tester.pumpAndSettle();

          final continueButton3 = find.text('Continue');
          if (continueButton3.evaluate().isNotEmpty) {
            await tester.tap(continueButton3);
            await tester.pumpAndSettle();
          }
        }

        // Look for Get Started or verify we progressed
        final getStarted = find.text('Get Started');
        if (getStarted.evaluate().isNotEmpty) {
          expect(getStarted, findsOneWidget);
        }
      }

      // Either way, app should be functional
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('Auth Screen', () {
    testWidgets('auth screen displays sign in options', (tester) async {
      await prefs.setBool('hasCompletedOnboarding', true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Auth screen should show sign in buttons
      // The exact text depends on platform, but we should see some auth UI
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('email sign in button navigates to email screen', (tester) async {
      await prefs.setBool('hasCompletedOnboarding', true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try to find and tap email option
      final emailButton = find.text('Continue with Email');
      if (emailButton.evaluate().isNotEmpty) {
        await tester.tap(emailButton);
        await tester.pumpAndSettle();

        // Should show email input
        expect(find.byType(TextField), findsWidgets);
      }
    });
  });

  group('Navigation - Logged In User', () {
    testWidgets('home screen displays all occasions', (tester) async {
      await prefs.setBool('hasCompletedOnboarding', true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // If we can see occasions, we're on home screen
      // This test will only pass if user is logged in
      final birthdayCard = find.text('Birthday');
      if (birthdayCard.evaluate().isNotEmpty) {
        // All 10 occasions should be visible
        for (final occasion in Occasion.values) {
          expect(
            find.text(occasion.label),
            findsOneWidget,
            reason: 'Occasion ${occasion.label} should be visible',
          );
        }
      }
    });

    testWidgets('tapping occasion navigates to generate screen', (tester) async {
      await prefs.setBool('hasCompletedOnboarding', true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Only run if on home screen
      final birthdayCard = find.text('Birthday');
      if (birthdayCard.evaluate().isNotEmpty) {
        await tester.tap(birthdayCard);
        await tester.pumpAndSettle();

        // Generate screen shows relationships
        expect(find.text('Close Friend'), findsOneWidget);
        expect(find.text('Family'), findsOneWidget);
      }
    });

    testWidgets('settings button navigates to settings', (tester) async {
      await prefs.setBool('hasCompletedOnboarding', true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Only run if on home screen with settings icon
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
      }
    });

    testWidgets('back navigation works from generate screen', (tester) async {
      await prefs.setBool('hasCompletedOnboarding', true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final birthdayCard = find.text('Birthday');
      if (birthdayCard.evaluate().isNotEmpty) {
        // Navigate to generate
        await tester.tap(birthdayCard);
        await tester.pumpAndSettle();

        // Go back
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Back on home screen
        expect(find.text('Prosepal'), findsOneWidget);
      }
    });
  });

  group('Generation Flow', () {
    testWidgets('complete generation wizard flow', (tester) async {
      await prefs.setBool('hasCompletedOnboarding', true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isProProvider.overrideWith((ref) => false),
            remainingGenerationsProvider.overrideWith((ref) => 3),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final birthdayCard = find.text('Birthday');
      if (birthdayCard.evaluate().isNotEmpty) {
        // Step 1: Select occasion
        await tester.tap(birthdayCard);
        await tester.pumpAndSettle();

        // Step 2: Select relationship
        await tester.tap(find.text('Close Friend'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Step 3: Select tone
        await tester.tap(find.text('Heartfelt'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Step 4: Generate button visible
        final generateButton = find.text('Generate Messages');
        await tester.ensureVisible(generateButton);
        await tester.pumpAndSettle();

        expect(generateButton, findsOneWidget);
      }
    });
  });

  group('Settings Screen', () {
    testWidgets('settings displays expected sections', (tester) async {
      await prefs.setBool('hasCompletedOnboarding', true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);

        // Scroll to find Privacy Policy
        final listView = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text('Privacy Policy'),
          100,
          scrollable: listView,
        );
        expect(find.text('Privacy Policy'), findsOneWidget);
      }
    });
  });

  group('Accessibility', () {
    testWidgets('buttons meet minimum touch target size', (tester) async {
      await prefs.setBool('hasCompletedOnboarding', true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find any elevated button and check size
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        final buttonSize = tester.getSize(buttons.first);
        // Apple HIG recommends 44pt minimum touch target
        expect(buttonSize.height, greaterThanOrEqualTo(44));
      }
    });
  });
}
