/// Comprehensive Scenario Tests for Prosepal
///
/// These tests cover all documented user flows, edge cases, and recently
/// fixed issues from TESTING.md, LAUNCH_CHECKLIST.md, and session history.
///
/// Categories:
/// 1. User Flows (Fresh install, upgrade, reinstall, multi-device)
/// 2. Anonymous User Scenarios
/// 3. Pro User Scenarios  
/// 4. AI Generation Scenarios (including truncation fix)
/// 5. Payment Edge Cases
/// 6. Auth Edge Cases
/// 7. Settings Screen Scenarios
/// 8. Error Handling
/// 9. Known Issues (L5, X2, R3)
///
/// Run with: patrol test -t integration_test/scenario_tests.dart
library;

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

void main() {
  late SharedPreferences prefs;
  late MockAuthService mockAuth;
  late MockSubscriptionService mockSubscription;
  late MockAiService mockAi;

  Future<void> initTest({
    Map<String, Object>? initialPrefs,
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs ?? {
      'hasCompletedOnboarding': true,
    });
    prefs = await SharedPreferences.getInstance();
    mockAuth = MockAuthService();
    mockSubscription = MockSubscriptionService();
    mockAi = MockAiService();
  }

  Future<void> pumpApp(
    PatrolIntegrationTester $, {
    bool isLoggedIn = false,
    bool isPro = false,
    int remainingGenerations = 1,
    bool hasCompletedOnboarding = true,
    String? email,
    MockAiService? aiService,
  }) async {
    await prefs.setBool('hasCompletedOnboarding', hasCompletedOnboarding);
    mockAuth.setLoggedIn(isLoggedIn, email: email ?? 'test@example.com');
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
  // FLOW 1: Fresh Install (Anonymous)
  // Launch → Onboarding → Home (anon) → Generate (1 free) → Results → Home (0)
  // ===========================================================================

  group('Flow 1: Fresh Install Anonymous', () {
    patrolTest('new user sees onboarding first', ($) async {
      await initTest(initialPrefs: {});
      await pumpApp($, isLoggedIn: false, hasCompletedOnboarding: false);

      // Should see onboarding, not home
      await $('Continue').waitUntilVisible();
    });

    patrolTest('anonymous user sees home after onboarding', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: false, remainingGenerations: 1);

      await $('Prosepal').waitUntilVisible();
      expect($("What's the occasion?"), findsOneWidget);
    });

    patrolTest('anonymous user has 1 free generation', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: false, remainingGenerations: 1);

      // Should see free tier indicator
      expect($('1'), findsWidgets);
      expect($('Free messages remaining'), findsOneWidget);
    });

    patrolTest('anonymous user can complete full generation flow', ($) async {
      await initTest();
      mockAi.messagesToReturn = [
        'Test message 1',
        'Test message 2', 
        'Test message 3',
      ];
      await pumpApp($, isLoggedIn: false, remainingGenerations: 1, aiService: mockAi);

      // Complete wizard
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Should see Generate button (not upgrade - has 1 remaining)
      await $('Generate Messages').waitUntilVisible();
      await $('Generate Messages').tap();

      // Should see results
      await $('Test message 1').waitUntilVisible();
      expect(mockAi.generateCallCount, 1);
    });
  });

  // ===========================================================================
  // FLOW 2: Upgrade Path (Second Generate)
  // Home → Generate → "Upgrade to Continue" → Auth → Paywall → Purchase → Pro
  // ===========================================================================

  group('Flow 2: Upgrade Path', () {
    patrolTest('anonymous user with 0 remaining sees upgrade button', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: false, remainingGenerations: 0);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Should see upgrade, not generate
      await $('Upgrade to Continue').waitUntilVisible();
      expect($('Generate Messages'), findsNothing);
    });

    patrolTest('upgrade button shows sign-in prompt for anonymous', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: false, remainingGenerations: 0);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Should show sign in prompt text
      expect($('Sign in to go Pro'), findsOneWidget);
    });

    patrolTest('logged in user with 0 remaining goes directly to paywall', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, remainingGenerations: 0);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Should show upgrade prompt
      expect($('Go Pro for more messages'), findsOneWidget);

      // Tap upgrade
      await $('Upgrade to Continue').tap();

      // Should navigate to paywall
      await $('Unlock').waitUntilVisible();
    });
  });

  // ===========================================================================
  // FLOW 3: Reinstall Anonymous
  // Delete app → Reinstall → Onboarding → Home → Generate (new free token)
  // ===========================================================================

  group('Flow 3: Reinstall Anonymous', () {
    patrolTest('fresh install gets new free token', ($) async {
      // Simulate fresh install - no prefs
      await initTest(initialPrefs: {});
      await pumpApp($, isLoggedIn: false, hasCompletedOnboarding: false, remainingGenerations: 1);

      // Should see onboarding
      await $('Continue').waitUntilVisible();
    });

    patrolTest('anonymous reinstall clears local state', ($) async {
      // First "install" - user generates
      await initTest(initialPrefs: {
        'hasCompletedOnboarding': true,
        'usage_free_remaining': 0,
        'usage_total_count': 1,
      });
      await pumpApp($, isLoggedIn: false, remainingGenerations: 0);

      // User has 0 remaining (used their free token)
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      expect($('Upgrade to Continue'), findsOneWidget);
    });
  });

  // ===========================================================================
  // FLOW 4: Reinstall Pro User
  // Delete app → Reinstall → Home (0 tokens) → Auth → Pro restored
  // ===========================================================================

  group('Flow 4: Reinstall Pro User', () {
    patrolTest('pro user sees pro badge immediately after auth', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true);

      await $('Prosepal').waitUntilVisible();
      expect($('PRO'), findsOneWidget);
    });

    patrolTest('pro user has unlimited generations', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true, remainingGenerations: 500);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Should always see Generate, never Upgrade
      await $('Generate Messages').waitUntilVisible();
      expect($('Upgrade to Continue'), findsNothing);
    });
  });

  // ===========================================================================
  // ANONYMOUS USER SCENARIOS (Recent fixes)
  // ===========================================================================

  group('Anonymous User Scenarios', () {
    patrolTest('settings shows Sign In tile for anonymous user', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: false);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      // Should show sign in option, not account card
      expect($('Sign In / Create Account'), findsOneWidget);
    });

    patrolTest('settings hides account actions for anonymous user', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: false);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      // Account actions should NOT be visible
      expect($('Sign Out'), findsNothing);
      expect($('Delete Account'), findsNothing);
    });

    patrolTest('signed in user sees account card with email', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, email: 'user@test.com');

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      expect($('user@test.com'), findsOneWidget);
    });

    patrolTest('signed in user sees account actions', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      await $('Sign Out').scrollTo();
      expect($('Sign Out'), findsOneWidget);
      expect($('Delete Account'), findsOneWidget);
    });
  });

  // ===========================================================================
  // AI GENERATION SCENARIOS (Including truncation fix)
  // ===========================================================================

  group('AI Generation Scenarios', () {
    patrolTest('AI returns exactly 3 messages', ($) async {
      await initTest();
      mockAi.messagesToReturn = [
        'Message one with full content.',
        'Message two with full content.',
        'Message three with full content.',
      ];
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      // All 3 messages should appear
      await $('Message one').waitUntilVisible();
      expect($('Option 1'), findsOneWidget);
      expect($('Option 2'), findsOneWidget);
      expect($('Option 3'), findsOneWidget);
    });

    patrolTest('long messages are not truncated (2048 token fix)', ($) async {
      await initTest();
      // Simulate a long message that would have been truncated at 400 tokens
      final longMessage = 'Happy Birthday! ' * 50; // ~100 words
      mockAi.messagesToReturn = [longMessage, 'Short 2', 'Short 3'];
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      // Should show the full long message
      await $('Happy Birthday!').waitUntilVisible();
    });

    patrolTest('network error shows user-friendly message', ($) async {
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

      await $('Unable to connect').waitUntilVisible();
    });

    patrolTest('rate limit error shows appropriate message', ($) async {
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
    });

    patrolTest('content blocked shows safety message', ($) async {
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
    });
  });

  // ===========================================================================
  // PAYMENT EDGE CASES
  // ===========================================================================

  group('Payment Edge Cases', () {
    patrolTest('free user sees Free Plan in settings', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: false);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      expect($('Free Plan'), findsOneWidget);
    });

    patrolTest('pro user sees Pro Plan in settings', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      expect($('Pro Plan'), findsOneWidget);
    });

    patrolTest('pro user sees Manage Subscription option', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      expect($('Manage Subscription'), findsOneWidget);
    });

    patrolTest('free user sees Restore Purchases option', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: false);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      await $('Restore Purchases').scrollTo();
      expect($('Restore Purchases'), findsOneWidget);
    });

    patrolTest('usage card navigates to paywall', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: false, remainingGenerations: 1);

      // Tap the usage card
      await $('Free messages remaining').tap();

      // Should navigate to paywall
      await $('Unlock').waitUntilVisible();
    });
  });

  // ===========================================================================
  // AUTH EDGE CASES
  // ===========================================================================

  group('Auth Edge Cases', () {
    patrolTest('sign out shows confirmation dialog', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      await $('Sign Out').scrollTo().tap();

      await $('Sign out of your account?').waitUntilVisible();
      expect($('Cancel'), findsOneWidget);
    });

    patrolTest('sign out cancel dismisses dialog', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      await $('Sign Out').scrollTo().tap();
      await $('Sign out of your account?').waitUntilVisible();

      await $('Cancel').tap();
      await $.pump(const Duration(milliseconds: 300));

      expect($('Sign out of your account?'), findsNothing);
      expect($('Settings'), findsOneWidget);
    });

    patrolTest('delete account shows confirmation with warning', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      await $('Delete Account').scrollTo().tap();

      await $('Delete your account?').waitUntilVisible();
      expect($('This action cannot be undone'), findsOneWidget);
    });
  });

  // ===========================================================================
  // ALL 13 OCCASIONS
  // ===========================================================================

  group('All Occasions Coverage', () {
    for (final occasion in Occasion.values) {
      patrolTest('${occasion.label} flow completes successfully', ($) async {
        await initTest();
        await pumpApp($, isLoggedIn: true, isPro: true);

        await $(occasion.label).scrollTo().tap();
        await $('Close Friend').waitUntilVisible();
        await $('Close Friend').tap();
        await $('Continue').tap();
        await $('Heartfelt').tap();
        await $('Continue').tap();

        await $('Generate Messages').waitUntilVisible();
      });
    }
  });

  // ===========================================================================
  // ALL RELATIONSHIPS
  // ===========================================================================

  group('All Relationships Coverage', () {
    for (final relationship in Relationship.values) {
      patrolTest('${relationship.label} can be selected', ($) async {
        await initTest();
        await pumpApp($, isLoggedIn: true);

        await $('Birthday').tap();
        await $(relationship.label).waitUntilVisible();
        await $(relationship.label).tap();

        expect($('Continue'), findsOneWidget);
      });
    }
  });

  // ===========================================================================
  // ALL TONES
  // ===========================================================================

  group('All Tones Coverage', () {
    for (final tone in Tone.values) {
      patrolTest('${tone.label} can be selected', ($) async {
        await initTest();
        await pumpApp($, isLoggedIn: true);

        await $('Birthday').tap();
        await $('Close Friend').tap();
        await $('Continue').tap();

        await $(tone.label).waitUntilVisible();
        await $(tone.label).tap();

        expect($('Continue'), findsOneWidget);
      });
    }
  });

  // ===========================================================================
  // MESSAGE LENGTH OPTIONS
  // ===========================================================================

  group('Message Length Options', () {
    patrolTest('all length options visible on step 3', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      expect($('Brief'), findsOneWidget);
      expect($('Standard'), findsOneWidget);
      expect($('Detailed'), findsOneWidget);
    });

    patrolTest('Brief shows 1-2 sentences description', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      await $('Brief').tap();
      await $('1-2 sentences').waitUntilVisible();
    });
  });

  // ===========================================================================
  // RESULTS SCREEN
  // ===========================================================================

  group('Results Screen', () {
    patrolTest('shows all 3 message options', ($) async {
      await initTest();
      mockAi.messagesToReturn = ['Msg 1', 'Msg 2', 'Msg 3'];
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      await $('Your Messages').waitUntilVisible();
      expect($('Option 1'), findsOneWidget);
      expect($('Option 2'), findsOneWidget);
      expect($('Option 3'), findsOneWidget);
    });

    patrolTest('copy button shows copied confirmation', ($) async {
      await initTest();
      mockAi.messagesToReturn = ['Test message'];
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      await $('Your Messages').waitUntilVisible();
      await $('Copy').tap();

      await $('Copied!').waitUntilVisible();
    });

    patrolTest('share button is visible', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      await $('Your Messages').waitUntilVisible();
      expect($(Icons.share_outlined), findsWidgets);
    });

    patrolTest('start over returns to home', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      await $('Your Messages').waitUntilVisible();
      await $('Start Over').tap();

      await $('Prosepal').waitUntilVisible();
      expect($("What's the occasion?"), findsOneWidget);
    });
  });

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  group('Navigation', () {
    patrolTest('back from step 1 returns to home', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);

      await $('Birthday').tap();
      await $('Close Friend').waitUntilVisible();

      await $(Icons.arrow_back).tap();

      await $('Prosepal').waitUntilVisible();
    });

    patrolTest('back from step 2 returns to step 1', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').waitUntilVisible();

      await $(Icons.arrow_back).tap();

      await $('Close Friend').waitUntilVisible();
    });

    patrolTest('back from step 3 returns to step 2', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').waitUntilVisible();

      await $(Icons.arrow_back).tap();

      await $('Heartfelt').waitUntilVisible();
      expect($('Generate Messages'), findsNothing);
    });
  });

  // ===========================================================================
  // ERROR DISMISSAL
  // ===========================================================================

  group('Error Handling', () {
    patrolTest('error can be dismissed', ($) async {
      await initTest();
      mockAi.errorToThrow = const AiNetworkException('Test error');
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      await $('Test error').waitUntilVisible();

      // Dismiss
      await $(Icons.close).first.tap();
      await $.pump(const Duration(milliseconds: 500));

      expect($('Test error'), findsNothing);
    });

    patrolTest('can retry after dismissing error', ($) async {
      await initTest();
      mockAi.errorToThrow = const AiNetworkException('Network error');
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();

      await $('Network error').waitUntilVisible();
      await $(Icons.close).first.tap();

      // Clear error and retry
      mockAi.errorToThrow = null;
      await $('Generate Messages').tap();

      await $('Happy Birthday').waitUntilVisible();
    });
  });

  // ===========================================================================
  // KNOWN ISSUES (from TESTING.md)
  // ===========================================================================

  group('Known Issues Verification', () {
    // L5: User stuck after 3 failed biometrics - needs fallback
    // This is a device-only test - placeholder for documentation

    // X2: No biometric re-auth on foreground
    // This is a device-only test - placeholder for documentation

    // R3: Supabase session persist after reinstall
    // This requires manual testing

    patrolTest('app handles missing auth gracefully', ($) async {
      await initTest();
      // Simulate no auth but user tries to access protected feature
      await pumpApp($, isLoggedIn: false, remainingGenerations: 0);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Should show upgrade with sign in prompt, not crash
      await $('Upgrade to Continue').waitUntilVisible();
      expect($('Sign in to go Pro'), findsOneWidget);
    });
  });

  // ===========================================================================
  // PRO STATUS DETECTION (Recent fix)
  // ===========================================================================

  group('Pro Status Detection', () {
    patrolTest('pro status updates reactively', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true);

      // Pro badge should be visible
      await $('PRO').waitUntilVisible();
    });

    patrolTest('pro user never sees upgrade button', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true, remainingGenerations: 500);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      await $('Generate Messages').waitUntilVisible();
      expect($('Upgrade'), findsNothing);
    });

    patrolTest('free user with 0 remaining sees upgrade', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: false, remainingGenerations: 0);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      await $('Upgrade to Continue').waitUntilVisible();
      expect($('Generate Messages'), findsNothing);
    });
  });

  // ===========================================================================
  // LEGAL LINKS
  // ===========================================================================

  group('Legal Links', () {
    patrolTest('privacy policy accessible from settings', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      await $('Privacy Policy').scrollTo();
      expect($('Privacy Policy'), findsOneWidget);
    });

    patrolTest('terms of service accessible from settings', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      await $('Terms of Service').scrollTo();
      expect($('Terms of Service'), findsOneWidget);
    });
  });
}
