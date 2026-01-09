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
import 'package:screen_secure/screen_secure.dart';
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
import 'core/services/force_update_service.dart';
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
Future<void> _initializeApp() async {
  final init = InitService.instance;

  // Initialize Firebase first for error reporting
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    init.firebaseReady();

    // Initialize Crashlytics (only in release mode)
    if (!kDebugMode) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Apply user's analytics preference (GDPR consent)
      try {
        final prefs = await SharedPreferences.getInstance();
        final analyticsEnabled =
            prefs.getBool(PreferenceKeys.analyticsEnabled) ?? true;
        await FirebaseAnalytics.instance
            .setAnalyticsCollectionEnabled(analyticsEnabled);
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(analyticsEnabled);
      } catch (_) {
        // Default to enabled if prefs not available
      }
    }
  } catch (e) {
    Log.error('Firebase initialization failed', e);
    init.firebaseFailed('$e');
  }

  // Activate Firebase App Check (only if Firebase initialized)
  if (init.isFirebaseReady) {
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
        providerApple: const AppleAppAttestProvider(),
      );
    } catch (e) {
      Log.warning('Firebase App Check activation failed', {'error': '$e'});
    }

    // Check for force update (only in release mode, requires Firebase)
    if (!kDebugMode) {
      try {
        final forceUpdateService = ForceUpdateService();
        await forceUpdateService.initialize();
        final updateStatus = await forceUpdateService.checkForUpdate();

        if (updateStatus == UpdateStatus.forceUpdateRequired) {
          Log.warning('Force update required - blocking app');
          FlutterNativeSplash.remove();
          runApp(ForceUpdateScreen(storeUrl: forceUpdateService.storeUrl));
          return;
        }
      } catch (e) {
        Log.warning('Force update check failed', {'error': '$e'});
        // Continue - fail open
      }
    }
  }

  // Validate configuration early (throws in release if missing)
  AppConfig.validate();

  // Initialize Supabase (critical for auth and data)
  if (AppConfig.hasSupabaseConfig) {
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
  } else {
    Log.warning('Supabase skipped: configuration not provided');
    init.supabaseFailed('Configuration not provided');
  }

  // Check for critical failures before continuing
  if (!init.isCriticalReady) {
    Log.error('Critical service initialization failed', {
      'firebase': init.isFirebaseReady,
      'supabase': init.isSupabaseReady,
      'error': init.criticalError,
    });

    // Remove splash and show error screen
    FlutterNativeSplash.remove();

    runApp(
      InitErrorScreen(
        errorMessage: init.criticalError ?? 'Unknown error',
        onRetry: () async {
          // Reset and retry initialization
          init.reset();
          await _initializeApp();
        },
      ),
    );
    return;
  }

  // Verify edge functions are deployed (non-blocking, just logs warnings)
  if (init.isSupabaseReady) {
    unawaited(SupabaseAuthProvider().verifyEdgeFunctions());
  }

  // Initialize RevenueCat (non-critical - app works without subscriptions)
  final subscriptionService = SubscriptionService();
  try {
    await subscriptionService.initialize();
    init.revenueCatReady();
    final isPro = await subscriptionService.isPro();
    Log.info('App launched', {'initialProStatus': isPro});
  } catch (e) {
    Log.error('RevenueCat initialization failed', e);
    init.revenueCatFailed('$e');
  }

  // Enable screenshot prevention in release builds
  if (!kDebugMode) {
    try {
      await ScreenSecure.init(screenshotBlock: true, screenRecordBlock: true);
      Log.info('Screen security enabled');
    } catch (e) {
      Log.warning('Screen security init failed', {'error': '$e'});
    }
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Record first launch for review timing
  final reviewService = ReviewService(prefs);
  await reviewService.recordFirstLaunchIfNeeded();

  // Pre-initialize OAuth providers for faster sign-in UX
  final authService = AuthService(
    supabaseAuth: SupabaseAuthProvider(),
    appleAuth: AppleAuthProvider(),
    googleAuth: GoogleAuthProvider(),
  );
  unawaited(authService.initializeProviders());

  // Create router with route guards (prevents deep link bypass)
  final router = createAppRouter(prefs);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        subscriptionServiceProvider.overrideWithValue(subscriptionService),
        authServiceProvider.overrideWithValue(authService),
      ],
      child: ProsepalApp(router: router),
    ),
  );
}
