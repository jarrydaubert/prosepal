import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/config/app_config.dart';
import 'core/config/preference_keys.dart';
import 'core/providers/providers.dart';
import 'core/services/apple_auth_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/google_auth_provider.dart';
import 'core/services/init_service.dart';
import 'core/services/log_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/services/review_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/supabase_auth_provider.dart';
import 'firebase_options.dart';

void main() async {
  // Preserve native splash until we're ready
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Lock to portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run initialization and handle critical failures
  await _initializeApp();
}

/// Initialize all services and launch app.
/// Shows error screen if critical services fail.
///
/// Optimized startup flow:
/// 1. Firebase first (required for crash reporting + remote config)
/// 2. App Check + Remote Config in parallel (both need Firebase)
/// 3. Force update check (blocking - must happen before any user interaction)
/// 4. Supabase + RevenueCat + SharedPrefs in parallel (independent services)
Future<void> _initializeApp() async {
  final init = InitService.instance;
  final stopwatch = Stopwatch()..start();

  // =========================================================================
  // PHASE 1: Firebase (required for crash reporting and remote config)
  // =========================================================================
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    init.firebaseReady();
    Log.info('Firebase initialized', {'ms': stopwatch.elapsedMilliseconds});

    // Setup Crashlytics error handlers (sync, no await needed)
    if (!kDebugMode) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } on Exception catch (e) {
    Log.error('Firebase initialization failed', e);
    init.firebaseFailed('$e');
  }

  // =========================================================================
  // PHASE 2: Config validation + SharedPrefs (sync, fast)
  // =========================================================================
  AppConfig.validate();
  AppConfig.assertNoTestStoreInRelease();

  // Get SharedPreferences first (fast, local) - needed for router
  final prefs = await SharedPreferences.getInstance();

  // Auto-detect spelling preference from device locale if not already set
  if (!prefs.containsKey(PreferenceKeys.spellingPreference)) {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final isUkLocale =
        locale.countryCode == 'GB' ||
        locale.countryCode == 'AU' ||
        locale.countryCode == 'NZ' ||
        locale.countryCode == 'IE';
    final spelling = isUkLocale ? 'uk' : 'us';
    await prefs.setString(PreferenceKeys.spellingPreference, spelling);
    Log.info('Spelling auto-detected', {
      'locale': locale.toString(),
      'spelling': spelling,
    });
  }

  Log.info('Phase 2 complete', {'ms': stopwatch.elapsedMilliseconds});

  // =========================================================================
  // PHASE 3: Show Flutter splash IMMEDIATELY, init services in background
  // This eliminates the ~2s grey native splash while Remote Config loads
  // =========================================================================
  final subscriptionService = SubscriptionService();
  final initStatusNotifier = InitStatusNotifier();

  // Create auth service early
  final authService = AuthService(
    supabaseAuth: SupabaseAuthProvider(),
    appleAuth: AppleAuthProvider(),
    googleAuth: GoogleAuthProvider(),
  );

  // Create router and container
  final router = createAppRouter(prefs);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      subscriptionServiceProvider.overrideWithValue(subscriptionService),
      authServiceProvider.overrideWithValue(authService),
      initStatusProvider.overrideWith((ref) => initStatusNotifier),
    ],
  );

  // Remove native splash and show Flutter splash immediately
  FlutterNativeSplash.remove();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: ProsepalApp(router: router),
    ),
  );

  // Continue initialization in background
  Log.info('App shown, continuing init in background');

  // Start RevenueCat timeout timer (5 seconds)
  const revenueCatTimeout = Duration(seconds: 5);
  Timer? revenueCatTimeoutTimer;
  revenueCatTimeoutTimer = Timer(revenueCatTimeout, () {
    if (!init.isRevenueCatReady) {
      Log.warning('RevenueCat init timed out', {'timeout': '5s'});
      initStatusNotifier.markTimedOut();
    }
  });

  // Run all background services in parallel
  unawaited(
    Future.wait([
      // App Check (non-blocking)
      if (init.isFirebaseReady) _initAppCheck(),
      // Remote Config + force update check (in background, checked by splash screen)
      if (init.isFirebaseReady && !kDebugMode)
        _initRemoteConfigAndCheckForceUpdate(initStatusNotifier),
      // Supabase
      _initSupabase(init).then((_) {
        if (init.isSupabaseReady) {
          initStatusNotifier.markSupabaseReady();
        } else {
          // Mark as "ready" even on failure so splash can proceed
          // (app handles missing Supabase gracefully)
          Log.warning('Supabase init failed, marking ready anyway');
          initStatusNotifier.markSupabaseReady();
        }
      }),
      // RevenueCat
      _initRevenueCat(subscriptionService, init).then((_) {
        revenueCatTimeoutTimer?.cancel();
        if (init.isRevenueCatReady) {
          initStatusNotifier.markRevenueCatReady();
        }
      }),
    ]).then((_) {
      Log.info('Background init complete', {
        'ms': stopwatch.elapsedMilliseconds,
      });

      // Check for critical failures
      if (!init.isCriticalReady) {
        Log.error('Critical service initialization failed', {
          'firebase': init.isFirebaseReady,
          'supabase': init.isSupabaseReady,
          'error': init.criticalError,
        });
        initStatusNotifier.setError(
          init.criticalError ?? 'Service init failed',
        );
      }
    }),
  );

  // =========================================================================
  // PHASE 4: Post-init setup (non-blocking)
  // =========================================================================
  final reviewService = ReviewService(prefs);
  unawaited(reviewService.recordFirstLaunchIfNeeded());
  unawaited(_applyAnalyticsPreference(prefs));
  unawaited(authService.initializeProviders());
}

