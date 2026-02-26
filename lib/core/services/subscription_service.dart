import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../interfaces/subscription_interface.dart';
import 'log_service.dart';

/// RevenueCat subscription service implementation
///
/// Handles in-app purchases, subscription status, and paywall presentation.
/// Uses native RevenueCat SDK with Test Store for development.
///
/// ## Environment Configuration
/// API keys are provided via dart-define through AppConfig.
/// See `.env.example` for all required variables.
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
  static const String _entitlementId = 'pro';
  static const String _anonymousAppUserIdKey =
      'revenuecat_anonymous_app_user_id';

  /// Check if current platform supports RevenueCat
  /// RevenueCat Flutter SDK supports iOS and Android
  /// Web and desktop require different payment solutions
  static bool get _isPlatformSupported => Platform.isIOS || Platform.isAndroid;

  /// Get the appropriate API key based on platform and environment
  static String get _activeApiKey {
    // If Test Store is explicitly enabled and key is provided, use it
    if (AppConfig.useRevenueCatTestStore &&
        AppConfig.revenueCatTestStoreKey.isNotEmpty) {
      return AppConfig.revenueCatTestStoreKey;
    }
    // Otherwise use platform-specific production key
    return Platform.isIOS
        ? AppConfig.revenueCatIosKey
        : AppConfig.revenueCatAndroidKey;
  }

  /// Check if using Test Store (for logging/debugging)
  static bool get isUsingTestStore =>
      AppConfig.useRevenueCatTestStore &&
      AppConfig.revenueCatTestStoreKey.isNotEmpty;

  bool _isInitialized = false;
  final _uuid = const Uuid();

  /// Stream controller for customer info updates
  StreamController<CustomerInfo>? _customerInfoController;

  @override
  bool get isConfigured => _isInitialized;

  @override
  Stream<CustomerInfo>? get customerInfoStream {
    if (!_isInitialized) return null;
    _customerInfoController ??= StreamController<CustomerInfo>.broadcast(
      onListen: () {
        // Set up the SDK listener when first subscriber attaches
        Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);
      },
      onCancel: () {
        // Clean up when no more subscribers
        Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdate);
        _customerInfoController?.close();
        _customerInfoController = null;
      },
    );
    return _customerInfoController!.stream;
  }

  void _onCustomerInfoUpdate(CustomerInfo info) {
    _customerInfoController?.add(info);
  }

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

    // Use warn level even in debug - debug level logs raw JWT receipts
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.warn);
    }

    // Use a stable App User ID at configure time:
    // - signed-in Supabase user ID when available
    // - otherwise a persisted anonymous ID (prevents synthetic "new users" on logout)
    final signedInUserId = _currentSupabaseUserId();
    final initialAppUserId =
        signedInUserId ?? await _getOrCreateAnonymousAppUserId();

    // StoreKit2 is the default in purchases_flutter 9.x
    final config = PurchasesConfiguration(apiKey)..appUserID = initialAppUserId;
    await Purchases.configure(config);

    _isInitialized = true;

    try {
      final configuredAppUserId = await Purchases.appUserID;
      final isAnonymous = await Purchases.isAnonymous;
      Log.info('RevenueCat configured identity', {
        'appUserId': _truncateId(configuredAppUserId),
        'isAnonymous': isAnonymous,
      });
    } on PlatformException catch (e) {
      Log.warning('RevenueCat identity check failed after configure', {
        'error': '$e',
      });
    }

    // Sync purchases to transfer any subscriptions to the current RC user.
    // This prevents orphaned anonymous users and inflated customer counts.
    // - Android: Google Play subscriptions follow the Google account
    // - iOS: App Store receipts are device-bound but still need sync after reinstall
    try {
      await Purchases.syncPurchases();
      Log.info('RevenueCat: Purchases synced');
    } on PlatformException catch (e) {
      Log.warning('RevenueCat: Sync failed', {'error': '$e'});
    }

    Log.info('RevenueCat initialized', {
      'platform': Platform.isIOS ? 'iOS' : 'Android',
      'testStore': isUsingTestStore,
      'configuredAs': signedInUserId == null ? 'anonymous' : 'authenticated',
    });
  }

  @override
  Future<bool> isPro() async => hasEntitlement(_entitlementId);

  @override
  Future<bool> hasEntitlement(String entitlementId) async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(entitlementId);
    } on PlatformException catch (e) {
      Log.error('Error checking entitlement', e, null, {
        'entitlementId': entitlementId,
      });
      return false;
    }
  }

  @override
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_isInitialized) return null;
    try {
      return await Purchases.getCustomerInfo();
    } on PlatformException catch (e) {
      Log.error('Error getting customer info', e);
      return null;
    }
  }

  @override
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) return null;
    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
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
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        Log.info('Purchase cancelled by user');
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        // iOS Ask to Buy: purchase pending parental approval
        Log.info('Purchase pending approval (Ask to Buy)');
        // Return false but don't log as error - this is expected for children
      } else {
        Log.error('Purchase error', e, null, {'errorCode': errorCode.name});
      }
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
    } on PlatformException catch (e) {
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
    } on PlatformException catch (e) {
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
    } on PlatformException catch (e) {
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
    } on PlatformException catch (e) {
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
      if (currentAppUserId == userId) {
        Log.info('RevenueCat user already identified', {
          'userId': _truncateId(userId),
        });
        await Log.setUserId(userId);
        return;
      }

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
      } on PlatformException catch (syncError) {
        // Non-fatal: sync may fail if no purchases exist
        Log.warning('Purchase sync after identify failed', {
          'error': '$syncError',
        });
      }

      // Set user ID in Crashlytics for crash correlation
      await Log.setUserId(userId);
    } on PlatformException catch (e) {
      Log.error('Error identifying user', e);
    }
  }

  @override
  Future<void> logOut() async {
    try {
      // Avoid Purchases.logOut() random-user generation. It creates a fresh
      // anonymous ID each time, inflating RevenueCat "new users" metrics.
      final previousAppUserId = await Purchases.appUserID;
      final anonymousId = await _getOrCreateAnonymousAppUserId();

      if (previousAppUserId != anonymousId) {
        final result = await Purchases.logIn(anonymousId);
        Log.info('RevenueCat switched to anonymous app user', {
          'previousId': _truncateId(previousAppUserId),
          'newId': _truncateId(anonymousId),
          'created': result.created,
        });
      } else {
        Log.info('RevenueCat already on anonymous app user', {
          'appUserId': _truncateId(anonymousId),
        });
      }

      await Log.clearUserId();
      Log.info('RevenueCat user logged out');
    } on PlatformException catch (e) {
      // Some SDK states can reject identity changes when already anonymous.
      // Treat as non-fatal during sign-out/delete flows.
      if (e.code == '22' || (e.message?.contains('anonymous') ?? false)) {
        Log.info(
          'RevenueCat: User already anonymous, skipping identity switch',
        );
        await Log.clearUserId();
      } else {
        Log.error('Error logging out', e);
      }
    }
    // ignore: avoid_catching_errors - SDK not initialized (expected in tests)
    on AssertionError {
      // Ignore
    }
  }

  /// Truncate ID for logging (privacy)
  static String _truncateId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 4)}';
  }

  String? _currentSupabaseUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } on Exception {
      return null;
    }
  }

  Future<String> _getOrCreateAnonymousAppUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_anonymousAppUserIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = 'anon_${_uuid.v4()}';
    await prefs.setString(_anonymousAppUserIdKey, generated);
    return generated;
  }
}
