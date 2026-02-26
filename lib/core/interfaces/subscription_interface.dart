import 'package:purchases_flutter/purchases_flutter.dart';

/// Abstract interface for subscription services
/// Allows mocking in tests without RevenueCat dependency
abstract class ISubscriptionService {
  /// Check if RevenueCat is ready to use
  bool get isConfigured;

  /// Initialize RevenueCat SDK
  Future<void> initialize();

  /// Check if user has Pro entitlement
  Future<bool> isPro();

  /// Get current customer info
  Future<CustomerInfo?> getCustomerInfo();

  /// Get available offerings (products)
  Future<Offerings?> getOfferings();

  /// Purchase a package
  Future<bool> purchasePackage(Package package);

  /// Restore purchases
  Future<bool> restorePurchases();

  /// Show RevenueCat's built-in paywall
  Future<bool> showPaywall();

  /// Show paywall only if user doesn't have entitlement
  Future<bool> showPaywallIfNeeded();

  /// Show Customer Center (manage subscriptions)
  Future<void> showCustomerCenter();

  /// Listen to customer info updates
  void addCustomerInfoListener(void Function(CustomerInfo) listener);

  /// Remove customer info update listener
  void removeCustomerInfoListener(void Function(CustomerInfo) listener);

  /// Identify user
  Future<void> identifyUser(String userId);

  /// Log out user
  Future<void> logOut();
}