// =============================================================================
// Helper functions for parallel initialization
// =============================================================================

/// Initialize Firebase App Check
Future<void> _initAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerApple: const AppleAppAttestProvider(),
    );
  } on Exception catch (e) {
    Log.warning('Firebase App Check activation failed', {'error': '$e'});
  }
}

/// Initialize Remote Config and check for force update
/// Updates InitStatusNotifier with force update state (checked by splash screen)
Future<void> _initRemoteConfigAndCheckForceUpdate(
  InitStatusNotifier notifier,
) async {
  try {
    final remoteConfig = RemoteConfigService.instance;
    await remoteConfig.initialize();
    notifier.markRemoteConfigReady();

    if (await remoteConfig.isUpdateRequired()) {
      Log.warning('Force update required');
      notifier.setForceUpdate(remoteConfig.storeUrl);
    }
  } on Exception catch (e) {
    Log.warning('Remote Config init failed', {'error': '$e'});
    // Continue - fail open (don't require update if we can't check)
    notifier.markRemoteConfigReady();
  }
}

/// Initialize Supabase
Future<void> _initSupabase(InitService init) async {
  Log.info('Supabase init starting', {
    'hasConfig': AppConfig.hasSupabaseConfig,
    'urlPresent': AppConfig.supabaseUrl.isNotEmpty,
    'keyPresent': AppConfig.supabaseAnonKey.isNotEmpty,
  });

  if (!AppConfig.hasSupabaseConfig) {
    Log.warning('Supabase skipped: configuration not provided');
    init.supabaseFailed('Configuration not provided');
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    Log.info('Supabase initialized successfully');
    init.supabaseReady();
  } on Exception catch (e) {
    Log.error('Supabase initialization failed', e);
    init.supabaseFailed('$e');
  }
}

/// Initialize RevenueCat
Future<void> _initRevenueCat(
  SubscriptionService subscriptionService,
  InitService init,
) async {
  try {
    await subscriptionService.initialize();
    init.revenueCatReady();
  } on Exception catch (e) {
    Log.error('RevenueCat initialization failed', e);
    init.revenueCatFailed('$e');
  }
}

/// Apply GDPR analytics preference
Future<void> _applyAnalyticsPreference(SharedPreferences prefs) async {
  try {
    final analyticsEnabled =
        prefs.getBool(PreferenceKeys.analyticsEnabled) ?? true;
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
      analyticsEnabled,
    );
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      analyticsEnabled,
    );
  } on Exception catch (e) {
    Log.warning('Failed to apply analytics preference', {'error': '$e'});
  }
}
