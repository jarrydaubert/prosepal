import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show PlatformException;
import 'package:prosepal/core/interfaces/subscription_interface.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Mock implementation of ISubscriptionService for testing
///
/// Designed for purchases_flutter 7.x (tested with v7.2.0).
///
/// ## Features
/// - Configurable state (isPro, offerings, customerInfo)
/// - Call tracking and parameter capture
/// - Global and per-method error simulation
/// - RevenueCat-specific error helpers (cancelled, network, store errors)
/// - CustomerInfo listener stream for state-management tests
/// - Multi-tier entitlement support
///
/// ## Basic Usage
/// ```dart
/// final mockSub = MockSubscriptionService();
/// mockSub.setIsPro(true);
/// mockSub.purchaseResult = true;
/// ```
///
/// ## Error Simulation
/// ```dart
/// // User cancelled purchase:
/// mockSub.simulatePurchaseCancelled();
///
/// // Network error:
/// mockSub.simulateNetworkError();
///
/// // Per-method error:
/// mockSub.methodErrors['restorePurchases'] = Exception('Store error');
/// ```
///
/// ## Multi-tier Entitlements
/// ```dart
/// mockSub.setEntitlement('premium', true);
/// mockSub.setEntitlement('pro', false);
/// expect(await mockSub.hasEntitlement('premium'), true);
/// ```
class MockSubscriptionService implements ISubscriptionService {
  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  bool _isConfigured = true;
  bool _isPro = false;
  CustomerInfo? _customerInfo;
  Offerings? _offerings;

  /// Set the configured state
  void setConfigured(bool value) => _isConfigured = value;

  /// Set the pro subscription state
  void setIsPro(bool value) => _isPro = value;

  /// Set the CustomerInfo to return
  void setCustomerInfo(CustomerInfo? value) => _customerInfo = value;

  /// Set the Offerings to return
  void setOfferings(Offerings? value) => _offerings = value;

  // ---------------------------------------------------------------------------
  // Call Tracking
  // ---------------------------------------------------------------------------

  /// Number of times initialize() was called
  @visibleForTesting
  int initializeCallCount = 0;

  /// Number of times isPro() was called
  @visibleForTesting
  int isProCallCount = 0;

  /// Number of times getCustomerInfo() was called
  @visibleForTesting
  int getCustomerInfoCallCount = 0;

  /// Number of times getOfferings() was called
  @visibleForTesting
  int getOfferingsCallCount = 0;

  /// Number of times purchasePackage() was called
  @visibleForTesting
  int purchasePackageCallCount = 0;

  /// Number of times restorePurchases() was called
  @visibleForTesting
  int restorePurchasesCallCount = 0;

  /// Number of times showPaywall() was called
  @visibleForTesting
  int showPaywallCallCount = 0;

  /// Number of times showPaywallIfNeeded() was called
  @visibleForTesting
  int showPaywallIfNeededCallCount = 0;

  /// Number of times showCustomerCenter() was called
  @visibleForTesting
  int showCustomerCenterCallCount = 0;

  /// Number of times identifyUser() was called
  @visibleForTesting
  int identifyUserCallCount = 0;

  /// Number of times logOut() was called
  @visibleForTesting
  int logOutCallCount = 0;

  /// Last userId passed to identifyUser()
  @visibleForTesting
  String? lastIdentifiedUserId;

  /// Last package passed to purchasePackage()
  @visibleForTesting
  Package? lastPurchasedPackage;

  // ---------------------------------------------------------------------------
  // Result Configuration
  // ---------------------------------------------------------------------------

  /// Result to return from purchasePackage()
  @visibleForTesting
  bool purchaseResult = true;

  /// Result to return from restorePurchases()
  @visibleForTesting
  bool restoreResult = false;

  /// Result to return from showPaywall() and showPaywallIfNeeded()
  @visibleForTesting
  bool paywallResult = false;

  /// Alias for paywallResult - controls showPaywall() return value
  set showPaywallResult(bool value) => paywallResult = value;
  bool get showPaywallResult => paywallResult;

  /// Delay before showPaywall completes (for testing loading states)
  @visibleForTesting
  Duration? showPaywallDelay;

  /// Error to throw specifically for restore (shorthand for methodErrors)
  set restoreError(Exception? e) {
    if (e != null) {
      methodErrors['restorePurchases'] = e;
    } else {
      methodErrors.remove('restorePurchases');
    }
  }

  // ---------------------------------------------------------------------------
  // Error Simulation
  // ---------------------------------------------------------------------------

