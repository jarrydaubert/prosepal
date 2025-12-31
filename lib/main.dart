import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/providers/providers.dart';
import 'core/services/apple_auth_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/google_auth_provider.dart';
import 'core/services/review_service.dart';
import 'core/services/supabase_auth_provider.dart';
import 'core/services/subscription_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'https://mwoxtqxzunsjmbdqezif.supabase.co',
      anonKey: 'sb_publishable_DJB3MvvHJRl-vuqrkn1-6w_hwTLnOaS',
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  // Initialize RevenueCat
  final subscriptionService = SubscriptionService();
  try {
    await subscriptionService.initialize();
  } catch (e) {
    debugPrint('RevenueCat initialization failed: $e');
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
      ],
      child: const ProsepalApp(),
    ),
  );
}
