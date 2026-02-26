import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/services/ai_service.dart';

import '../test/mocks/mock_ai_service.dart';
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
  late MockAiService mockAi;

  Future<void> initTest() async {
    SharedPreferences.setMockInitialValues({
      'hasCompletedOnboarding': true,
    });
    prefs = await SharedPreferences.getInstance();
    mockAuth = MockAuthService();
    mockSubscription = MockSubscriptionService();
    mockAi = MockAiService();
  }

  /// Pumps app with mocked services for deterministic testing
  Future<void> pumpApp(
    PatrolIntegrationTester $, {
    bool isLoggedIn = true,
    bool isPro = false,
    int remainingGenerations = 3,
    bool hasCompletedOnboarding = true,
    MockAiService? aiService,
  }) async {
    await prefs.setBool('hasCompletedOnboarding', hasCompletedOnboarding);
    mockAuth.setLoggedIn(isLoggedIn, email: 'test@example.com');
    mockSubscription.setIsPro(isPro);

    await $.pumpWidgetAndSettle(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuth),
          subscriptionServiceProvider.overrideWithValue(mockSubscription),
          aiServiceProvider.overrideWithValue(aiService ?? mockAi),
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

  // ===========================================================================
  // Generation Outcome Tests (with MockAiService)
  // ===========================================================================

  patrolTest(
    'generation flow shows results screen with messages',
    ($) async {
      await initTest();
      mockAi.messagesToReturn = [
        'Birthday message 1 - Have a wonderful day!',
        'Birthday message 2 - Wishing you the best!',
        'Birthday message 3 - Celebrate in style!',
      ];
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      // Navigate wizard
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Tap Generate
      await $('Generate Messages').tap();

      // Verify results screen with generated messages
      await $('Birthday message 1').waitUntilVisible();
      expect($('Birthday message 1'), findsOneWidget);
      expect($('Birthday message 2'), findsOneWidget);
      expect($('Birthday message 3'), findsOneWidget);

      // Verify AI service was called correctly
      expect(mockAi.generateCallCount, 1);
      expect(mockAi.lastOccasion, Occasion.birthday);
      expect(mockAi.lastRelationship, Relationship.closeFriend);
      expect(mockAi.lastTone, Tone.heartfelt);
    },
  );

  patrolTest(
    'copy button appears on generated messages',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      // Wait for results then check for copy icons
      await $(Icons.copy).waitUntilVisible();
      expect($(Icons.copy), findsWidgets);
    },
  );

  // ===========================================================================
  // Error Handling Tests
  // ===========================================================================

  patrolTest(
    'network error shows user-friendly message',
    ($) async {
      await initTest();
      mockAi.errorToThrow = const AiNetworkException(
        'Unable to connect. Please check your internet connection.',
      );
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      // Verify error message displayed
      await $('Unable to connect').waitUntilVisible();
      expect($('internet connection'), findsOneWidget);
    },
  );

  patrolTest(
    'rate limit error shows appropriate message',
    ($) async {
      await initTest();
      mockAi.errorToThrow = const AiRateLimitException(
        'Too many requests. Please wait a moment.',
      );
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      await $('Too many requests').waitUntilVisible();
    },
  );

  patrolTest(
    'content blocked error shows safety message',
    ($) async {
      await initTest();
      mockAi.errorToThrow = const AiContentBlockedException(
        'Content was blocked by safety filters.',
      );
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      await $('blocked').waitUntilVisible();
    },
  );

  patrolTest(
    'error can be dismissed and user can retry',
    ($) async {
      await initTest();
      mockAi.errorToThrow = const AiNetworkException('Network error');
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      // Error shown
      await $('Network error').waitUntilVisible();

      // Dismiss error (look for dismiss button or OK)
      if ($('OK').exists) {
        await $('OK').tap();
      } else if ($('Dismiss').exists) {
        await $('Dismiss').tap();
      }

      // Clear error and retry
      mockAi.errorToThrow = null;
      await $('Generate Messages').tap();

      // Should now show results
      await $('Happy Birthday').waitUntilVisible();
    },
  );

  // ===========================================================================
  // Pro User Specific Tests
  // ===========================================================================

  patrolTest(
    'pro user sees Pro Plan in settings',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      expect($('Pro Plan'), findsOneWidget);
      expect($('Free Plan'), findsNothing);
    },
  );

  patrolTest(
    'pro user can generate unlimited messages',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true, remainingGenerations: 500);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Should see generate, never upgrade
      await $('Generate Messages').waitUntilVisible();
      expect($('Upgrade'), findsNothing);
      expect($('remaining'), findsNothing);
    },
  );

  // ===========================================================================
  // Upgrade Flow Tests
  // ===========================================================================

  patrolTest(
    'upgrade button navigates to paywall',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: false, remainingGenerations: 0);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      await $('Upgrade to Continue').tap();

      // Should navigate to paywall screen
      await $('Unlock').waitUntilVisible();
    },
  );

  patrolTest(
    'free user sees remaining generations count',
    ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: false, remainingGenerations: 2);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Should show remaining count somewhere on generate screen
      await $('Generate Messages').waitUntilVisible();
      expect($('2'), findsWidgets); // Free tier shows count
    },
  );
}
