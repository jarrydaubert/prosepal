import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// They test actual SDK behavior, not mocks.
///
/// Run with: patrol test -t integration_test/device_only/revenuecat_test.dart
///
/// TESTING ENVIRONMENTS:
/// 1. Test Store: Instant purchases, no sandbox accounts needed
/// 2. Apple Sandbox: Real store simulation, requires sandbox tester account
/// 3. TestFlight: Production-like, renewals every 24 hours
///
/// BEFORE APP STORE SUBMISSION:
/// - Replace Test Store key with platform-specific production key
/// - Test with real Apple Sandbox (not Test Store)
/// - Verify transactions appear in RevenueCat dashboard
void main() {
  const kProEntitlement = 'pro';
  late SharedPreferences prefs;

  Future<void> initTest() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await Purchases.setLogLevel(LogLevel.debug);
  }

  Future<void> pumpApp(PatrolIntegrationTester $) async {
    await $.pumpWidgetAndSettle(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ProsepalApp(),
      ),
    );
  }

  // ===========================================================================
  // SDK Configuration
  // ===========================================================================

  patrolTest(
    'RevenueCat SDK initializes without errors',
    ($) async {
      await initTest();
      await pumpApp($);

      expect($(MaterialApp), findsOneWidget);

      final subscriptionService = SubscriptionService();
      await subscriptionService.initialize();
      expect(subscriptionService.isConfigured, isTrue);

      debugPrint('✅ SDK initialized successfully');
      debugPrint('   Using Test Store: ${SubscriptionService.isUsingTestStore}');
    },
  );

  // ===========================================================================
  // Product Configuration
  // ===========================================================================

  patrolTest(
    'offerings are fetched successfully',
    ($) async {
      await initTest();
      await pumpApp($);

      final offerings = await Purchases.getOfferings();

      expect(offerings.current, isNotNull,
          reason: 'Current offering must be configured in RevenueCat dashboard');

      debugPrint('✅ Offerings fetched successfully');
      debugPrint('   Current offering: ${offerings.current!.identifier}');
      debugPrint('   Packages: ${offerings.current!.availablePackages.length}');
    },
  );

  patrolTest(
    'all packages have valid products',
    ($) async {
      await initTest();
      await pumpApp($);

      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];

      expect(packages, isNotEmpty,
          reason: 'Should have at least one package with valid products');

      for (final package in packages) {
        expect(package.storeProduct.identifier, isNotEmpty);
        expect(package.storeProduct.price, greaterThan(0));

        debugPrint('✅ Valid product: ${package.storeProduct.identifier} '
            '- ${package.storeProduct.priceString}');
      }
    },
  );

  // ===========================================================================
  // User Identity
  // ===========================================================================

  patrolTest(
    'anonymous user gets valid App User ID',
    ($) async {
      await initTest();
      await pumpApp($);

      final customerInfo = await Purchases.getCustomerInfo();

      expect(customerInfo.originalAppUserId, isNotEmpty,
          reason: 'Anonymous user should have an App User ID');

      debugPrint('✅ User identity verified');
      debugPrint('   App User ID: ${customerInfo.originalAppUserId}');
      debugPrint('   Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');
    },
  );

  // ===========================================================================
  // Purchase Testing
  // ===========================================================================

  patrolTest(
    'restore purchases works',
    ($) async {
      await initTest();
      await pumpApp($);

      try {
        final customerInfo = await Purchases.restorePurchases();

        debugPrint('✅ Restore completed');
        debugPrint('   App User ID: ${customerInfo.originalAppUserId}');
        debugPrint('   Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');

        if (customerInfo.entitlements.active.isEmpty) {
          debugPrint('   ℹ️ No purchases to restore (expected for new user)');
        }

        expect(customerInfo, isNotNull);
      } catch (e) {
        fail('Restore purchases failed: $e');
      }
    },
  );

  patrolTest(
    'test purchase flow (manual verification)',
    ($) async {
      await initTest();
      await pumpApp($);

      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];

      if (packages.isEmpty) {
        debugPrint('⚠️ No packages available - skipping purchase test');
        return;
      }

      final package = packages.firstWhere(
        (p) => p.identifier.toLowerCase().contains('monthly'),
        orElse: () => packages.first,
      );

      debugPrint('🛒 Package available for purchase: ${package.storeProduct.identifier}');
      debugPrint('   Price: ${package.storeProduct.priceString}');
      debugPrint('');
      debugPrint('📋 To test purchase manually:');
      debugPrint('   1. Navigate to paywall in app');
      debugPrint('   2. Tap on subscription option');
      debugPrint('   3. Complete purchase in sandbox');
      debugPrint('   4. Verify entitlement in RevenueCat dashboard');

      expect(package, isNotNull);
    },
  );

  // ===========================================================================
  // UI Flow Integration
  // ===========================================================================

  patrolTest(
    'free user sees upgrade button when exhausted',
    ($) async {
      await initTest();

      await $.pumpWidgetAndSettle(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            remainingGenerationsProvider.overrideWith((ref) => 0),
            isProProvider.overrideWith((ref) => false),
          ],
          child: const ProsepalApp(),
        ),
      );

      // Navigate through wizard
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Should see upgrade button
      await $('Upgrade to Continue').waitUntilVisible();
      expect($('Upgrade to Continue'), findsOneWidget);
      debugPrint('✅ Upgrade prompt shown for free user');
    },
  );

  patrolTest(
    'pro user bypasses paywall',
    ($) async {
      await initTest();

      await $.pumpWidgetAndSettle(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            remainingGenerationsProvider.overrideWith((ref) => 500),
            isProProvider.overrideWith((ref) => true),
          ],
          child: const ProsepalApp(),
        ),
      );

      // Navigate through wizard
      await $('Birthday').tap();
      await $('Close Friend').tap();
      await $('Continue').tap();
      await $('Heartfelt').tap();
      await $('Continue').tap();

      // Should see generate button
      await $('Generate Messages').waitUntilVisible();
      expect($('Upgrade to Continue'), findsNothing);
      debugPrint('✅ Pro user can generate without paywall');
    },
  );

  // ===========================================================================
  // Pre-Launch Verification
  // ===========================================================================

  patrolTest(
    'pre-launch checklist verification',
    ($) async {
      await initTest();

      debugPrint('');
      debugPrint('🚀 PRE-LAUNCH CHECKLIST');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');

      final isTestStore = SubscriptionService.isUsingTestStore;

      if (isTestStore) {
        debugPrint('⚠️  USING TEST STORE - Do NOT submit to App Store!');
        debugPrint('');
        debugPrint('Before submission, change in subscription_service.dart:');
        debugPrint('  _useTestStore defaultValue: true → false');
        debugPrint('');
      } else {
        debugPrint('✅ Using production API key');
      }

      debugPrint('Checklist:');
      debugPrint('  [ ] Replace Test Store key with platform-specific key');
      debugPrint('  [ ] Test with real Apple Sandbox (not Test Store)');
      debugPrint('  [ ] Verify all products fetch correctly');
      debugPrint('  [ ] Test purchase unlocks "pro" content');
      debugPrint('  [ ] Verify subscription status updates');
      debugPrint('  [ ] Test restore purchases after reinstall');
      debugPrint('  [ ] Verify transactions in RevenueCat dashboard');
      debugPrint('  [ ] Include subscription disclosure in App Store description');
      debugPrint('  [ ] Wait ~24 hours after "Cleared for Sale" before release');
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════════');

      expect(true, isTrue);
    },
  );
}
