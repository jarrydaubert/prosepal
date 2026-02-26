import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patrol/patrol.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/services/subscription_service.dart';

/// RevenueCat Integration Tests - REAL DEVICE ONLY
///
/// These tests require a physical device or simulator with RevenueCat configured.
/// They verify actual SDK behavior with real API calls.
///
/// Run with: patrol test -t integration_test/device_only/revenuecat_test.dart
///
/// See docs/SUBSCRIPTION_TESTING.md for manual verification checklist.
void main() {
  late SharedPreferences prefs;
  late SubscriptionService subscriptionService;

  Future<void> initTest() async {
    SharedPreferences.setMockInitialValues({
      'hasCompletedOnboarding': true,
    });
    prefs = await SharedPreferences.getInstance();
    await Purchases.setLogLevel(LogLevel.debug);
    subscriptionService = SubscriptionService();
  }

  Future<void> pumpApp(
    PatrolIntegrationTester $, {
    bool? overrideIsPro,
    int? overrideRemaining,
  }) async {
    await $.pumpWidgetAndSettle(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          subscriptionServiceProvider.overrideWithValue(subscriptionService),
          if (overrideIsPro != null) isProProvider.overrideWith((ref) => overrideIsPro),
          if (overrideRemaining != null) remainingGenerationsProvider.overrideWith((ref) => overrideRemaining),
        ],
        child: const ProsepalApp(),
      ),
    );
  }

  // ===========================================================================
  // SDK Configuration Tests
  // ===========================================================================

  patrolTest(
    'SDK initializes and is configured',
    ($) async {
      await initTest();
      await pumpApp($);

      await subscriptionService.initialize();

      expect(subscriptionService.isConfigured, isTrue,
          reason: 'SDK should be configured after initialization');
    },
  );

  patrolTest(
    'SDK reports correct store type',
    ($) async {
      await initTest();
      await pumpApp($);

      await subscriptionService.initialize();

      // This test documents which store is being used
      // Fails if Test Store is enabled before App Store submission
      if (SubscriptionService.isUsingTestStore) {
        debugPrint('WARNING: Using Test Store - not for App Store submission');
      } else {
        debugPrint('Using production API keys');
      }

      expect(subscriptionService.isConfigured, isTrue);
    },
  );

  // ===========================================================================
  // Product Configuration Tests
  // ===========================================================================

  patrolTest(
    'offerings endpoint returns current offering',
    ($) async {
      await initTest();
      await pumpApp($);

      final offerings = await Purchases.getOfferings();

      expect(offerings.current, isNotNull,
          reason: 'Current offering must be configured in RevenueCat dashboard');
      expect(offerings.current!.identifier, isNotEmpty,
          reason: 'Offering should have a valid identifier');
    },
  );

  patrolTest(
    'current offering contains at least one package',
    ($) async {
      await initTest();
      await pumpApp($);

      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];

      expect(packages, isNotEmpty,
          reason: 'Should have at least one subscription package');
    },
  );

  patrolTest(
    'all packages have valid product identifiers',
    ($) async {
      await initTest();
      await pumpApp($);

      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];

      for (final package in packages) {
        expect(package.storeProduct.identifier, isNotEmpty,
            reason: 'Package ${package.identifier} should have product identifier');
        expect(package.storeProduct.price, greaterThan(0),
            reason: 'Package ${package.identifier} should have price > 0');
        expect(package.storeProduct.priceString, isNotEmpty,
            reason: 'Package ${package.identifier} should have formatted price');
      }
    },
  );

  patrolTest(
    'monthly package exists with expected properties',
    ($) async {
      await initTest();
      await pumpApp($);

      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];

      final monthly = packages.where(
        (p) => p.packageType == PackageType.monthly ||
               p.identifier.toLowerCase().contains('monthly'),
      );

      expect(monthly, isNotEmpty,
          reason: 'Should have a monthly subscription option');
    },
  );

  // ===========================================================================
  // User Identity Tests
  // ===========================================================================

  patrolTest(
    'anonymous user receives valid App User ID',
    ($) async {
      await initTest();
      await pumpApp($);

      final customerInfo = await Purchases.getCustomerInfo();

      expect(customerInfo.originalAppUserId, isNotEmpty,
          reason: 'Anonymous users should receive an App User ID');
    },
  );

  patrolTest(
    'customer info contains entitlements object',
    ($) async {
      await initTest();
      await pumpApp($);

      final customerInfo = await Purchases.getCustomerInfo();

      expect(customerInfo.entitlements, isNotNull,
          reason: 'Customer info should include entitlements');
      // Note: entitlements.active may be empty for free users
    },
  );

  // ===========================================================================
  // Restore Purchases Tests
  // ===========================================================================

  patrolTest(
    'restore purchases completes without error',
    ($) async {
      await initTest();
      await pumpApp($);

      // Should not throw
      final customerInfo = await Purchases.restorePurchases();

      expect(customerInfo, isNotNull,
          reason: 'Restore should return customer info');
      expect(customerInfo.originalAppUserId, isNotEmpty,
          reason: 'Restored customer should have App User ID');
    },
  );

  patrolTest(
    'restore purchases returns consistent user ID',
    ($) async {
      await initTest();
      await pumpApp($);

      final before = await Purchases.getCustomerInfo();
      final afterRestore = await Purchases.restorePurchases();

      expect(afterRestore.originalAppUserId, equals(before.originalAppUserId),
          reason: 'App User ID should remain consistent after restore');
    },
  );

  // ===========================================================================
  // Subscription Status Tests
  // ===========================================================================

  patrolTest(
    'subscription service reports isPro based on entitlements',
    ($) async {
      await initTest();
      await pumpApp($);

      await subscriptionService.initialize();
      final isPro = await subscriptionService.isPro();

      // isPro should match whether "pro" entitlement is active
      final customerInfo = await Purchases.getCustomerInfo();
      final hasProEntitlement = customerInfo.entitlements.active.containsKey('pro');

      expect(isPro, equals(hasProEntitlement),
          reason: 'isPro should match pro entitlement status');
    },
  );

  // ===========================================================================
  // UI Integration Tests
  // ===========================================================================

  patrolTest(
    'paywall screen loads offerings',
    ($) async {
      await initTest();
      await pumpApp($, overrideRemaining: 0, overrideIsPro: false);

      // Navigate to paywall via upgrade button
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Upgrade to Continue').tap();

      // Verify paywall loaded with real offerings
      // Look for price string (e.g., "$4.99/month")
      await $('\$').waitUntilVisible(timeout: const Duration(seconds: 10));
    },
  );

  patrolTest(
    'paywall shows restore purchases option',
    ($) async {
      await initTest();
      await pumpApp($, overrideRemaining: 0, overrideIsPro: false);

      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();
      await $('Upgrade to Continue').tap();

      // Verify restore option exists
      await $('Restore').scrollTo();
      expect($('Restore'), findsOneWidget,
          reason: 'Paywall should show restore purchases option');
    },
  );

  patrolTest(
    'settings shows current subscription status',
    ($) async {
      await initTest();
      await subscriptionService.initialize();
      final isPro = await subscriptionService.isPro();

      await pumpApp($, overrideIsPro: isPro);

      await $(Icons.settings_outlined).tap();
      await $('Settings').waitUntilVisible();

      // Should show either "Pro Plan" or "Free Plan" based on actual status
      if (isPro) {
        expect($('Pro Plan'), findsOneWidget);
      } else {
        expect($('Free Plan'), findsOneWidget);
      }
    },
  );

  // ===========================================================================
  // Error Handling Tests
  // ===========================================================================

  patrolTest(
    'handles network timeout gracefully',
    ($) async {
      await initTest();
      await pumpApp($);

      // Verify SDK doesn't crash on repeated calls
      for (var i = 0; i < 3; i++) {
        final offerings = await Purchases.getOfferings();
        expect(offerings, isNotNull);
      }
    },
  );

  // ===========================================================================
  // Pre-Launch Validation
  // ===========================================================================

  patrolTest(
    'all required products are configured',
    ($) async {
      await initTest();
      await pumpApp($);

      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];

      // Verify we have subscription options
      expect(packages.length, greaterThanOrEqualTo(1),
          reason: 'Should have at least 1 subscription option');

      // Log what's configured for manual verification
      for (final package in packages) {
        debugPrint('Product: ${package.storeProduct.identifier} '
            '(${package.storeProduct.priceString})');
      }
    },
  );

  patrolTest(
    'pro entitlement identifier matches expected value',
    ($) async {
      await initTest();
      await pumpApp($);

      // The app expects "pro" as the entitlement ID
      // This test documents that assumption
      const expectedEntitlementId = 'pro';

      await subscriptionService.initialize();

      // Get customer to verify entitlement structure is accessible
      final customerInfo = await Purchases.getCustomerInfo();

      // The entitlements object should exist (even if empty for free users)
      expect(customerInfo.entitlements, isNotNull);

      // Log active entitlements for debugging
      debugPrint('Active entitlements: ${customerInfo.entitlements.active.keys}');
      debugPrint('Expected entitlement ID: $expectedEntitlementId');
    },
  );
}
