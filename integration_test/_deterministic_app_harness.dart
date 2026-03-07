library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/services/device_fingerprint_service.dart';
import 'package:prosepal/core/services/usage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/mocks/mock_ai_service.dart';
import '../test/mocks/mock_auth_service.dart';
import '../test/mocks/mock_device_fingerprint_service.dart';
import '../test/mocks/mock_rate_limit_service.dart';
import '../test/mocks/mock_subscription_service.dart';

class DeterministicAppHarness {
  DeterministicAppHarness._({
    required this.prefs,
    required this.auth,
    required this.subscription,
    required this.ai,
    required this.deviceFingerprint,
    required this.rateLimit,
    required this.initStatusNotifier,
  });

  final SharedPreferences prefs;
  final MockAuthService auth;
  final MockSubscriptionService subscription;
  final MockAiService ai;
  final MockDeviceFingerprintService deviceFingerprint;
  final MockRateLimitService rateLimit;
  final InitStatusNotifier initStatusNotifier;

  static Future<DeterministicAppHarness> create({
    bool isPro = false,
    bool loggedIn = false,
    bool onboardingCompleted = true,
    bool freeTierUsed = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'hasCompletedOnboarding': onboardingCompleted,
      'analytics_enabled': false,
      'hasSeenFirstActionHint': false,
      'total_generation_count': freeTierUsed ? 1 : 0,
      'device_used_free_tier': freeTierUsed,
    });

    final prefs = await SharedPreferences.getInstance();
    final auth = MockAuthService();
    if (loggedIn) {
      auth.setLoggedIn(true, email: 'test@example.com');
    }

    final subscription = MockSubscriptionService()..setIsPro(isPro);
    final ai = MockAiService();
    final deviceFingerprint = MockDeviceFingerprintService(
      allowFreeTier: !freeTierUsed,
      deviceCheckReason: freeTierUsed
          ? DeviceCheckReason.alreadyUsed
          : DeviceCheckReason.newDevice,
    );
    final rateLimit = MockRateLimitService(
      deviceFingerprint: deviceFingerprint,
    );
    final initStatusNotifier = InitStatusNotifier()
      ..markSupabaseReady()
      ..markRevenueCatReady()
      ..markRemoteConfigReady();

    return DeterministicAppHarness._(
      prefs: prefs,
      auth: auth,
      subscription: subscription,
      ai: ai,
      deviceFingerprint: deviceFingerprint,
      rateLimit: rateLimit,
      initStatusNotifier: initStatusNotifier,
    );
  }

  Widget buildApp({bool isPro = false}) {
    subscription.setIsPro(isPro);
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(auth),
        subscriptionServiceProvider.overrideWithValue(subscription),
        aiServiceProvider.overrideWithValue(ai),
        deviceFingerprintServiceProvider.overrideWithValue(deviceFingerprint),
        rateLimitServiceProvider.overrideWithValue(rateLimit),
        usageServiceProvider.overrideWith(
          (ref) => UsageService(prefs, deviceFingerprint, rateLimit),
        ),
        initStatusProvider.overrideWith((ref) => initStatusNotifier),
        isProProvider.overrideWith((ref) => isPro),
        remainingGenerationsProvider.overrideWith((ref) => isPro ? 999 : 1),
      ],
      child: const ProsepalApp(),
    );
  }

  void dispose() {
    auth.dispose();
  }
}
