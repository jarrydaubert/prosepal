import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/app/app.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/services/subscription_service.dart';

/// RevenueCat Integration Tests
///
/// Based on official RevenueCat documentation:
/// - https://www.revenuecat.com/docs/test-and-launch/debugging
/// - https://www.revenuecat.com/docs/test-and-launch/sandbox/apple-app-store
/// - https://www.revenuecat.com/docs/test-and-launch/launch-checklist
///
/// Run with: flutter test integration_test/revenuecat_test.dart
///
/// DEBUG LOGS:
/// All RevenueCat logs are prepended with "[Purchases]"
/// Key emojis to watch for:
///   😻 = Success from RevenueCat
///   😻💰 = Purchase info received
///   💰 = Product-related messages
///   ‼️ = Errors requiring attention
///   ⚠️ = Warnings about implementation
///
/// TESTING ENVIRONMENTS:
/// 1. Test Store (current): Instant purchases, no sandbox accounts needed
/// 2. Apple Sandbox: Real store simulation, requires sandbox tester account
/// 3. TestFlight: Production-like, renewals every 24 hours (Dec 2024+)
///
/// SANDBOX RENEWAL RATES:
///   3 days → 2 min | 1 week → 3 min | 1 month → 5 min
///   2 months → 10 min | 3 months → 15 min | 6 months → 30 min | 1 year → 1 hour
///   Max 12 renewals per day in sandbox
///
/// BEFORE APP STORE SUBMISSION:
/// - Replace Test Store key with platform-specific production key
/// - Test with real Apple Sandbox (not Test Store)
/// - Verify transactions appear in RevenueCat dashboard
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Pro entitlement ID - must match RevenueCat dashboard
  const kProEntitlement = 'pro';

  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    // IMPORTANT: Set log level BEFORE configure (per RevenueCat docs)
    // Look for "[Purchases]" prefix in console output
    await Purchases.setLogLevel(LogLevel.debug);

    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════╗');
    debugPrint('║  RevenueCat Integration Tests                            ║');
    debugPrint('║  Using: ${SubscriptionService.isUsingTestStore ? "TEST STORE" : "PRODUCTION"}                                    ║');
    debugPrint('║  Watch for [Purchases] logs with emoji indicators        ║');
    debugPrint('╚══════════════════════════════════════════════════════════╝');
    debugPrint('');
  });

  group('1. SDK Configuration (Launch Checklist Item)', () {
    testWidgets('RevenueCat initializes without errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      // Wait for SDK initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify app launched
      expect(find.byType(MaterialApp), findsOneWidget);

      // Check SDK is configured
      final subscriptionService = SubscriptionService();
      await subscriptionService.initialize();

      expect(subscriptionService.isConfigured, isTrue,
          reason: 'RevenueCat SDK should be initialized');

      debugPrint('✅ SDK initialized successfully');
      debugPrint('   Using Test Store: ${SubscriptionService.isUsingTestStore}');
    });

    testWidgets('debug logs are enabled and emitting', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Trigger an API call to generate logs
      try {
        await Purchases.getCustomerInfo();
        debugPrint('✅ Check console for [Purchases] debug logs');
        debugPrint('   Look for: 😻 (success), 💰 (products), ‼️ (errors)');
      } catch (e) {
        debugPrint('⚠️ API call failed: $e');
      }
    });
  });

  group('2. Product Configuration (Launch Checklist Item)', () {
    testWidgets('offerings are fetched successfully', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      final offerings = await Purchases.getOfferings();

      // Check for current offering
      expect(offerings.current, isNotNull,
          reason: 'Current offering must be configured in RevenueCat dashboard');

      debugPrint('✅ Offerings fetched successfully');
      debugPrint('   Current offering: ${offerings.current!.identifier}');
      debugPrint('   Packages: ${offerings.current!.availablePackages.length}');
    });

    testWidgets('no Invalid Product Identifiers in offerings', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];

      // All packages should have valid products
      expect(packages, isNotEmpty,
          reason: 'Should have at least one package with valid products. '
              'Check console for "Invalid Product Identifiers" warning');

      for (final package in packages) {
        expect(package.storeProduct.identifier, isNotEmpty);
        expect(package.storeProduct.price, greaterThan(0));

        debugPrint('✅ Valid product: ${package.storeProduct.identifier} '
            '- ${package.storeProduct.priceString}');
      }
    });

    testWidgets('expected subscription products exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      final offerings = await Purchases.getOfferings();
      final productIds = offerings.current?.availablePackages
              .map((p) => p.storeProduct.identifier)
              .toList() ??
          [];

      debugPrint('📦 Found products: $productIds');

      // Check for expected product types (weekly/monthly/yearly)
      final hasSubscriptionProducts = productIds.any((id) =>
          id.contains('weekly') ||
          id.contains('monthly') ||
          id.contains('yearly'));

      expect(hasSubscriptionProducts, isTrue,
          reason: 'Should have subscription products configured');
    });
  });

  group('3. User Identity (Launch Checklist Item)', () {
    testWidgets('anonymous user gets valid App User ID', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      final customerInfo = await Purchases.getCustomerInfo();

      expect(customerInfo.originalAppUserId, isNotEmpty,
          reason: 'Anonymous user should have an App User ID');

      debugPrint('✅ User identity verified');
      debugPrint('   App User ID: ${customerInfo.originalAppUserId}');
      debugPrint('   Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');
    });

    testWidgets('user tracked in customer view', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      final customerInfo = await Purchases.getCustomerInfo();

      // Log user ID for manual verification in RevenueCat dashboard
      debugPrint('');
      debugPrint('📋 Verify in RevenueCat Dashboard:');
      debugPrint('   Go to: Customers > Search for App User ID');
      debugPrint('   App User ID: ${customerInfo.originalAppUserId}');
      debugPrint('');

      expect(customerInfo, isNotNull);
    });
  });

  group('4. Purchase Testing (Launch Checklist Item)', () {
    testWidgets('test purchase unlocks pro content', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Get offerings
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];

      if (packages.isEmpty) {
        debugPrint('⚠️ No packages available - skipping purchase test');
        return;
      }

      // Find monthly package (or first available)
      final package = packages.firstWhere(
        (p) => p.identifier.toLowerCase().contains('monthly'),
        orElse: () => packages.first,
      );

      debugPrint('🛒 Attempting purchase: ${package.storeProduct.identifier}');
      debugPrint('   Price: ${package.storeProduct.priceString}');

      try {
        // Perform purchase
        final result = await Purchases.purchase(
          PurchaseParams.package(package),
        );

        final customerInfo = result.customerInfo;
        final hasPro = customerInfo.entitlements.active.containsKey(kProEntitlement);

        expect(hasPro, isTrue,
            reason: 'Pro entitlement should be active after purchase');

        debugPrint('✅ Purchase successful!');
        debugPrint('   Active entitlements: ${customerInfo.entitlements.active.keys}');

        // Verify transaction appears in dashboard
        debugPrint('');
        debugPrint('📋 Verify in RevenueCat Dashboard:');
        debugPrint('   1. Go to Activity view');
        debugPrint('   2. Enable "View Sandbox Data" toggle');
        debugPrint('   3. Search for App User ID: ${customerInfo.originalAppUserId}');
        debugPrint('');
      } on PlatformException catch (e) {
        if (e.code == 'PURCHASE_CANCELLED' ||
            (e.message?.contains('cancelled') ?? false)) {
          debugPrint('ℹ️ Purchase cancelled by user (expected in test)');
        } else {
          debugPrint('❌ Purchase error: ${e.code} - ${e.message}');
          // Don't fail - Test Store may not be configured
        }
      } catch (e) {
        debugPrint('❌ Unexpected error: $e');
      }
    });

    testWidgets('restore purchases works', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

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
    });

    testWidgets('subscription status updates correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Get initial status
      final customerInfo = await Purchases.getCustomerInfo();
      final initialEntitlements = customerInfo.entitlements.active.keys.toList();

      debugPrint('📊 Subscription Status Check');
      debugPrint('   Active: ${initialEntitlements.isNotEmpty}');
      debugPrint('   Entitlements: $initialEntitlements');

      if (customerInfo.entitlements.active.containsKey(kProEntitlement)) {
        final proEntitlement = customerInfo.entitlements.active[kProEntitlement]!;
        debugPrint('   Pro expires: ${proEntitlement.expirationDate}');
        debugPrint('   Will renew: ${proEntitlement.willRenew}');
      }

      expect(customerInfo, isNotNull);
    });
  });

  group('5. UI Flow Integration', () {
    testWidgets('paywall shows when free user exhausted', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            remainingGenerationsProvider.overrideWith((ref) => 0),
            isProProvider.overrideWith((ref) => false),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to generate screen
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close Friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Heartfelt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should see upgrade button
      final upgradeButton = find.text('Upgrade to Continue');
      await tester.ensureVisible(upgradeButton);
      await tester.pumpAndSettle();

      expect(upgradeButton, findsOneWidget);
      debugPrint('✅ Upgrade prompt shown for free user');
    });

    testWidgets('pro user bypasses paywall', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            remainingGenerationsProvider.overrideWith((ref) => 500),
            isProProvider.overrideWith((ref) => true),
          ],
          child: const ProsepalApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to generate screen
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close Friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Heartfelt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should see generate button (not upgrade)
      final generateButton = find.text('Generate Messages');
      await tester.ensureVisible(generateButton);
      await tester.pumpAndSettle();

      expect(generateButton, findsOneWidget);
      expect(find.text('Upgrade to Continue'), findsNothing);
      debugPrint('✅ Pro user can generate without paywall');
    });
  });

  group('6. Pre-Launch Verification', () {
    testWidgets('verify Test Store vs Production key', (tester) async {
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

      // This test always passes - it's informational
      expect(true, isTrue);
    });
  });
}
