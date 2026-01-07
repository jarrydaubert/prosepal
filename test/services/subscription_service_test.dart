import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/subscription_service.dart';

/// SubscriptionService Unit Tests
///
/// Tests REAL SubscriptionService behavior, not mock behavior.
/// Each test answers: "What bug does this catch?"
///
/// Note: RevenueCat SDK cannot be initialized in unit tests.
/// These tests verify graceful handling when SDK is not configured.
/// Full purchase flow testing requires integration tests on device.
void main() {
  group('SubscriptionService - Not Initialized Behavior', () {
    // Bug: App crashes when RevenueCat not initialized
    // These tests verify graceful degradation

    late SubscriptionService service;

    setUp(() {
      service = SubscriptionService();
    });

    test('isConfigured returns false before initialize', () {
      expect(service.isConfigured, isFalse);
    });

    test('isPro returns false when not initialized', () async {
      // Bug: Free user incorrectly shown as Pro, or crash
      final result = await service.isPro();
      expect(result, isFalse);
    });

    test('getCustomerInfo returns null when not initialized', () async {
      // Bug: Crash when accessing customer info before init
      final result = await service.getCustomerInfo();
      expect(result, isNull);
    });

    test('getOfferings returns null when not initialized', () async {
      // Bug: Crash when loading offerings before init
      final result = await service.getOfferings();
      expect(result, isNull);
    });

    test('restorePurchases returns false when not initialized', () async {
      // Bug: User thinks restore worked when it didn't
      final result = await service.restorePurchases();
      expect(result, isFalse);
    });

    test('showPaywall returns false when not initialized', () async {
      // Bug: User stuck on paywall that never loads
      final result = await service.showPaywall();
      expect(result, isFalse);
    });

    test('showPaywallIfNeeded returns false when not initialized', () async {
      // Bug: User blocked from feature without explanation
      final result = await service.showPaywallIfNeeded();
      expect(result, isFalse);
    });

    test(
      'showCustomerCenter completes without crash when not initialized',
      () async {
        // Bug: Crash when opening customer center before init
        await expectLater(service.showCustomerCenter(), completes);
      },
    );

    test('identifyUser completes without crash when not initialized', () async {
      // Bug: Crash when identifying user before init
      await expectLater(service.identifyUser('test-user'), completes);
    });

    test('logOut completes without crash when not initialized', () async {
      // Bug: Crash when logging out before init
      await expectLater(service.logOut(), completes);
    });
  });

  group('SubscriptionService - Instance Behavior', () {
    test('creates new instance each time', () {
      // Bug: Singleton leaking state between tests/sessions
      final service1 = SubscriptionService();
      final service2 = SubscriptionService();

      expect(identical(service1, service2), isFalse);
    });

    test('new instance starts unconfigured', () {
      // Bug: New instance inherits configured state
      final service = SubscriptionService();
      expect(service.isConfigured, isFalse);
    });
  });
}
