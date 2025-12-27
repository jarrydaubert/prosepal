import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/providers/providers.dart';
import 'core/services/subscription_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Crashlytics (only in release mode)
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://mwoxtqxzunsjmbdqezif.supabase.co',
    anonKey: 'sb_publishable_DJB3MvvHJRl-vuqrkn1-6w_hwTLnOaS',
  );

  // Initialize RevenueCat
  final subscriptionService = SubscriptionService();
  await subscriptionService.initialize();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        subscriptionServiceProvider.overrideWithValue(subscriptionService),
      ],
      child: const ProsepalApp(),
    ),
  );
}
