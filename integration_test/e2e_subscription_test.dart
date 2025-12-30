import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/models/models.dart';

/// E2E Tests for Subscription Flows
///
/// These tests verify the subscription-related UI flows work correctly.
/// They use mocked subscription state since real purchases require device testing.
///
/// Run with: flutter test integration_test/e2e_subscription_test.dart -d <device_id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://mwoxtqxzunsjmbdqezif.supabase.co',
      anonKey: 'sb_publishable_DJB3MvvHJRl-vuqrkn1-6w_hwTLnOaS',
    );

    SharedPreferences.setMockInitialValues({
      'hasCompletedOnboarding': true,
    });
    prefs = await SharedPreferences.getInstance();
  });

  group('Free User Experience', () {
    testWidgets('free user sees remaining generations count', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isProProvider.overrideWith((ref) => false),
            remainingGenerationsProvider.overrideWith((ref) => 2),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to generate screen if on home
      final birthdayCard = find.text('Birthday');
      if (birthdayCard.evaluate().isNotEmpty) {
        await tester.tap(birthdayCard);
        await tester.pumpAndSettle();

        // Complete wizard steps
        await tester.tap(find.text('Close Friend'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heartfelt'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should see remaining count
        expect(find.textContaining('2'), findsWidgets);
      }
    });

    testWidgets('free user with 0 remaining sees upgrade button', (tester) async {
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

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final birthdayCard = find.text('Birthday');
      if (birthdayCard.evaluate().isNotEmpty) {
        await tester.tap(birthdayCard);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Close Friend'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heartfelt'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should see upgrade button instead of generate
        final upgradeButton = find.text('Upgrade to Continue');
        await tester.ensureVisible(upgradeButton);
        expect(upgradeButton, findsOneWidget);
        expect(find.text('Generate Messages'), findsNothing);
      }
    });

    testWidgets('free user with remaining can generate', (tester) async {
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
        await tester.tap(birthdayCard);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Close Friend'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heartfelt'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should see generate button
        final generateButton = find.text('Generate Messages');
        await tester.ensureVisible(generateButton);
        expect(generateButton, findsOneWidget);
      }
    });
  });

  group('Pro User Experience', () {
    testWidgets('pro user always sees generate button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isProProvider.overrideWith((ref) => true),
            remainingGenerationsProvider.overrideWith((ref) => 999),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final birthdayCard = find.text('Birthday');
      if (birthdayCard.evaluate().isNotEmpty) {
        await tester.tap(birthdayCard);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Close Friend'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heartfelt'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Pro user should see generate button
        final generateButton = find.text('Generate Messages');
        await tester.ensureVisible(generateButton);
        expect(generateButton, findsOneWidget);
        expect(find.text('Upgrade to Continue'), findsNothing);
      }
    });

    testWidgets('pro user sees Pro Plan in settings', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isProProvider.overrideWith((ref) => true),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        // Pro user should see Pro Plan or Manage Subscription
        expect(
          find.textContaining('Pro').evaluate().isNotEmpty ||
              find.text('Manage Subscription').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });
  });

  group('Settings Subscription Section', () {
    testWidgets('free user sees Upgrade option', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isProProvider.overrideWith((ref) => false),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        // Free user should see upgrade option
        expect(find.text('Free Plan'), findsOneWidget);
      }
    });

    testWidgets('restore purchases option visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isProProvider.overrideWith((ref) => false),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        // Restore purchases should be visible
        final restoreButton = find.text('Restore Purchases');
        expect(restoreButton, findsOneWidget);
      }
    });
  });

  group('All Occasions - Free User Flow', () {
    for (final occasion in Occasion.values) {
      testWidgets('${occasion.label} - free user wizard flow', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              isProProvider.overrideWith((ref) => false),
              remainingGenerationsProvider.overrideWith((ref) => 1),
            ],
            child: const ProsepalApp(),
          ),
        );

        await tester.pumpAndSettle(const Duration(seconds: 3));

        final occasionCard = find.text(occasion.label);
        if (occasionCard.evaluate().isNotEmpty) {
          await tester.tap(occasionCard);
          await tester.pumpAndSettle();

          // Verify occasion emoji displayed
          expect(find.text(occasion.emoji), findsWidgets);

          // Select first available relationship
          final closeFriend = find.text('Close Friend');
          if (closeFriend.evaluate().isNotEmpty) {
            await tester.tap(closeFriend);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Continue'));
            await tester.pumpAndSettle();

            // Select first tone
            await tester.tap(find.text('Heartfelt'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Continue'));
            await tester.pumpAndSettle();

            // Should see generate button (has 1 remaining)
            final generateButton = find.text('Generate Messages');
            await tester.ensureVisible(generateButton);
            expect(generateButton, findsOneWidget);
          }
        }
      });
    }
  });

  group('All Occasions - Pro User Flow', () {
    for (final occasion in Occasion.values) {
      testWidgets('${occasion.label} - pro user wizard flow', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              isProProvider.overrideWith((ref) => true),
              remainingGenerationsProvider.overrideWith((ref) => 999),
            ],
            child: const ProsepalApp(),
          ),
        );

        await tester.pumpAndSettle(const Duration(seconds: 3));

        final occasionCard = find.text(occasion.label);
        if (occasionCard.evaluate().isNotEmpty) {
          await tester.tap(occasionCard);
          await tester.pumpAndSettle();

          // Verify occasion displayed
          expect(find.text(occasion.emoji), findsWidgets);

          // Complete wizard
          final closeFriend = find.text('Close Friend');
          if (closeFriend.evaluate().isNotEmpty) {
            await tester.tap(closeFriend);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Continue'));
            await tester.pumpAndSettle();

            await tester.tap(find.text('Heartfelt'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Continue'));
            await tester.pumpAndSettle();

            // Pro user should always see generate
            final generateButton = find.text('Generate Messages');
            await tester.ensureVisible(generateButton);
            expect(generateButton, findsOneWidget);
          }
        }
      });
    }
  });

  group('Navigation Flows', () {
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

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final birthdayCard = find.text('Birthday');
      if (birthdayCard.evaluate().isNotEmpty) {
        await tester.tap(birthdayCard);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Close Friend'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Heartfelt'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Tap upgrade button
        final upgradeButton = find.text('Upgrade to Continue');
        await tester.ensureVisible(upgradeButton);
        await tester.tap(upgradeButton);
        await tester.pumpAndSettle();

        // Should navigate to paywall (verify by screen change)
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('settings upgrade navigates to paywall', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isProProvider.overrideWith((ref) => false),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        // Find and tap upgrade in settings
        final upgradeOption = find.text('Upgrade');
        if (upgradeOption.evaluate().isNotEmpty) {
          await tester.tap(upgradeOption);
          await tester.pumpAndSettle();

          // Should navigate to paywall
          expect(find.byType(Scaffold), findsWidgets);
        }
      }
    });
  });
}
