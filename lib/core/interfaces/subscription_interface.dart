import 'package:purchases_flutter/purchases_flutter.dart';

/// Abstract interface for subscription services (RevenueCat).
///
/// Enables dependency injection and mocking for unit tests without
/// requiring the RevenueCat SDK at test time.
///
/// ## Usage Flow
/// 1. Call [initialize] at app startup
/// 2. Check [isConfigured] before calling other methods
/// 3. Use [isPro] or [hasEntitlement] to check access
/// 4. Use [showPaywall] or [purchasePackage] for purchases
/// 5. Listen for updates via [addCustomerInfoListener] or [customerInfoStream]
///
/// ## Error Handling
/// Most methods throw [PlatformException] on SDK errors. Use
/// [PurchasesErrorHelper.getErrorCode] to get specific error codes:
///
/// ```dart
/// try {
///   await service.purchasePackage(package);
/// } on PlatformException catch (e) {
///   final code = PurchasesErrorHelper.getErrorCode(e);
///   if (code == PurchasesErrorCode.purchaseCancelledError) {
///     // User cancelled - not an error
///   } else if (code == PurchasesErrorCode.paymentPendingError) {
///     // iOS Ask to Buy - pending parental approval
///   }
/// }
/// ```
///
/// ## Common Error Codes
/// - [PurchasesErrorCode.purchaseCancelledError] - User cancelled purchase
/// - [PurchasesErrorCode.paymentPendingError] - iOS Ask to Buy pending
/// - [PurchasesErrorCode.storeProblemError] - App Store/Play Store issue
/// - [PurchasesErrorCode.networkError] - No connectivity
/// - [PurchasesErrorCode.purchaseNotAllowedError] - Restricted account
/// - [PurchasesErrorCode.productNotAvailableForPurchaseError] - Product unavailable
///
/// ## Platform Support
/// - iOS: Full support via StoreKit 2
/// - Android: Full support via Google Play Billing
/// - Web/Desktop: Not supported (returns gracefully)
abstract class ISubscriptionService {
  /// Whether RevenueCat SDK is initialized and ready.
  ///
  /// Check this before calling purchase or offering methods.
  /// Returns false on unsupported platforms or if API key is missing.
  bool get isConfigured;

  /// Stream of customer info updates for reactive programming.
  ///
  /// Emits whenever entitlements change (purchase, expiration, restore).
  /// Use this with Riverpod StreamProvider for reactive UI updates.
  ///
  /// Returns null if SDK is not configured.
  Stream<CustomerInfo>? get customerInfoStream;

  /// Initialize RevenueCat SDK with platform-specific API key.
  ///
  /// Must be called once at app startup before other methods.
  /// Automatically syncs existing purchases after initialization.
  ///
  /// Throws [StateError] if:
  /// - Test Store is enabled in release mode (fatal misconfiguration)
  /// - API key is missing in release mode
  ///
  /// Silently returns on unsupported platforms (web, desktop).
  Future<void> initialize();

  /// Check if user has the 'pro' entitlement.
  ///
  /// Returns false if SDK not initialized or on error.
  /// For multiple entitlement tiers, use [hasEntitlement] instead.
  Future<bool> isPro();

  /// Check if user has a specific entitlement.
  ///
  /// [entitlementId] - The entitlement identifier from RevenueCat dashboard.
  ///
  /// Returns false if SDK not initialized, entitlement doesn't exist,
  /// or entitlement is expired.
  ///
  /// Use this for apps with multiple subscription tiers:
  /// ```dart
  /// if (await service.hasEntitlement('premium')) { ... }
  /// if (await service.hasEntitlement('enterprise')) { ... }
  /// ```
  Future<bool> hasEntitlement(String entitlementId);

  /// Get current customer info with all entitlements.
  ///
  /// Returns null if SDK not initialized or on error.
  /// Use for detailed entitlement inspection or displaying subscription status.
  Future<CustomerInfo?> getCustomerInfo();

  /// Get available offerings (product configurations).
  ///
  /// Returns null if SDK not initialized, no offerings configured,
  /// or on network error.
  ///
  /// Use [Offerings.current] for the default offering.
  Future<Offerings?> getOfferings();

  /// Purchase a package and return success status.
  ///
  /// [package] - The package to purchase from [getOfferings].
  ///
  /// Returns true if purchase succeeded and entitlement is now active.
  /// Returns false if:
  /// - User cancelled ([PurchasesErrorCode.purchaseCancelledError])
  /// - Payment pending approval ([PurchasesErrorCode.paymentPendingError])
  /// - Any other error occurred
  ///
  /// Throws [PlatformException] on SDK errors (caught internally, returns false).
  Future<bool> purchasePackage(Package package);

  /// Restore previous purchases from the store.
  ///
  /// Returns true if pro entitlement was restored.
  /// Returns false if no purchases found or on error.
  ///
  /// Call this when user taps "Restore Purchases" in settings.
  Future<bool> restorePurchases();

  /// Show RevenueCat's native paywall UI.
  ///
  /// Returns true if user purchased or restored successfully.
  /// Returns false if cancelled, no offerings, or error.
  ///
  /// Requires offerings configured in RevenueCat dashboard with
  /// paywall template attached.
  Future<bool> showPaywall();

  /// Show paywall only if user doesn't have the pro entitlement.
  ///
  /// Returns true if user purchased/restored, or already had entitlement.
  /// Returns false if cancelled or error.
  ///
  /// Use this as a gate before premium features.
  Future<bool> showPaywallIfNeeded();

  /// Show RevenueCat Customer Center for subscription management.
  ///
  /// Allows users to view/cancel subscriptions, request refunds,
  /// and contact support without leaving the app.
  ///
  /// Does nothing if SDK not initialized.
  Future<void> showCustomerCenter();

  /// Add a listener for customer info updates.
  ///
  /// Called when entitlements change (purchase, expiration, restore).
  /// Remember to call [removeCustomerInfoListener] to prevent leaks.
  ///
  /// For reactive patterns, prefer [customerInfoStream] with StreamProvider.
  void addCustomerInfoListener(void Function(CustomerInfo) listener);

  /// Remove a previously added customer info listener.
  void removeCustomerInfoListener(void Function(CustomerInfo) listener);

  /// Identify user with your backend user ID.
  ///
  /// [userId] - Your app's unique user identifier (e.g., Supabase user ID).
  ///
  /// Call after user signs in to link purchases to their account.
  /// Automatically syncs purchases after identification.
  ///
  /// RevenueCat will merge any anonymous purchases with the identified user.
  Future<void> identifyUser(String userId);

  /// Log out current user and reset to anonymous.
  ///
  /// Call when user signs out of your app.
  /// Does not affect the user's actual subscriptions.
  Future<void> logOut();
}
