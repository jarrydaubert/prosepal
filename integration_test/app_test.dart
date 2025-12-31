import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/models/models.dart';

import '../test/mocks/mock_auth_service.dart';
import '../test/mocks/mock_subscription_service.dart';

/// Patrol Integration Tests for Prosepal
///
/// Modern, robust integration tests using Patrol framework.
/// - Automatic waiting (no hardcoded delays)
/// - Deterministic mocked state
/// - No conditional assertions
///
/// Run with: patrol test -t integration_test/app_test.dart
void main() {
  late SharedPreferences prefs;
  late MockAuthService mockAuth;
  late MockSubscriptionService mockSubscription;

  Future<void> initTest() async {
    SharedPreferences.setMockInitialValues({
      'hasCompletedOnboarding': true,
    });
    prefs = await SharedPreferences.getInstance();
    mockAuth = MockAuthService();
    mockSubscription = MockSubscriptionService();
  }

  /// Pumps app with mocked services for deterministic testing
  Future<void> pumpApp(
    PatrolIntegrationTester $, {
    bool isLoggedIn = true,
    bool isPro = false,
    int remainingGenerations = 3,
    bool hasCompletedOnboarding = true,
  }) async {
    await prefs.setBool('hasCompletedOnboarding', hasCompletedOnboarding);
    mockAuth.setLoggedIn(isLoggedIn, email: 'test@example.com');
    mockSubscription.setProStatus(isPro);

    await $.pumpWidgetAndSettle(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
          subscriptionServiceProvider.overrideWithValue(mockSubscription),
          isProProvider.overrideWith((ref) => isPro),
          remainingGenerationsProvider.overrideWith((ref) => remainingGenerations),
        ],
        child: const ProsepalApp(),
      ),
    );
  }

  // ===========================================================================
  // App Launch Tests
  // ===========================================================================

  patrolTest(
    'logged in user sees home screen with all occasions',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);

      // Verify home screen elements
      expect($('Prosepal'), findsOneWidget);
      expect($("What's the occasion?"), findsOneWidget);

      // Verify all 10 occasions are displayed
      for (final occasion in Occasion.values) {
        expect($(occasion.label), findsOneWidget);
      }
    },
  );

  patrolTest(
    'logged out user sees auth screen with all sign-in options',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: false);

      // Verify auth screen options
      await $('Continue with Email').waitUntilVisible();
      expect($('Continue with Apple'), findsOneWidget);
      expect($('Continue with Google'), findsOneWidget);
    },
  );

  patrolTest(
    'new user sees onboarding flow',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: false, hasCompletedOnboarding: false);

      // First page - Continue button visible
      await $('Continue').waitUntilVisible();
    },
  );

  // ===========================================================================
  // Generation Wizard Tests
  // ===========================================================================

  patrolTest(
    'complete wizard flow reaches generate button',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, remainingGenerations: 3);

      // Step 1: Select occasion
      await $('Birthday').tap();

      // Step 2: Select relationship
      await $('Close Friend').waitUntilVisible();
      await $('Close Friend').tap();
      await $('Continue').tap();

      // Step 3: Select tone
      await $('Heartfelt').waitUntilVisible();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Step 4: Generate screen - verify generate button exists
      await $('Generate Messages').waitUntilVisible();
      expect($('Generate Messages'), findsOneWidget);
    },
  );

  patrolTest(
    'back navigation returns to home from wizard',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);

      await $('Birthday').tap();
      await $('Close Friend').waitUntilVisible();

      // Go back
      await $(Icons.arrow_back).tap();

      // Verify home screen
      await $('Prosepal').waitUntilVisible();
      expect($("What's the occasion?"), findsOneWidget);
    },
  );

  // ===========================================================================
  // Free vs Pro User Tests
  // ===========================================================================

  patrolTest(
    'free user with remaining generations sees generate button',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: false, remainingGenerations: 3);

      // Navigate through wizard
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Verify generate button (not upgrade)
      await $('Generate Messages').waitUntilVisible();
      expect($('Generate Messages'), findsOneWidget);
      expect($('Upgrade to Continue'), findsNothing);
    },
  );

  patrolTest(
    'free user with 0 remaining sees upgrade button',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: false, remainingGenerations: 0);

      // Navigate through wizard
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Verify upgrade button (not generate)
      await $('Upgrade to Continue').waitUntilVisible();
      expect($('Upgrade to Continue'), findsOneWidget);
      expect($('Generate Messages'), findsNothing);
    },
  );

  patrolTest(
    'pro user always sees generate button',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true, remainingGenerations: 500);

      // Navigate through wizard
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Verify generate button
      await $('Generate Messages').waitUntilVisible();
      expect($('Upgrade to Continue'), findsNothing);
    },
  );

  // ===========================================================================
  // Settings Tests
  // ===========================================================================

  patrolTest(
    'navigates to settings and shows subscription info',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: false);

      // Navigate to settings
      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      // Verify subscription section
      expect($('Free Plan'), findsOneWidget);
      expect($('Restore Purchases'), findsOneWidget);
    },
  );

  patrolTest(
    'settings shows legal links',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      // Scroll to and verify legal section
      await $('Privacy Policy').scrollTo();
      expect($('Privacy Policy'), findsOneWidget);
      expect($('Terms of Service'), findsOneWidget);
    },
  );

  // ===========================================================================
  // All Occasions Coverage
  // ===========================================================================

  for (final occasion in Occasion.values) {
    patrolTest(
      '${occasion.label} wizard flow completes successfully',
      ($) async {
        await initTest();
        await pumpApp($, isLoggedIn: true, isPro: true);

        await $(occasion.label).tap();
        await $('Close Friend').waitUntilVisible();
        await $('Close Friend').tap();
        await $('Continue').tap();
        await $('Heartfelt').tap();
        await $('Continue').tap();

        await $('Generate Messages').waitUntilVisible();
      },
    );
  }

  // ===========================================================================
  // All Relationships Coverage
  // ===========================================================================

  final relationships = ['Close Friend', 'Family', 'Colleague', 'Partner', 'Acquaintance'];
  for (final relationship in relationships) {
    patrolTest(
      '$relationship can be selected in wizard',
      ($) async {
        await initTest();
        await pumpApp($, isLoggedIn: true);

        await $('Birthday').tap();
        await $(relationship).waitUntilVisible();
        await $(relationship).tap();

        expect($('Continue'), findsOneWidget);
      },
    );
  }

  // ===========================================================================
  // All Tones Coverage
  // ===========================================================================

  final tones = ['Heartfelt', 'Funny', 'Formal', 'Casual'];
  for (final tone in tones) {
    patrolTest(
      '$tone can be selected in wizard',
      ($) async {
        await initTest();
        await pumpApp($, isLoggedIn: true);

        await $('Birthday').tap();
        await $('Close Friend').tap();
        await $('Continue').tap();

        await $(tone).waitUntilVisible();
        await $(tone).tap();

        expect($('Continue'), findsOneWidget);
      },
    );
  }
}
