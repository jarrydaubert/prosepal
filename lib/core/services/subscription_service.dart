import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class SubscriptionService {
  // ==========================================================================
  // RevenueCat API Keys
  // ==========================================================================
  //
  // These are PUBLIC keys (safe to include in app) - they only allow client-side operations.
  //
  // KEY TYPES:
  // - Production keys (appl_*, goog_*): Use for App Store/Play Store builds
  // - Test Store key: Use ONLY for automated testing, crashes in production!
  //
  // SWITCHING KEYS:
  // Override via dart-define for different environments:
  //   flutter run --dart-define=REVENUECAT_IOS_KEY=your_key
  //   flutter run --dart-define=REVENUECAT_USE_TEST_STORE=true
  //
  // BEFORE APP STORE SUBMISSION:
  // Verify you're using the production key (appl_*), NOT the Test Store key!
  // ==========================================================================

  // Production API Keys (defaults for release builds)
  static const String _iosProductionKey = 'appl_dWOaTNoefQCZUxqvQfsTPuMqYuk';
  static const String _androidProductionKey = ''; // TODO: Add before Play Store release

  // Test Store Key (for automated testing only - get from RevenueCat Dashboard)
  // Dashboard: Project Settings > Apps > Test Store
  // WARNING: Using Test Store in production will crash the app!
  static const String _testStoreKey = String.fromEnvironment(
    'REVENUECAT_TEST_STORE_KEY',
    defaultValue: 'test_iCdJYZJvbduyqGECAsUtDJKYClX', // Test Store key for development
  );

  // Environment flags
  // TODO: Set back to false before App Store submission!
  static const bool _useTestStore = bool.fromEnvironment(
    'REVENUECAT_USE_TEST_STORE',
    defaultValue: true, // TEMPORARY: Using Test Store for development
  );

  // Allow override of production keys via dart-define
  static const String _iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
    defaultValue: _iosProductionKey,
  );
  static const String _androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
    defaultValue: _androidProductionKey,
  );

  static const String _entitlementId = 'pro';

  /// Get the appropriate API key based on platform and environment
  static String get _activeApiKey {
    // If Test Store is explicitly enabled and key is provided, use it
    if (_useTestStore && _testStoreKey.isNotEmpty) {
      return _testStoreKey;
    }
    // Otherwise use platform-specific production key
    return Platform.isIOS ? _iosApiKey : _androidApiKey;
  }

  /// Check if using Test Store (for logging/debugging)
  static bool get isUsingTestStore => _useTestStore && _testStoreKey.isNotEmpty;

  bool _isInitialized = false;

  /// Check if RevenueCat is ready to use
  bool get isConfigured => _isInitialized;

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    final apiKey = _activeApiKey;

    if (apiKey.isEmpty) {
      debugPrint(
        'WARNING: RevenueCat API key not provided. '
        'Run with --dart-define=REVENUECAT_IOS_KEY=your_key '
        'or --dart-define=REVENUECAT_TEST_STORE_KEY=your_test_key',
      );
      return;
    }

    // Only enable debug logging in debug mode
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    final config = PurchasesConfiguration(apiKey);
    await Purchases.configure(config);

    _isInitialized = true;

    // Log which environment we're using
    if (isUsingTestStore) {
      debugPrint('⚠️ RevenueCat initialized with TEST STORE (not for production!)');
    } else {
      debugPrint('RevenueCat initialized with ${Platform.isIOS ? 'iOS' : 'Android'} production key');
    }
  }

  /// Check if user has Pro entitlement
  Future<bool> isPro() async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(_entitlementId);
    } catch (e) {
      debugPrint('Error checking pro status: $e');
      return false;
    }
  }

  /// Get current customer info
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_isInitialized) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('Error getting customer info: $e');
      return null;
    }
  }

  /// Get available offerings (products)
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Error getting offerings: $e');
      return null;
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo.entitlements.active.containsKey(
        _entitlementId,
      );
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('User cancelled purchase');
      } else {
        debugPrint('Purchase error: $e');
      }
      return false;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    if (!_isInitialized) {
      debugPrint('RevenueCat not initialized - cannot restore purchases');
      return false;
    }
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.active.containsKey(_entitlementId);
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  /// Show RevenueCat's built-in paywall
  /// Returns true if user purchased or restored, false if dismissed or failed
  Future<bool> showPaywall() async {
    if (!_isInitialized) {
      debugPrint('RevenueCat not initialized - cannot show paywall');
      return false;
    }

    try {
      final result = await RevenueCatUI.presentPaywall();
      return result == PaywallResult.purchased ||
          result == PaywallResult.restored;
    } catch (e) {
      debugPrint('Error showing paywall: $e');
      return false;
    }
  }

  /// Show RevenueCat's built-in paywall only if user doesn't have entitlement
  Future<bool> showPaywallIfNeeded() async {
    if (!_isInitialized) {
      debugPrint('RevenueCat not initialized - cannot show paywall');
      return false;
    }

    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(_entitlementId);
      return result == PaywallResult.purchased ||
          result == PaywallResult.restored;
    } catch (e) {
      debugPrint('Error showing paywall: $e');
      return false;
    }
  }

  /// Show RevenueCat's Customer Center (manage subscriptions)
  Future<void> showCustomerCenter() async {
    if (!_isInitialized) {
      debugPrint('RevenueCat not initialized - cannot show customer center');
      return;
    }
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('Error showing customer center: $e');
    }
  }

  /// Listen to customer info updates
  void addCustomerInfoListener(void Function(CustomerInfo) listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  /// Identify user (for when they sign in with Supabase later)
  Future<void> identifyUser(String userId) async {
    if (!_isInitialized) {
      debugPrint('RevenueCat not initialized, skipping identify');
      return;
    }
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('Error identifying user: $e');
    }
  }

  /// Log out user
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
}