  /// Global error - thrown by any method if set
  @visibleForTesting
  Exception? errorToThrow;

  /// Per-method errors - takes precedence over [errorToThrow]
  ///
  /// Keys: 'initialize', 'isPro', 'getCustomerInfo', 'getOfferings',
  /// 'purchasePackage', 'restorePurchases', 'showPaywall', 'showPaywallIfNeeded',
  /// 'showCustomerCenter', 'identifyUser', 'logOut', 'hasEntitlement'
  @visibleForTesting
  final Map<String, Exception> methodErrors = {};

  Exception? _getError(String method) {
    return methodErrors[method] ?? errorToThrow;
  }

  /// Create a PlatformException matching RevenueCat error format
  ///
  /// Use with PurchasesErrorHelper.getErrorCode() in production code.
  static PlatformException createRevenueCatError(
    PurchasesErrorCode code, [
    String? message,
  ]) {
    return PlatformException(
      code: code.index.toString(),
      message: message ?? code.name,
      details: {'code': code.index, 'readableErrorCode': code.name},
    );
  }

  /// Simulate purchase cancelled by user (PurchasesErrorCode.purchaseCancelledError)
  void simulatePurchaseCancelled() {
    errorToThrow = createRevenueCatError(
      PurchasesErrorCode.purchaseCancelledError,
      'Purchase was cancelled',
    );
  }

  /// Simulate payment pending (iOS Ask to Buy) (PurchasesErrorCode.paymentPendingError)
  void simulatePaymentPending() {
    errorToThrow = createRevenueCatError(
      PurchasesErrorCode.paymentPendingError,
      'Payment pending parental approval',
    );
  }

  /// Simulate store problem (PurchasesErrorCode.storeProblemError)
  void simulateStoreProblem([String message = 'App Store error']) {
    errorToThrow = createRevenueCatError(
      PurchasesErrorCode.storeProblemError,
      message,
    );
  }

  /// Simulate network error (PurchasesErrorCode.networkError)
  void simulateNetworkError([String message = 'Network error']) {
    errorToThrow = createRevenueCatError(
      PurchasesErrorCode.networkError,
      message,
    );
  }

  /// Simulate purchase not allowed (PurchasesErrorCode.purchaseNotAllowedError)
  void simulatePurchaseNotAllowed([String message = 'Purchases not allowed']) {
    errorToThrow = createRevenueCatError(
      PurchasesErrorCode.purchaseNotAllowedError,
      message,
    );
  }

  /// Simulate product not available (PurchasesErrorCode.productNotAvailableForPurchaseError)
  void simulateProductNotAvailable([String message = 'Product not available']) {
    errorToThrow = createRevenueCatError(
      PurchasesErrorCode.productNotAvailableForPurchaseError,
      message,
    );
  }

  /// Simulate configuration error (PurchasesErrorCode.configurationError)
  void simulateConfigurationError([String message = 'Configuration error']) {
    errorToThrow = createRevenueCatError(
      PurchasesErrorCode.configurationError,
      message,
    );
  }

  // ---------------------------------------------------------------------------
  // CustomerInfo Stream
  // ---------------------------------------------------------------------------

  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  /// Emit a CustomerInfo update to all registered listeners
  void emitCustomerInfo(CustomerInfo info) {
    _customerInfoController.add(info);
    _customerInfo = info;
  }

  // ---------------------------------------------------------------------------
  // Reset & Dispose
  // ---------------------------------------------------------------------------

  /// Reset all state and counters to defaults
  void reset() {
    _isConfigured = true;
    _isPro = false;
    _customerInfo = null;
    _offerings = null;
    _entitlements.clear();
    initializeCallCount = 0;
    isProCallCount = 0;
    hasEntitlementCallCount = 0;
    getCustomerInfoCallCount = 0;
    getOfferingsCallCount = 0;
    purchasePackageCallCount = 0;
    restorePurchasesCallCount = 0;
    showPaywallCallCount = 0;
    showPaywallIfNeededCallCount = 0;
    showCustomerCenterCallCount = 0;
    identifyUserCallCount = 0;
    logOutCallCount = 0;
    lastIdentifiedUserId = null;
    lastPurchasedPackage = null;
    lastCheckedEntitlement = null;
    purchaseResult = true;
    restoreResult = false;
    paywallResult = false;
    showPaywallDelay = null;
    errorToThrow = null;
    methodErrors.clear();
  }

  /// Dispose the stream controller to prevent leaks
  void dispose() {
    _customerInfoController.close();
  }

