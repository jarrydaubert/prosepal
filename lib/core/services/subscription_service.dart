import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'log_service.dart';
import '../interfaces/subscription_interface.dart';

/// RevenueCat subscription service implementation
///
/// Handles in-app purchases, subscription status, and paywall presentation.
/// Uses native RevenueCat SDK with Test Store for development.
///
/// ## Environment Configuration
/// - Test Store (default in debug): Instant purchases, no sandbox accounts
/// - Production: Real App Store/Play Store transactions
///
/// ## Usage
/// ```dart
/// final service = SubscriptionService();
/// await service.initialize();
/// if (await service.isPro()) {
///   // User has pro access
/// }
/// ```
class SubscriptionService implements ISubscriptionService {
  // ==========================================================================
  // RevenueCat API Keys (REQUIRED via dart-define)
  // ==========================================================================
  //
  // These are PUBLIC keys (safe to include in app) - they only allow client-side operations.
  // Keys MUST be provided via dart-define to prevent accidental use of wrong keys.
  //
  // REQUIRED FOR BUILDS:
  //   flutter build ios --dart-define=REVENUECAT_IOS_KEY=appl_xxx
  //   flutter build android --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
  //
  // FOR TESTING:
  //   flutter run --dart-define=REVENUECAT_USE_TEST_STORE=true \
  //               --dart-define=REVENUECAT_TEST_STORE_KEY=test_xxx
  //
  // Get keys from: RevenueCat Dashboard > Project Settings > API Keys
  // ==========================================================================

