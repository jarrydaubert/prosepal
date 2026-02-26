/// Scenario Tests - Mocked Integration Tests (Patrol)
/// 
/// Covers flows requiring mocked state (auth, subscription, AI errors).
/// For real device tests, see golden_path_test.dart (Firebase Test Lab).
/// 
/// Run: patrol test -t integration_test/scenario_tests.dart
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

  Future<void> initTest({Map<String, Object>? initialPrefs}) async {
    SharedPreferences.setMockInitialValues(initialPrefs ?? {'hasCompletedOnboarding': true});
    prefs = await SharedPreferences.getInstance();
    mockAuth = MockAuthService();
    mockSubscription = MockSubscriptionService();
    mockAi = MockAiService();
  }

  Future<void> pumpApp(PatrolIntegrationTester $, {
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

  // ===== ANONYMOUS USER SCENARIOS =====
  group('Anonymous User', () {
    patrolTest('sees onboarding on fresh install', ($) async {
      await initTest(initialPrefs: {});
      await pumpApp($, hasCompletedOnboarding: false);
      await $('Continue').waitUntilVisible();
    });

    patrolTest('has 1 free generation', ($) async {
      await initTest();
      await pumpApp($, remainingGenerations: 1);
      expect($('Free messages remaining'), findsOneWidget);
    });

    patrolTest('with 0 remaining sees upgrade button', ($) async {
      await initTest();
      await pumpApp($, remainingGenerations: 0);
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Upgrade to Continue').waitUntilVisible();
    });

    patrolTest('settings shows Sign In tile', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: false);
      await $(Icons.settings_outlined).tap();
      expect($('Sign In / Create Account'), findsOneWidget);
      expect($('Sign Out'), findsNothing);
    });
  });

  // ===== PRO USER SCENARIOS =====
  group('Pro User', () {
    patrolTest('sees PRO badge', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true);
      expect($('PRO'), findsOneWidget);
    });

    patrolTest('never sees upgrade button', ($) async {
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

    patrolTest('sees Pro Plan in settings', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true);
      await $(Icons.settings_outlined).tap();
      expect($('Pro Plan'), findsOneWidget);
      expect($('Manage Subscription'), findsOneWidget);
    });
  });

  // ===== AI ERROR SCENARIOS (Mocked) =====
  group('AI Errors', () {
    patrolTest('network error shows message', ($) async {
      await initTest();
      mockAi.errorToThrow = const AiNetworkException('Unable to connect');
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();
      await $('Unable to connect').waitUntilVisible();
    });

    patrolTest('rate limit error shows message', ($) async {
      await initTest();
      mockAi.errorToThrow = const AiRateLimitException('Too many requests');
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();
      await $('Too many requests').waitUntilVisible();
    });

    patrolTest('content blocked shows message', ($) async {
      await initTest();
      mockAi.errorToThrow = const AiContentBlockedException('blocked');
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();
      await $('blocked').waitUntilVisible();
    });

    patrolTest('error can be dismissed and retried', ($) async {
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
      mockAi.errorToThrow = null;
      await $('Generate Messages').tap();
      await $('Happy Birthday').waitUntilVisible();
    });
  });

  // ===== AUTH DIALOGS (Mocked) =====
  group('Auth Dialogs', () {
    patrolTest('sign out shows confirmation', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);
      await $(Icons.settings_outlined).tap();
      await $('Sign Out').scrollTo().tap();
      await $('Sign out of your account?').waitUntilVisible();
    });

    patrolTest('sign out cancel dismisses', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);
      await $(Icons.settings_outlined).tap();
      await $('Sign Out').scrollTo().tap();
      await $('Cancel').tap();
      expect($('Sign out of your account?'), findsNothing);
    });

    patrolTest('delete account shows warning', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);
      await $(Icons.settings_outlined).tap();
      await $('Delete Account').scrollTo().tap();
      await $('Delete your account?').waitUntilVisible();
      expect($('This action cannot be undone'), findsOneWidget);
    });
  });

  // ===== RESULTS SCREEN (Mocked AI) =====
  group('Results Screen', () {
    patrolTest('shows 3 message options', ($) async {
      await initTest();
      mockAi.messagesToReturn = ['Msg 1', 'Msg 2', 'Msg 3'];
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();
      expect($('Option 1'), findsOneWidget);
      expect($('Option 2'), findsOneWidget);
      expect($('Option 3'), findsOneWidget);
    });

    patrolTest('copy shows confirmation', ($) async {
      await initTest();
      mockAi.messagesToReturn = ['Test'];
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();
      await $('Copy').tap();
      await $('Copied!').waitUntilVisible();
    });

    patrolTest('start over returns home', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: true, aiService: mockAi);
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Generate Messages').tap();
      await $('Start Over').tap();
      expect($("What's the occasion?"), findsOneWidget);
    });
  });

  // ===== ALL OCCASIONS (41) =====
  group('All Occasions', () {
    for (final occasion in Occasion.values) {
      patrolTest(occasion.label, ($) async {
        await initTest();
        await pumpApp($, isLoggedIn: true, isPro: true);
        await $(occasion.label).scrollTo().tap();
        await $('Close Friend').waitUntilVisible();
      });
    }
  });

  // ===== ALL RELATIONSHIPS (14) =====
  group('All Relationships', () {
    for (final rel in Relationship.values) {
      patrolTest(rel.label, ($) async {
        await initTest();
        await pumpApp($, isLoggedIn: true);
        await $('Birthday').tap();
        await $(rel.label).scrollTo().tap();
        expect($('Continue'), findsOneWidget);
      });
    }
  });

  // ===== ALL TONES (6) =====
  group('All Tones', () {
    for (final tone in Tone.values) {
      patrolTest(tone.label, ($) async {
        await initTest();
        await pumpApp($, isLoggedIn: true);
        await $('Birthday').tap();
        await $('Close Friend').tap();
        await $('Continue').tap();
        await $(tone.label).scrollTo().tap();
        expect($('Continue'), findsOneWidget);
      });
    }
  });

  // ===== NAVIGATION =====
  group('Navigation', () {
    patrolTest('back from step 1 → home', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);
      await $('Birthday').tap();
      await $(Icons.arrow_back).tap();
      await $('Prosepal').waitUntilVisible();
    });

    patrolTest('back from step 2 → step 1', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $(Icons.arrow_back).tap();
      await $('Close Friend').waitUntilVisible();
    });

    patrolTest('back from step 3 → step 2', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $(Icons.arrow_back).tap();
      await $('Heartfelt').waitUntilVisible();
    });
  });

  // ===== SETTINGS =====
  group('Settings', () {
    patrolTest('free user sees Free Plan', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: false);
      await $(Icons.settings_outlined).tap();
      expect($('Free Plan'), findsOneWidget);
    });

    patrolTest('restore purchases visible', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: false);
      await $(Icons.settings_outlined).tap();
      await $('Restore Purchases').scrollTo();
      expect($('Restore Purchases'), findsOneWidget);
    });

    patrolTest('legal links accessible', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true);
      await $(Icons.settings_outlined).tap();
      await $('Privacy Policy').scrollTo();
      expect($('Privacy Policy'), findsOneWidget);
      expect($('Terms of Service'), findsOneWidget);
    });

    patrolTest('usage card → paywall', ($) async {
      await initTest();
      await pumpApp($, isLoggedIn: true, isPro: false, remainingGenerations: 1);
      await $('Free messages remaining').tap();
      await $('Unlock').waitUntilVisible();
    });
  });
}
