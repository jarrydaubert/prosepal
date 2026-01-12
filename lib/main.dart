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
import 'core/services/review_service.dart';

import 'core/services/remote_config_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/supabase_auth_provider.dart';
import 'features/error/force_update_screen.dart';
import 'features/error/init_error_screen.dart';
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
  } catch (e) {
    Log.error('Firebase initialization failed', e);
    init.firebaseFailed('$e');
  }

  // =========================================================================
  // PHASE 2: App Check + Remote Config in PARALLEL (both need Firebase)
  // =========================================================================
  if (init.isFirebaseReady) {
    await Future.wait([
      // App Check activation
      _initAppCheck(),
      // Remote Config (includes force update check in release)
      if (!kDebugMode) _initRemoteConfigAndCheckForceUpdate(init),
    ]);
    Log.info('Phase 2 complete', {'ms': stopwatch.elapsedMilliseconds});

    // Check if force update was triggered (returns early from _initializeApp)
    if (_forceUpdateRequired) {
      FlutterNativeSplash.remove();
      runApp(ForceUpdateScreen(storeUrl: _forceUpdateStoreUrl));
      return;
    }
  }

  // =========================================================================
  // PHASE 3: Config validation (sync, fast)
  // =========================================================================
  AppConfig.validate();
  AppConfig.assertNoTestStoreInRelease();

  // =========================================================================
  // PHASE 4: Supabase + RevenueCat + SharedPrefs in PARALLEL
  // =========================================================================
  late final SharedPreferences prefs;
  final subscriptionService = SubscriptionService();

  // Create InitStatusNotifier early so we can update it during init
  final initStatusNotifier = InitStatusNotifier();

  // Start RevenueCat timeout timer (5 seconds)
  // If RevenueCat takes too long, mark as timed out so UI can show fallback
  const revenueCatTimeout = Duration(seconds: 5);
  Timer? revenueCatTimeoutTimer;
  revenueCatTimeoutTimer = Timer(revenueCatTimeout, () {
    if (!init.isRevenueCatReady) {
      Log.warning('RevenueCat init timed out', {'timeout': '5s'});
      initStatusNotifier.markTimedOut();
    }
  });

  await Future.wait([
    // Supabase (critical for auth and data)
    _initSupabase(init).then((_) {
      if (init.isSupabaseReady) {
        initStatusNotifier.markSupabaseReady();
      }
    }),
    // RevenueCat (non-critical - app works without subscriptions)
    _initRevenueCat(subscriptionService, init).then((_) {
      revenueCatTimeoutTimer?.cancel(); // Cancel timeout if init succeeds
      if (init.isRevenueCatReady) {
        initStatusNotifier.markRevenueCatReady();
      }
    }),
    // SharedPreferences (fast, local)
    SharedPreferences.getInstance().then((p) => prefs = p),
  ]);
  Log.info('Phase 4 complete', {'ms': stopwatch.elapsedMilliseconds});

  // Check for critical failures before continuing
  if (!init.isCriticalReady) {
    Log.error('Critical service initialization failed', {
      'firebase': init.isFirebaseReady,
      'supabase': init.isSupabaseReady,
      'error': init.criticalError,
    });

    FlutterNativeSplash.remove();
    runApp(
      InitErrorScreen(
        errorMessage: init.criticalError ?? 'Unknown error',
        onRetry: () async {
          init.reset();
          _forceUpdateRequired = false;
          await _initializeApp();
        },
      ),
    );
    return;
  }

  // =========================================================================
  // PHASE 5: Post-init setup (non-blocking where possible)
  // =========================================================================

  // Record first launch for review timing
  final reviewService = ReviewService(prefs);
  unawaited(reviewService.recordFirstLaunchIfNeeded());

  // Apply GDPR analytics preference (non-blocking)
  unawaited(_applyAnalyticsPreference(prefs));

  // Log final Pro status
  if (init.isRevenueCatReady) {
    final isPro = await subscriptionService.isPro();
    Log.info('App launched', {
      'initialProStatus': isPro,
      'totalInitMs': stopwatch.elapsedMilliseconds,
    });
  } else {
    Log.info('App launched', {
      'initialProStatus': 'unknown (RevenueCat failed)',
      'totalInitMs': stopwatch.elapsedMilliseconds,
    });
  }

  // Pre-initialize OAuth providers for faster sign-in UX
  final authService = AuthService(
    supabaseAuth: SupabaseAuthProvider(),
    appleAuth: AppleAuthProvider(),
    googleAuth: GoogleAuthProvider(),
  );
  unawaited(authService.initializeProviders());

  // Create router with route guards (prevents deep link bypass)
  final router = createAppRouter(prefs);

  // Create single container with all service overrides
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      subscriptionServiceProvider.overrideWithValue(subscriptionService),
      authServiceProvider.overrideWithValue(authService),
      initStatusProvider.overrideWith((ref) => initStatusNotifier),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: ProsepalApp(router: router),
    ),
  );
}

// =============================================================================
// Helper functions for parallel initialization
// =============================================================================

/// Force update state (set by _initRemoteConfigAndCheckForceUpdate)
bool _forceUpdateRequired = false;
String _forceUpdateStoreUrl = '';

/// Initialize Firebase App Check
Future<void> _initAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidPlayIntegrityProvider(),
      providerApple: const AppleAppAttestProvider(),
    );
  } catch (e) {
    Log.warning('Firebase App Check activation failed', {'error': '$e'});
  }
}

/// Initialize Remote Config and check for force update
/// Sets _forceUpdateRequired if update is needed
Future<void> _initRemoteConfigAndCheckForceUpdate(InitService init) async {
  try {
    final remoteConfig = RemoteConfigService.instance;
    await remoteConfig.initialize();

    if (await remoteConfig.isUpdateRequired()) {
      Log.warning('Force update required - blocking app');
      _forceUpdateRequired = true;
      _forceUpdateStoreUrl = remoteConfig.storeUrl;
    }
  } catch (e) {
    Log.warning('Remote Config init failed', {'error': '$e'});
    // Continue - fail open (don't require update if we can't check)
  }
}

/// Initialize Supabase
Future<void> _initSupabase(InitService init) async {
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
    init.supabaseReady();
  } catch (e) {
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
  } catch (e) {
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
  } catch (e) {
    Log.warning('Failed to apply analytics preference', {'error': '$e'});
  }
}
