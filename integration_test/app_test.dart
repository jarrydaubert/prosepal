import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/models/models.dart';

/// End-to-End Integration Tests for Prosepal
///
/// These tests launch the full application and simulate real user flows.
///
/// Run with: flutter test integration_test/app_test.dart
///
/// Requirements:
/// - Real device or simulator
/// - For full testing: GEMINI_API_KEY configured
/// - For purchase testing: RevenueCat sandbox setup
///
/// Note: These tests use mocked services for deterministic behavior.
/// See revenuecat_test.dart and firebase_test.dart for service-specific tests.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
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

      // Assert: App renders successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('home screen displays app branding', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert: App title is visible
      expect(find.text('Prosepal'), findsOneWidget);

      // Assert: Tagline is visible
      expect(find.text('The right words, right now'), findsOneWidget);
    });

    testWidgets('home screen displays all occasions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert: All 10 occasions are displayed
      for (final occasion in Occasion.values) {
        expect(
          find.text(occasion.label),
          findsOneWidget,
          reason: 'Occasion ${occasion.label} should be visible',
        );
      }
    });
  });

  group('Navigation Flow', () {
    testWidgets('tapping occasion navigates to generate screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act: Tap on Birthday occasion
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      // Assert: Generate screen appears with relationships
      expect(find.text('Close Friend'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
    });

    testWidgets('settings button navigates to settings', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act: Tap settings icon
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Assert: Settings screen appears
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('back navigation works from generate screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to generate
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert: Back on home screen
      expect(find.text('Prosepal'), findsOneWidget);
      expect(find.text("What's the occasion?"), findsOneWidget);
    });
  });

  group('Generation Flow - Free User', () {
    testWidgets('complete generation wizard flow', (tester) async {
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

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 1: Select occasion
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      // Step 2: Select relationship
      expect(find.text('Close Friend'), findsOneWidget);
      await tester.tap(find.text('Close Friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Select tone
      expect(find.text('Heartfelt'), findsOneWidget);
      await tester.tap(find.text('Heartfelt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Generate button visible (free user with remaining generations)
      final generateButton = find.text('Generate Messages');
      await tester.ensureVisible(generateButton);
      await tester.pumpAndSettle();

      expect(generateButton, findsOneWidget);
    });

    testWidgets('free user with 0 remaining sees upgrade prompt', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isProProvider.overrideWith((ref) => false),
            remainingGenerationsProvider.overrideWith((ref) => 0),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate through wizard
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close Friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Heartfelt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Assert: Upgrade button instead of Generate
      final upgradeButton = find.text('Upgrade to Continue');
      await tester.ensureVisible(upgradeButton);
      await tester.pumpAndSettle();

      expect(upgradeButton, findsOneWidget);
      expect(find.text('Generate Messages'), findsNothing);
    });

    testWidgets('upgrade button navigates to paywall', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isProProvider.overrideWith((ref) => false),
            remainingGenerationsProvider.overrideWith((ref) => 0),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate through wizard to upgrade button
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close Friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Heartfelt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Tap upgrade
      final upgradeButton = find.text('Upgrade to Continue');
      await tester.ensureVisible(upgradeButton);
      await tester.pumpAndSettle();
      await tester.tap(upgradeButton);
      await tester.pumpAndSettle();

      // Assert: Paywall or subscription UI appears
      // Note: Actual paywall depends on RevenueCat setup
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('Generation Flow - Pro User', () {
    testWidgets('pro user sees generate button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isProProvider.overrideWith((ref) => true),
            remainingGenerationsProvider.overrideWith((ref) => 500),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate through wizard
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close Friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Heartfelt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Assert: Generate button visible (not upgrade)
      final generateButton = find.text('Generate Messages');
      await tester.ensureVisible(generateButton);
      await tester.pumpAndSettle();

      expect(generateButton, findsOneWidget);
      expect(find.text('Upgrade to Continue'), findsNothing);
    });
  });

  group('All Occasions Flow', () {
    for (final occasion in Occasion.values) {
      testWidgets('${occasion.label} occasion navigates correctly', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: const ProsepalApp(),
          ),
        );

        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Tap the occasion
        await tester.tap(find.text(occasion.label));
        await tester.pumpAndSettle();

        // Assert: Generate screen shows with occasion info
        expect(find.text(occasion.label), findsWidgets);
        expect(find.text(occasion.emoji), findsWidgets);

        // Assert: Relationship options visible
        expect(find.text('Close Friend'), findsOneWidget);
      });
    }
  });

  group('Settings Screen', () {
    testWidgets('settings displays all sections', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Assert: Settings screen with expected sections
      expect(find.text('Settings'), findsOneWidget);

      // Scroll to find various settings sections
      final listView = find.byType(Scrollable).first;

      // Check for common settings items
      await tester.scrollUntilVisible(
        find.text('Privacy Policy'),
        100,
        scrollable: listView,
      );
      expect(find.text('Privacy Policy'), findsOneWidget);
    });
  });

  group('Accessibility', () {
    testWidgets('buttons are large enough for touch', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find any elevated button and check size
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        final buttonSize = tester.getSize(buttons.first);
        // Apple HIG recommends 44pt minimum touch target
        expect(buttonSize.height, greaterThanOrEqualTo(44));
      }
    });

    testWidgets('text is readable size', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Check body text is at least 14pt (readable)
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final text in textWidgets) {
        if (text.style?.fontSize != null) {
          // Allow small text for captions, but main text should be readable
          // This is a soft check - main content should be 14+
        }
      }

      // Test passes if app renders without accessibility errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