  // Production API Keys - MUST be provided via dart-define for release builds
  static const String _iosApiKey = String.fromEnvironment('REVENUECAT_IOS_KEY');
  static const String _androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );

  // Test Store Key (for automated testing only)
  // Dashboard: Project Settings > Apps > Test Store
  // WARNING: Test Store in production WILL crash!
  static const String _testStoreKey = String.fromEnvironment(
    'REVENUECAT_TEST_STORE_KEY',
  );

  // Use Test Store for automated testing (not device testing)
  static const bool _useTestStore = bool.fromEnvironment(
    'REVENUECAT_USE_TEST_STORE',
  );

  static const String _entitlementId = 'pro';

  /// Check if current platform supports RevenueCat
  static bool get _isPlatformSupported {
    // RevenueCat Flutter SDK supports iOS and Android
    // Web and desktop require different payment solutions
    return Platform.isIOS || Platform.isAndroid;
  }

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

  @override
  bool get isConfigured => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check platform support first
    if (!_isPlatformSupported) {
      Log.warning('RevenueCat not supported on this platform', {
        'platform': Platform.operatingSystem,
      });
      return;
    }

    // CRITICAL: Block Test Store in release builds
    // Test Store will crash in production - this prevents accidental submission
    if (isUsingTestStore && kReleaseMode) {
      Log.error(
        'FATAL: Test Store cannot be used in release builds',
        'Configuration error',
      );
      throw StateError(
        'RevenueCat Test Store is enabled in release mode. '
        'This will crash in production. Remove REVENUECAT_USE_TEST_STORE flag.',
      );
    }

    final apiKey = _activeApiKey;

    if (apiKey.isEmpty) {
      final keyName = Platform.isIOS
          ? 'REVENUECAT_IOS_KEY'
          : 'REVENUECAT_ANDROID_KEY';
      if (kReleaseMode) {
        Log.error(
          'FATAL: RevenueCat API key not provided',
          'Missing $keyName dart-define',
        );
        throw StateError(
          'RevenueCat API key not provided. '
          'Set via: flutter build ${Platform.isIOS ? "ios" : "apk"} '
          '--dart-define=$keyName=your_key',
        );
      }
      Log.warning('RevenueCat API key not provided - subscriptions disabled', {
        'hint': 'Set $keyName via dart-define for production builds',
      });
      return;
    }

    // Only enable debug logging in debug mode
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    final config = PurchasesConfiguration(apiKey);
    await Purchases.configure(config);

    _isInitialized = true;

    // Sync purchases to transfer any subscriptions to the current RC user.
    // This prevents orphaned anonymous users and inflated customer counts.
    // - Android: Google Play subscriptions follow the Google account
    // - iOS: App Store receipts are device-bound but still need sync after reinstall
    try {
      await Purchases.syncPurchases();
      Log.info('RevenueCat: Purchases synced');
    } catch (e) {
      Log.warning('RevenueCat: Sync failed', {'error': '$e'});
    }

    Log.info('RevenueCat initialized', {
      'platform': Platform.isIOS ? 'iOS' : 'Android',
      'testStore': isUsingTestStore,
    });
  }

  @override
  Future<bool> isPro() async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(_entitlementId);
    } catch (e) {
      Log.error('Error checking pro status', e);
      return false;
    }
  }

  @override
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_isInitialized) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      Log.error('Error getting customer info', e);
      return null;
    }
  }

  @override
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      Log.error('Error getting offerings', e);
      return null;
    }
  }

  @override
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final hasPro = result.customerInfo.entitlements.active.containsKey(
        _entitlementId,
      );
      Log.info('Purchase completed', {'hasPro': hasPro});
      return hasPro;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        Log.info('Purchase cancelled by user');
      } else {
        Log.error('Purchase error', e);
      }
      return false;
    } catch (e) {
      Log.error('Purchase error', e);
      return false;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    if (!_isInitialized) {
      Log.warning('RevenueCat not initialized - cannot restore');
      return false;
    }
    try {
      final customerInfo = await Purchases.restorePurchases();
      final hasPro = customerInfo.entitlements.active.containsKey(
        _entitlementId,
      );
      Log.info('Restore completed', {'hasPro': hasPro});
      return hasPro;
    } catch (e) {
      Log.error('Error restoring purchases', e);
      return false;
    }
  }

  @override
  Future<bool> showPaywall() async {
    if (!_isInitialized) {
      Log.warning('RevenueCat not initialized - cannot show paywall');
      return false;
    }

    try {
      final offerings = await Purchases.getOfferings();
      final packageCount = offerings.current?.availablePackages.length ?? 0;
      Log.info('Paywall offerings loaded', {'packages': packageCount});

      if (offerings.current == null ||
          offerings.current!.availablePackages.isEmpty) {
        Log.warning('No offerings available');
        return false;
      }

      final result = await RevenueCatUI.presentPaywall();
      final success =
          result == PaywallResult.purchased || result == PaywallResult.restored;
      Log.info('Paywall result', {'result': result.name, 'success': success});
      return success;
    } catch (e) {
      Log.error('Error showing paywall', e);
      return false;
    }
  }

  @override
  Future<bool> showPaywallIfNeeded() async {
    if (!_isInitialized) {
      Log.warning('RevenueCat not initialized - cannot show paywall');
      return false;
    }

    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(_entitlementId);
      final success =
          result == PaywallResult.purchased || result == PaywallResult.restored;
      Log.info('PaywallIfNeeded result', {
        'result': result.name,
        'success': success,
      });
      return success;
    } catch (e) {
      Log.error('Error showing paywall', e);
      return false;
    }
  }

  @override
  Future<void> showCustomerCenter() async {
    if (!_isInitialized) {
      Log.warning('RevenueCat not initialized - cannot show customer center');
      return;
    }
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      Log.error('Error showing customer center', e);
    }
  }

  @override
  void addCustomerInfoListener(void Function(CustomerInfo) listener) {
    if (!_isInitialized) return;
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  @override
  void removeCustomerInfoListener(void Function(CustomerInfo) listener) {
    if (!_isInitialized) return;
    Purchases.removeCustomerInfoUpdateListener(listener);
  }

  @override
  Future<void> identifyUser(String userId) async {
    if (!_isInitialized) {
      Log.warning('RevenueCat not initialized, skipping identify');
      return;
    }
    try {
      final currentAppUserId = await Purchases.appUserID;
      final result = await Purchases.logIn(userId);
      final newAppUserId = await Purchases.appUserID;
      final hasPro = result.customerInfo.entitlements.active.containsKey(
        _entitlementId,
      );

      Log.info('RevenueCat user identified', {
        'previousId': _truncateId(currentAppUserId),
        'targetId': _truncateId(userId),
        'newId': _truncateId(newAppUserId),
        'created': result.created,
        'hasPro': hasPro,
      });

      // Sync purchases to ensure entitlements are fresh after login
      // This is especially important on Android for purchase restoration
      try {
        await Purchases.syncPurchases();
        Log.info('RevenueCat purchases synced after identify');
      } catch (syncError) {
        // Non-fatal: sync may fail if no purchases exist
        Log.warning('Purchase sync after identify failed', {
          'error': '$syncError',
        });
      }

      // Set user ID in Crashlytics for crash correlation
      await Log.setUserId(userId);
    } catch (e) {
      Log.error('Error identifying user', e);
    }
  }

  @override
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      await Log.clearUserId();
      Log.info('RevenueCat user logged out');
    } catch (e) {
      Log.error('Error logging out', e);
    }
  }

  /// Truncate ID for logging (privacy)
  static String _truncateId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 4)}';
  }
}
