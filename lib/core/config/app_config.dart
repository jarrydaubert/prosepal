import 'package:flutter/foundation.dart';

/// Centralized configuration for all environment variables.
///
/// All values are provided via dart-define at build time:
/// ```bash
/// flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx
/// ```
///
/// For local development, use the run scripts which source from `.env.local`:
/// ```bash
/// ./scripts/run_ios.sh    # iOS with all keys
/// ./scripts/run_android.sh # Android with all keys
/// ```
///
/// For CI/CD, set these as environment variables in your build system.
///
/// See `.env.example` for all required variables.
abstract final class AppConfig {
  // ===========================================================================
  // Supabase Configuration
  // Dashboard: https://supabase.com/dashboard
  // ===========================================================================

  /// Supabase project URL
  /// Find in: Supabase Dashboard > Project Settings > API > Project URL
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anonymous (public) key
  /// Find in: Supabase Dashboard > Project Settings > API > anon public
  /// Note: This key is safe to expose in client code - RLS policies protect data
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  // ===========================================================================
  // RevenueCat Configuration
  // Dashboard: https://app.revenuecat.com
  // ===========================================================================

  /// RevenueCat iOS API key
  /// Find in: RevenueCat Dashboard > Project > API Keys > iOS
  static const String revenueCatIosKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
  );

  /// RevenueCat Android API key
  /// Find in: RevenueCat Dashboard > Project > API Keys > Android
  static const String revenueCatAndroidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );

  /// RevenueCat Test Store key (for automated testing only)
  /// Find in: RevenueCat Dashboard > Project Settings > Apps > Test Store
  /// WARNING: Using Test Store in production WILL crash the app!
  static const String revenueCatTestStoreKey = String.fromEnvironment(
    'REVENUECAT_TEST_STORE_KEY',
  );

  /// Whether to use Test Store (for automated testing)
  static const bool useRevenueCatTestStore = bool.fromEnvironment(
    'REVENUECAT_USE_TEST_STORE',
  );

  // ===========================================================================
  // Google Sign-In Configuration
  // Console: https://console.cloud.google.com/apis/credentials
  // ===========================================================================

  /// Google OAuth Web Client ID (required for both platforms)
  /// Find in: Firebase Console > Project Settings > Your Apps > Web
  /// Or: Google Cloud Console > APIs & Services > Credentials
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Google OAuth iOS Client ID
  /// Find in: Firebase Console > Project Settings > Your Apps > iOS
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  // ===========================================================================
  // Validation
  // ===========================================================================

  /// Validates that all required configuration is present.
  /// Call this early in app initialization (after main()).
  ///
  /// In debug mode, logs warnings for missing config.
  /// In release mode, throws if critical config is missing.
  static void validate() {
    final missing = <String>[];

    // Critical: App won't function without these
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');

    // Platform-specific RevenueCat keys
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        revenueCatIosKey.isEmpty) {
      missing.add('REVENUECAT_IOS_KEY');
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        revenueCatAndroidKey.isEmpty) {
      missing.add('REVENUECAT_ANDROID_KEY');
    }

    if (missing.isEmpty) return;

    final message =
        'Missing required configuration: ${missing.join(', ')}\n'
        'Provide via dart-define or use ./scripts/run_ios.sh (or run_android.sh)';

    if (kReleaseMode) {
      // In release mode, fail fast - app won't work properly
      throw StateError(message);
    } else {
      // In debug mode, warn but allow app to run (for partial testing)
      debugPrint('WARNING: $message');
    }
  }

  /// Check if Supabase is configured
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Check if RevenueCat is configured for the current platform
  static bool get hasRevenueCatConfig {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return revenueCatIosKey.isNotEmpty;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return revenueCatAndroidKey.isNotEmpty;
    }
    return false;
  }

  /// Check if Google Sign-In is configured
  static bool get hasGoogleSignInConfig => googleWebClientId.isNotEmpty;
}
