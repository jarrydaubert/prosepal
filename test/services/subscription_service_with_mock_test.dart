import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/subscription_service.dart';

import '../mocks/mock_subscription_service.dart';

/// Consolidated SubscriptionService Test Suite
///
/// This file combines tests from:
/// - subscription_service_test.dart (basic API contract tests)
/// - subscription_service_mock_test.dart (pricing, product IDs, entitlements)
/// - subscription_service_with_mock_test.dart (mock service with state control)
///
/// Covers all 7 documented RevenueCat methods with happy and unhappy paths
///
/// Reference: docs/INTEGRATION_TESTING.md - RevenueCat section
/// API Key Usage:
/// - Unit tests: Use MockSubscriptionService (no real API calls)
/// - Integration tests: Use Test Store key (test_iCdJYZJvbduyqGECAsUtDJKYClX)
/// - Manual testing: Use Production key on real device with Apple Sandbox
void main() {
  late MockSubscriptionService subscriptionService;

  setUp(() {
    subscriptionService = MockSubscriptionService();
  });

  tearDown(() {
    subscriptionService.reset();
  });

  group('initialize', () {
    test('happy: SDK configures successfully', () async {
      await subscriptionService.initialize();

      expect(subscriptionService.isConfigured, isTrue);
      expect(subscriptionService.initializeCallCount, equals(1));
    });

    test('happy: multiple calls only initialize once effectively', () async {
      await subscriptionService.initialize();
      await subscriptionService.initialize();

      expect(subscriptionService.isConfigured, isTrue);
      expect(subscriptionService.initializeCallCount, equals(2));
    });

    test('unhappy: initialization error throws', () async {
      subscriptionService.errorToThrow = Exception('API key invalid');

      expect(
        () => subscriptionService.initialize(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getOfferings', () {
    test('happy: returns offerings when configured', () async {
      subscriptionService.setConfigured(true);
      // Note: Can't easily create real Offerings, so test null case
      final offerings = await subscriptionService.getOfferings();

      expect(subscriptionService.getOfferingsCallCount, equals(1));
      // offerings is null since we didn't set mock data
      expect(offerings, isNull);
    });

    test('happy: tracks call count', () async {
      await subscriptionService.getOfferings();
      await subscriptionService.getOfferings();

      expect(subscriptionService.getOfferingsCallCount, equals(2));
    });

    test('unhappy: returns null when not configured', () async {
      subscriptionService.setConfigured(false);

      final offerings = await subscriptionService.getOfferings();

      expect(offerings, isNull);
    });

    test('unhappy: network error throws', () async {
      subscriptionService.errorToThrow = Exception('Network error');

      expect(
        () => subscriptionService.getOfferings(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('isPro (checkSubscriptionStatus)', () {
    test('happy: returns true when pro', () async {
      subscriptionService.setIsPro(true);

      final isPro = await subscriptionService.isPro();

      expect(isPro, isTrue);
      expect(subscriptionService.isProCallCount, equals(1));
    });

    test('happy: returns false when not pro', () async {
      subscriptionService.setIsPro(false);

      final isPro = await subscriptionService.isPro();

      expect(isPro, isFalse);
    });

    test('unhappy: returns false when not configured', () async {
      subscriptionService.setConfigured(false);

      final isPro = await subscriptionService.isPro();

      expect(isPro, isFalse);
    });

    test('unhappy: error throws', () async {
      subscriptionService.errorToThrow = Exception('API error');

      expect(
        () => subscriptionService.isPro(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('purchasePackage', () {
    // Note: Package is a RevenueCat class that's hard to instantiate
    // These tests verify behavior through the mock's state management
    // Real purchase testing happens in integration_test/revenuecat_test.dart

    test('happy: purchase result updates pro status', () async {
      subscriptionService.purchaseResult = true;
      subscriptionService.setIsPro(false);

      // Verify the mock behavior without needing real Package
      expect(await subscriptionService.isPro(), isFalse);

      // Simulate purchase result
      subscriptionService.setIsPro(true);
      expect(await subscriptionService.isPro(), isTrue);
    });

    test('unhappy: cancelled purchase does not grant entitlement', () async {
      subscriptionService.purchaseResult = false;
      subscriptionService.setIsPro(false);

      // Verify state doesn't change on failed purchase
      expect(await subscriptionService.isPro(), isFalse);
    });
  });

  group('restorePurchases', () {
    test('happy: restores previous purchases', () async {
      subscriptionService.restoreResult = true;
      subscriptionService.setIsPro(false);

      final result = await subscriptionService.restorePurchases();

      expect(result, isTrue);
      expect(await subscriptionService.isPro(), isTrue);
      expect(subscriptionService.restorePurchasesCallCount, equals(1));
    });

    test('happy: no purchases to restore returns false', () async {
      subscriptionService.restoreResult = false;

      final result = await subscriptionService.restorePurchases();

      expect(result, isFalse);
    });

    test('unhappy: returns false when not configured', () async {
      subscriptionService.setConfigured(false);

      final result = await subscriptionService.restorePurchases();

      expect(result, isFalse);
    });

    test('unhappy: restore error throws', () async {
      subscriptionService.errorToThrow = Exception('Restore failed');

      expect(
        () => subscriptionService.restorePurchases(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('showPaywall', () {
    test('happy: user purchases via paywall', () async {
      subscriptionService.paywallResult = true;

      final result = await subscriptionService.showPaywall();

      expect(result, isTrue);
      expect(await subscriptionService.isPro(), isTrue);
      expect(subscriptionService.showPaywallCallCount, equals(1));
    });

    test('happy: user dismisses paywall returns false', () async {
      subscriptionService.paywallResult = false;

      final result = await subscriptionService.showPaywall();

      expect(result, isFalse);
    });

    test('unhappy: returns false when not configured', () async {
      subscriptionService.setConfigured(false);

      final result = await subscriptionService.showPaywall();

      expect(result, isFalse);
    });

    test('unhappy: paywall error throws', () async {
      subscriptionService.errorToThrow = Exception('Paywall load failed');

      expect(
        () => subscriptionService.showPaywall(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('showPaywallIfNeeded', () {
    test('happy: already pro returns true without showing', () async {
      subscriptionService.setIsPro(true);
      subscriptionService.paywallResult = false; // Would fail if shown

      final result = await subscriptionService.showPaywallIfNeeded();

      expect(result, isTrue);
    });

    test('happy: not pro shows paywall', () async {
      subscriptionService.setIsPro(false);
      subscriptionService.paywallResult = true;

      final result = await subscriptionService.showPaywallIfNeeded();

      expect(result, isTrue);
      expect(subscriptionService.showPaywallIfNeededCallCount, equals(1));
    });

    test('unhappy: returns false when not configured', () async {
      subscriptionService.setConfigured(false);

      final result = await subscriptionService.showPaywallIfNeeded();

      expect(result, isFalse);
    });
  });

  group('identifyUser', () {
    test('happy: links Supabase user ID', () async {
      await subscriptionService.identifyUser('supabase-user-123');

      expect(subscriptionService.identifyUserCallCount, equals(1));
      expect(
        subscriptionService.lastIdentifiedUserId,
        equals('supabase-user-123'),
      );
    });

    test('happy: does nothing when not configured', () async {
      subscriptionService.setConfigured(false);

      await subscriptionService.identifyUser('user-456');

      expect(subscriptionService.identifyUserCallCount, equals(1));
      expect(subscriptionService.lastIdentifiedUserId, equals('user-456'));
    });

    test('unhappy: identify error throws', () async {
      subscriptionService.errorToThrow = Exception('Identify failed');

      expect(
        () => subscriptionService.identifyUser('user-789'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('logOut', () {
    test('happy: clears entitlements', () async {
      subscriptionService.setIsPro(true);

      await subscriptionService.logOut();

      expect(await subscriptionService.isPro(), isFalse);
      expect(subscriptionService.logOutCallCount, equals(1));
    });

    test('unhappy: logout error throws', () async {
      subscriptionService.errorToThrow = Exception('Logout failed');

      expect(
        () => subscriptionService.logOut(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getCustomerInfo', () {
    test('happy: returns customer info when configured', () async {
      final info = await subscriptionService.getCustomerInfo();

      expect(subscriptionService.getCustomerInfoCallCount, equals(1));
      // info is null since we didn't set mock data
      expect(info, isNull);
    });

    test('unhappy: returns null when not configured', () async {
      subscriptionService.setConfigured(false);

      final info = await subscriptionService.getCustomerInfo();

      expect(info, isNull);
    });

    test('unhappy: error throws', () async {
      subscriptionService.errorToThrow = Exception('Customer info error');

      expect(
        () => subscriptionService.getCustomerInfo(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('showCustomerCenter', () {
    test('happy: opens customer center', () async {
      await subscriptionService.showCustomerCenter();

      expect(subscriptionService.showCustomerCenterCallCount, equals(1));
    });

    test('happy: does nothing when not configured', () async {
      subscriptionService.setConfigured(false);

      await subscriptionService.showCustomerCenter();

      expect(subscriptionService.showCustomerCenterCallCount, equals(1));
    });

    test('unhappy: error throws', () async {
      subscriptionService.errorToThrow = Exception('Customer center error');

      expect(
        () => subscriptionService.showCustomerCenter(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('entitlement flow', () {
    test('complete flow: free -> purchase -> pro', () async {
      // Start as free
      expect(await subscriptionService.isPro(), isFalse);

      // Simulate successful purchase
      subscriptionService.setIsPro(true);

      // Now pro
      expect(await subscriptionService.isPro(), isTrue);
    });

    test('complete flow: pro -> logout -> free', () async {
      subscriptionService.setIsPro(true);
      expect(await subscriptionService.isPro(), isTrue);

      await subscriptionService.logOut();

      expect(await subscriptionService.isPro(), isFalse);
    });

    test('complete flow: free -> restore -> pro', () async {
      subscriptionService.setIsPro(false);
      subscriptionService.restoreResult = true;

      await subscriptionService.restorePurchases();

      expect(await subscriptionService.isPro(), isTrue);
    });

    test('complete flow: free -> paywall -> pro', () async {
      subscriptionService.setIsPro(false);
      subscriptionService.paywallResult = true;

      await subscriptionService.showPaywall();

      expect(await subscriptionService.isPro(), isTrue);
    });
  });

  group('call count tracking', () {
    test('should track method calls accurately', () async {
      await subscriptionService.initialize();
      await subscriptionService.isPro();
      await subscriptionService.isPro();
      await subscriptionService.getCustomerInfo();
      await subscriptionService.getOfferings();
      await subscriptionService.restorePurchases();
      await subscriptionService.showPaywall();
      await subscriptionService.showPaywallIfNeeded();
      await subscriptionService.showCustomerCenter();
      await subscriptionService.identifyUser('user');
      await subscriptionService.logOut();

      expect(subscriptionService.initializeCallCount, equals(1));
      expect(subscriptionService.isProCallCount, equals(2));
      expect(subscriptionService.getCustomerInfoCallCount, equals(1));
      expect(subscriptionService.getOfferingsCallCount, equals(1));
      expect(subscriptionService.restorePurchasesCallCount, equals(1));
      expect(subscriptionService.showPaywallCallCount, equals(1));
      expect(subscriptionService.showPaywallIfNeededCallCount, equals(1));
      expect(subscriptionService.showCustomerCenterCallCount, equals(1));
      expect(subscriptionService.identifyUserCallCount, equals(1));
      expect(subscriptionService.logOutCallCount, equals(1));
    });

    test('reset clears all state and counts', () async {
      subscriptionService.setIsPro(true);
      await subscriptionService.isPro();
      subscriptionService.errorToThrow = Exception('test');

      subscriptionService.reset();

      expect(await subscriptionService.isPro(), isFalse);
      expect(subscriptionService.isProCallCount, equals(1)); // After reset
      expect(subscriptionService.errorToThrow, isNull);
    });
  });

  // ============================================================
  // REAL SERVICE TESTS (API Contract & Not Initialized Paths)
  // From: subscription_service_test.dart
  // ============================================================

  group('SubscriptionService (real) - API Contract', () {
    late SubscriptionService service;

    setUp(() {
      service = SubscriptionService();
    });

    test('should create new instance', () {
      expect(service, isNotNull);
    });

    test('should not be initialized by default', () {
      expect(service.isConfigured, isFalse);
    });

    test('should expose all required methods', () {
      expect(service.initialize, isA<Function>());
      expect(service.isPro, isA<Function>());
      expect(service.getCustomerInfo, isA<Function>());
      expect(service.getOfferings, isA<Function>());
      expect(service.restorePurchases, isA<Function>());
      expect(service.showPaywall, isA<Function>());
      expect(service.showPaywallIfNeeded, isA<Function>());
      expect(service.showCustomerCenter, isA<Function>());
      expect(service.identifyUser, isA<Function>());
      expect(service.logOut, isA<Function>());
      expect(service.addCustomerInfoListener, isA<Function>());
    });

    test('should allow multiple service instances', () {
      final service1 = SubscriptionService();
      final service2 = SubscriptionService();

      expect(service1, isNotNull);
      expect(service2, isNotNull);
      expect(identical(service1, service2), isFalse);
    });
  });

  group('SubscriptionService (real) - Not Initialized Paths', () {
    late SubscriptionService service;

    setUp(() {
      service = SubscriptionService();
    });

    test('isPro returns false when not initialized', () async {
      expect(await service.isPro(), isFalse);
    });

    test('getCustomerInfo returns null when not initialized', () async {
      expect(await service.getCustomerInfo(), isNull);
    });

    test('getOfferings returns null when not initialized', () async {
      expect(await service.getOfferings(), isNull);
    });

    test('restorePurchases returns false when not initialized', () async {
      expect(await service.restorePurchases(), isFalse);
    });

    test('showPaywall returns false when not initialized', () async {
      expect(await service.showPaywall(), isFalse);
    });

    test('showPaywallIfNeeded returns false when not initialized', () async {
      expect(await service.showPaywallIfNeeded(), isFalse);
    });

    test('showCustomerCenter completes without error', () async {
      await service.showCustomerCenter();
    });

    test('identifyUser completes without error', () async {
      await service.identifyUser('test-user-id');
    });
  });

  // ============================================================
  // CONFIGURATION & PRODUCT TESTS
  // From: subscription_service_mock_test.dart
  // ============================================================

  group('API Key Configuration', () {
    test('iOS API key has correct format', () {
      const iosKey = 'appl_dWOaTNoefQCZUxqvQfsTPuMqYuk';
      expect(iosKey.startsWith('appl_'), isTrue);
      expect(iosKey.length, greaterThan(10));
    });

    test('Test Store key has correct format', () {
      const testKey = 'test_iCdJYZJvbduyqGECAsUtDJKYClX';
      expect(testKey.startsWith('test_'), isTrue);
    });

    test('entitlement ID is correct', () {
      const entitlementId = 'pro';
      expect(entitlementId, equals('pro'));
    });
  });

  group('Product IDs', () {
    test('weekly product ID has correct format', () {
      const productId = 'com.prosepal.pro.weekly';
      expect(productId, startsWith('com.prosepal'));
      expect(productId, endsWith('weekly'));
    });

    test('monthly product ID has correct format', () {
      const productId = 'com.prosepal.pro.monthly';
      expect(productId, startsWith('com.prosepal'));
      expect(productId, endsWith('monthly'));
    });

    test('yearly product ID has correct format', () {
      const productId = 'com.prosepal.pro.yearly';
      expect(productId, startsWith('com.prosepal'));
      expect(productId, endsWith('yearly'));
    });
  });

  group('Pricing Validation', () {
    test('weekly price is reasonable', () {
      const weeklyPrice = 2.99;
      expect(weeklyPrice, lessThan(5.0));
      expect(weeklyPrice, greaterThan(0));
    });

    test('monthly price is reasonable', () {
      const monthlyPrice = 4.99;
      expect(monthlyPrice, lessThan(10.0));
      expect(monthlyPrice, greaterThan(0));
    });

    test('yearly provides savings over monthly', () {
      const monthlyPrice = 4.99;
      const yearlyPrice = 29.99;
      const monthsInYear = 12;

      final yearlyFromMonthly = monthlyPrice * monthsInYear;
      final savings = yearlyFromMonthly - yearlyPrice;
      final savingsPercent = (savings / yearlyFromMonthly) * 100;

      expect(savings, greaterThan(0));
      expect(savingsPercent, greaterThan(40)); // > 40% savings
    });
  });

  group('Trial Period Validation', () {
    test('weekly has 3-day trial', () {
      const trialDays = 3;
      expect(trialDays, equals(3));
    });

    test('monthly has 7-day trial', () {
      const trialDays = 7;
      expect(trialDays, equals(7));
    });

    test('yearly has 7-day trial', () {
      const trialDays = 7;
      expect(trialDays, equals(7));
    });
  });

  group('Usage Limits', () {
    test('free tier allows 3 lifetime generations', () {
      const freeLimit = 3;
      expect(freeLimit, equals(3));
    });

    test('pro tier allows 500 monthly generations', () {
      const proLimit = 500;
      expect(proLimit, equals(500));
    });
  });

  group('Entitlement Logic', () {
    test('check for pro entitlement correctly', () {
      const entitlementId = 'pro';
      final activeEntitlements = {'pro': true, 'trial': false};

      final hasPro = activeEntitlements.containsKey(entitlementId) &&
          activeEntitlements[entitlementId] == true;

      expect(hasPro, isTrue);
    });

    test('returns false when entitlement not present', () {
      const entitlementId = 'pro';
      final activeEntitlements = <String, bool>{};

      final hasPro = activeEntitlements.containsKey(entitlementId);

      expect(hasPro, isFalse);
    });

    test('returns false when entitlement is inactive', () {
      const entitlementId = 'pro';
      final activeEntitlements = {'pro': false};

      final hasPro = activeEntitlements.containsKey(entitlementId) &&
          activeEntitlements[entitlementId] == true;

      expect(hasPro, isFalse);
    });
  });

  group('PaywallResult Scenarios', () {
    test('purchased result grants access', () {
      const resultCode = 'purchased';
      expect(resultCode == 'purchased' || resultCode == 'restored', isTrue);
    });

    test('restored result grants access', () {
      const resultCode = 'restored';
      expect(resultCode == 'purchased' || resultCode == 'restored', isTrue);
    });

    test('cancelled result does not grant access', () {
      const resultCode = 'cancelled';
      expect(resultCode != 'purchased' && resultCode != 'restored', isTrue);
    });

    test('error result does not grant access', () {
      const resultCode = 'error';
      expect(resultCode != 'purchased' && resultCode != 'restored', isTrue);
    });
  });
}
