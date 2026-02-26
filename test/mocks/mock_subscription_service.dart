import 'dart:async';

import 'package:prosepal/core/interfaces/subscription_interface.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Mock implementation of ISubscriptionService for testing
///
/// Supports:
/// - Configurable state (isPro, offerings, customerInfo)
/// - Call tracking and parameter capture
/// - Global and per-method error simulation
/// - CustomerInfo listener stream for state-management tests
///
/// ## Usage
/// ```dart
/// final mockSub = MockSubscriptionService();
/// mockSub.setIsPro(true);
/// mockSub.purchaseResult = true;
/// mockSub.methodErrors['restorePurchases'] = Exception('Network error');
/// ```
class MockSubscriptionService implements ISubscriptionService {
  // Configurable state for tests
  bool _isConfigured = true;
  bool _isPro = false;
  CustomerInfo? _customerInfo;
  Offerings? _offerings;

  // Configuration methods for tests
  void setConfigured(bool value) => _isConfigured = value;
  void setIsPro(bool value) => _isPro = value;
  void setCustomerInfo(CustomerInfo? value) => _customerInfo = value;
  void setOfferings(Offerings? value) => _offerings = value;

  // Tracking for test verification
  int initializeCallCount = 0;
  int isProCallCount = 0;
  int getCustomerInfoCallCount = 0;
  int getOfferingsCallCount = 0;
  int purchasePackageCallCount = 0;
  int restorePurchasesCallCount = 0;
  int showPaywallCallCount = 0;
  int showPaywallIfNeededCallCount = 0;
  int showCustomerCenterCallCount = 0;
  int identifyUserCallCount = 0;
  int logOutCallCount = 0;

  String? lastIdentifiedUserId;
  Package? lastPurchasedPackage;

  // Results to return
  bool purchaseResult = true;
  bool restoreResult = false;
  bool paywallResult = false;

  /// Alias for paywallResult - controls showPaywall() return value
  set showPaywallResult(bool value) => paywallResult = value;
  bool get showPaywallResult => paywallResult;

  /// Delay before showPaywall completes (for testing loading states)
  Duration? showPaywallDelay;

  /// Error to throw specifically for restore (shorthand for methodErrors)
  set restoreError(Exception? e) {
    if (e != null) {
      methodErrors['restorePurchases'] = e;
    } else {
      methodErrors.remove('restorePurchases');
    }
  }

  // Error simulation
  Exception? errorToThrow;

  /// Per-method errors - takes precedence over [errorToThrow]
  /// Keys: 'initialize', 'isPro', 'getCustomerInfo', 'getOfferings',
  /// 'purchasePackage', 'restorePurchases', 'showPaywall', 'showPaywallIfNeeded',
  /// 'showCustomerCenter', 'identifyUser', 'logOut'
  final Map<String, Exception> methodErrors = {};

  Exception? _getError(String method) {
    return methodErrors[method] ?? errorToThrow;
  }

  // CustomerInfo listener stream
  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  /// Emit a CustomerInfo update to all registered listeners
  void emitCustomerInfo(CustomerInfo info) {
    _customerInfoController.add(info);
    _customerInfo = info;
  }

  void reset() {
    _isConfigured = true;
    _isPro = false;
    _customerInfo = null;
    _offerings = null;
    initializeCallCount = 0;
    isProCallCount = 0;
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
    purchaseResult = true;
    restoreResult = false;
    paywallResult = false;
    showPaywallDelay = null;
    errorToThrow = null;
    methodErrors.clear();
  }

  void dispose() {
    _customerInfoController.close();
  }

  @override
  bool get isConfigured => _isConfigured;

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    final error = _getError('initialize');
    if (error != null) throw error;
    _isConfigured = true;
  }

  @override
  Future<bool> isPro() async {
    isProCallCount++;
    if (!_isConfigured) return false;
    final error = _getError('isPro');
    if (error != null) throw error;
    return _isPro;
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
