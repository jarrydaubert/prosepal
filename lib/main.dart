import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Required for AppleProvider/AndroidProvider enums
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/providers/providers.dart';
import 'core/services/apple_auth_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/google_auth_provider.dart';
import 'core/services/log_service.dart';
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

  // Initialize Firebase first for error reporting
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Crashlytics (only in release mode)
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
  }

  // Activate Firebase App Check
  // Force real App Attest on iOS (debug provider is flaky on physical devices)
  // Real attestation works reliably in both debug and release builds
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'https://mwoxtqxzunsjmbdqezif.supabase.co',
      anonKey: 'sb_publishable_DJB3MvvHJRl-vuqrkn1-6w_hwTLnOaS',
    );
  } catch (e) {
    Log.error('Supabase initialization failed', e);
  }

  // Initialize RevenueCat
  final subscriptionService = SubscriptionService();
  bool initialProStatus = false;
  try {
    await subscriptionService.initialize();
    // Check pro status on startup
    initialProStatus = await subscriptionService.isPro();
    Log.info('App launched', {'initialProStatus': initialProStatus});
  } catch (e) {
    Log.error('RevenueCat initialization failed', e);
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
  // Non-blocking: don't await, let app start while initializing
  unawaited(authService.initializeProviders());

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        subscriptionServiceProvider.overrideWithValue(subscriptionService),
        authServiceProvider.overrideWithValue(authService),
        // Note: isProProvider now derives from customerInfoProvider reactively
      ],
      child: const ProsepalApp(),
    ),
  );
}