  // ---------------------------------------------------------------------------
  // ISubscriptionService Implementation
  // ---------------------------------------------------------------------------

  @override
  bool get isConfigured => _isConfigured;

  @override
  Stream<CustomerInfo>? get customerInfoStream {
    if (!_isConfigured) return null;
    return _customerInfoController.stream;
  }

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    final error = _getError('initialize');
    if (error != null) throw error;
    _isConfigured = true;
  }

  @override
  Future<bool> isPro() async {
    return hasEntitlement('pro');
  }

  // ---------------------------------------------------------------------------
  // Multi-tier Entitlements
  // ---------------------------------------------------------------------------

  /// Map of entitlement IDs to their active status
  /// Default: only 'pro' is checked, controlled by _isPro
  final Map<String, bool> _entitlements = {};

  /// Set a specific entitlement's active status
  void setEntitlement(String entitlementId, bool active) {
    _entitlements[entitlementId] = active;
  }

  /// Number of times hasEntitlement() was called
  @visibleForTesting
  int hasEntitlementCallCount = 0;

  /// Last entitlement ID passed to hasEntitlement()
  @visibleForTesting
  String? lastCheckedEntitlement;

  @override
  Future<bool> hasEntitlement(String entitlementId) async {
    hasEntitlementCallCount++;
    lastCheckedEntitlement = entitlementId;
    if (!_isConfigured) return false;
    final error = _getError('hasEntitlement');
    if (error != null) throw error;
    // Check custom entitlements first, fall back to _isPro for 'pro'
    if (_entitlements.containsKey(entitlementId)) {
      return _entitlements[entitlementId]!;
    }
    return entitlementId == 'pro' ? _isPro : false;
  }

  @override
  Future<CustomerInfo?> getCustomerInfo() async {
    getCustomerInfoCallCount++;
    if (!_isConfigured) return null;
    final error = _getError('getCustomerInfo');
    if (error != null) throw error;
    return _customerInfo;
  }

  @override
  Future<Offerings?> getOfferings() async {
    getOfferingsCallCount++;
    if (!_isConfigured) return null;
    final error = _getError('getOfferings');
    if (error != null) throw error;
    return _offerings;
  }

  @override
  Future<bool> purchasePackage(Package package) async {
    purchasePackageCallCount++;
    lastPurchasedPackage = package;
    final error = _getError('purchasePackage');
    if (error != null) throw error;
    if (purchaseResult) _isPro = true;
    return purchaseResult;
  }

  @override
  Future<bool> restorePurchases() async {
    restorePurchasesCallCount++;
    if (!_isConfigured) return false;
    final error = _getError('restorePurchases');
    if (error != null) throw error;
    if (restoreResult) _isPro = true;
    return restoreResult;
  }

  @override
  Future<bool> showPaywall() async {
    showPaywallCallCount++;
    if (showPaywallDelay != null) {
      await Future<void>.delayed(showPaywallDelay!);
    }
    if (!_isConfigured) return false;
    final error = _getError('showPaywall');
    if (error != null) throw error;
    if (paywallResult) _isPro = true;
    return paywallResult;
  }

  @override
  Future<bool> showPaywallIfNeeded() async {
    showPaywallIfNeededCallCount++;
    if (!_isConfigured) return false;
    if (_isPro) return true; // Already pro, no paywall needed
    final error = _getError('showPaywallIfNeeded');
    if (error != null) throw error;
    if (paywallResult) _isPro = true;
    return paywallResult;
  }

  @override
  Future<void> showCustomerCenter() async {
    showCustomerCenterCallCount++;
    if (!_isConfigured) return;
    final error = _getError('showCustomerCenter');
    if (error != null) throw error;
  }

  @override
  void addCustomerInfoListener(void Function(CustomerInfo) listener) {
    _customerInfoController.stream.listen(listener);
  }

  @override
  void removeCustomerInfoListener(void Function(CustomerInfo) listener) {
    // In mock, listeners are managed via stream controller
    // Real implementation would remove from RevenueCat SDK
  }

  @override
  Future<void> identifyUser(String userId) async {
    identifyUserCallCount++;
    lastIdentifiedUserId = userId;
    if (!_isConfigured) return;
    final error = _getError('identifyUser');
    if (error != null) throw error;
  }

  @override
  Future<void> logOut() async {
    logOutCallCount++;
    final error = _getError('logOut');
    if (error != null) throw error;
    _isPro = false;
  }
}
