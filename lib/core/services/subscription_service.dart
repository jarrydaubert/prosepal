import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class SubscriptionService {
  // RevenueCat API Keys (test keys - replace with production keys before release)
  static const String _iosApiKey = 'test_iCdJYZJvbduyqGECAsUtDJKYClX';
  static const String _androidApiKey = 'test_iCdJYZJvbduyqGECAsUtDJKYClX';
  static const String _entitlementId = 'pro';

  bool _isInitialized = false;

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Purchases.setLogLevel(LogLevel.debug);

    final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;

    final config = PurchasesConfiguration(apiKey);
    await Purchases.configure(config);

    _isInitialized = true;
    debugPrint('RevenueCat initialized');
  }

  /// Check if user has Pro entitlement
  Future<bool> isPro() async {
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
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('Error getting customer info: $e');
      return null;
    }
  }

  /// Get available offerings (products)
  Future<Offerings?> getOfferings() async {
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
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      return result.customerInfo.entitlements.active.containsKey(_entitlementId);
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
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.active.containsKey(_entitlementId);
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  /// Show RevenueCat's built-in paywall
  Future<bool> showPaywall() async {
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
