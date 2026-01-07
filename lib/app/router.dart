import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/providers/providers.dart';
import '../core/services/log_service.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/email_auth_screen.dart';
import '../features/auth/lock_screen.dart';
import '../features/generate/generate_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/biometric_setup_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/paywall/custom_paywall_screen.dart';
import '../features/results/results_screen.dart';
import '../features/history/history_screen.dart';
import '../features/settings/feedback_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/settings_screen.dart';
import '../shared/atoms/app_logo.dart';
import '../shared/theme/app_colors.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  // Handle unknown routes with error page
  errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const _SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) {
        final redirectTo = state.uri.queryParameters['redirect'];
        final isRestore = state.uri.queryParameters['restore'] == 'true';
        return AuthScreen(redirectTo: redirectTo, isProRestore: isRestore);
      },
    ),
    GoRoute(
      path: '/auth/email',
      name: 'emailAuth',
      builder: (context, state) => const EmailAuthScreen(),
    ),
    GoRoute(
      path: '/biometric-setup',
      name: 'biometricSetup',
      builder: (context, state) => const BiometricSetupScreen(),
    ),
    GoRoute(
      path: '/lock',
      name: 'lock',
      builder: (context, state) => const LockScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/generate',
      name: 'generate',
      builder: (context, state) => const GenerateScreen(),
    ),
    GoRoute(
      path: '/results',
      name: 'results',
      builder: (context, state) => const ResultsScreen(),
    ),
    GoRoute(
      path: '/paywall',
      name: 'paywall',
      builder: (context, state) => const CustomPaywallScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/feedback',
      name: 'feedback',
      builder: (context, state) => const FeedbackScreen(),
    ),
    GoRoute(
      path: '/terms',
      name: 'terms',
      builder: (context, state) => const TermsScreen(),
    ),
    GoRoute(
      path: '/privacy',
      name: 'privacy',
      builder: (context, state) => const PrivacyScreen(),
    ),
  ],
);

/// Splash screen that determines initial route
class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  bool _hasProFromRestore = false;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    // No artificial delay - determine route as fast as possible
    // Native splash stays visible until we call FlutterNativeSplash.remove()

    // Use providers for consistency and testability
    final prefs = ref.read(sharedPreferencesProvider);
    final hasCompletedOnboarding =
        prefs.getBool('hasCompletedOnboarding') ?? false;
    final authService = ref.read(authServiceProvider);
    final isLoggedIn = authService.isLoggedIn;
    final biometricService = ref.read(biometricServiceProvider);
    final biometricsEnabled = await biometricService.isEnabled;

    // Check if biometrics are actually available on device
    // User may have enabled in app but later disabled in device settings
    var biometricsAvailable = false;
    if (biometricsEnabled) {
      final available = await biometricService.availableBiometrics;
      biometricsAvailable = available.isNotEmpty;
      if (!biometricsAvailable) {
        // Biometrics were enabled but are no longer available - auto-disable
        Log.warning('Biometrics enabled but unavailable - auto-disabling');
        await biometricService.setEnabled(false);
      }
    }

    // Auto-restore: Check if anonymous user has Pro from previous purchase
    // This catches reinstalls where user purchased but isn't signed in yet
    if (!isLoggedIn) {
      _hasProFromRestore = await _checkAnonymousProStatus();
    }

    if (!mounted) return;

    // Remove native splash right before navigation
    FlutterNativeSplash.remove();

    Log.info('Router: Initial navigation', {
      'onboarded': hasCompletedOnboarding,
      'loggedIn': isLoggedIn,
      'bioEnabled': biometricsEnabled,
      'bioAvailable': biometricsAvailable,
      'hasProRestore': _hasProFromRestore,
    });

    if (!hasCompletedOnboarding) {
      Log.info('Router: -> /onboarding (not onboarded)');
      context.go('/onboarding');
    } else if (biometricsEnabled && biometricsAvailable) {
      // Biometric lock applies to all users (logged in or anonymous)
      // User explicitly enabled it, so respect their choice
      Log.info('Router: -> /lock (biometrics enabled)');
      context.go('/lock');
    } else if (_hasProFromRestore) {
      // Has Pro but not signed in - prompt to claim it
      Log.info('Router: -> /auth?restore=true (has Pro, not signed in)');
      context.go('/auth?restore=true');
    } else {
      Log.info('Router: -> /home (default)');
      context.go('/home');
    }
  }

  /// Check RevenueCat for Pro status without being logged in.
  /// Returns true if user has active Pro entitlement (from App Store receipt).
  Future<bool> _checkAnonymousProStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final hasPro = customerInfo.entitlements.active.containsKey('pro');
      if (hasPro) {
        Log.info('Anonymous user has Pro - prompting sign-in to claim');
      }
      return hasPro;
    } on Exception catch (e) {
      Log.warning('Failed to check anonymous Pro status', {'error': '$e'});
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Matches native splash: logo centered on background color
    // No text - seamless transition from native splash
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const AppLogo(size: 80),
        ),
      ),
    );
  }
}

/// Error screen for unknown routes (404)
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Page not found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The page you\'re looking for doesn\'t exist.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
