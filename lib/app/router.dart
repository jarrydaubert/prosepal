import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/preference_keys.dart';
import '../core/providers/providers.dart';
import '../core/services/log_service.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/email_auth_screen.dart';
import '../features/auth/lock_screen.dart';
import '../features/generate/generate_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/paywall/custom_paywall_screen.dart';
import '../features/results/results_screen.dart';
import '../features/history/history_screen.dart';
import '../features/settings/feedback_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/settings_screen.dart';
import '../shared/components/app_logo.dart';
import '../shared/theme/app_colors.dart';

/// Routes that don't require onboarding completion
const _publicRoutes = {'/splash', '/onboarding', '/terms', '/privacy'};

/// Routes that are part of the auth flow
const _authRoutes = {'/auth', '/auth/email', '/lock'};

/// Create router with route guards
///
/// Route guard logic:
/// 1. Public routes (splash, onboarding, legal) - always accessible
/// 2. Auth routes - accessible during auth flow
/// 3. Protected routes - require onboarding completion
///
/// Note: Biometric lock is handled by splash screen because it requires async check.
/// The redirect callback is synchronous, so we use splash as a gate.
GoRouter createAppRouter(SharedPreferences prefs) {
  return GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
    redirect: (context, state) => _routeGuard(state, prefs),
    routes: _routes,
  );
}

/// Legacy router without guards (for backward compatibility during transition)
/// TODO: Remove once all usages migrate to createAppRouter
final appRouter = GoRouter(
  initialLocation: '/splash',
  errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  routes: _routes,
);

/// Route guard that prevents bypassing onboarding via deep links
String? _routeGuard(GoRouterState state, SharedPreferences prefs) {
  final path = state.matchedLocation;

  // Public routes - always allow
  if (_publicRoutes.contains(path)) {
    return null;
  }

  // Auth routes - allow during auth flow
  if (_authRoutes.contains(path) || path.startsWith('/auth')) {
    return null;
  }

  // Check if onboarding is completed
  final hasCompletedOnboarding =
      prefs.getBool(PreferenceKeys.hasCompletedOnboarding) ??
          PreferenceKeys.hasCompletedOnboardingDefault;

  if (!hasCompletedOnboarding) {
    // Deep link tried to bypass onboarding - redirect to splash
    Log.warning('Route guard: Blocked deep link to $path (not onboarded)');
    return '/splash';
  }

  // Onboarding complete - allow navigation
  // Note: Biometric lock is checked in splash screen on app start
  return null;
}

/// All app routes
final _routes = <RouteBase>[
  GoRoute(path: '/splash', builder: (context, state) => const _SplashScreen()),
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
];

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
        prefs.getBool(PreferenceKeys.hasCompletedOnboarding) ??
          PreferenceKeys.hasCompletedOnboardingDefault;
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
      // Use subscription service to check if RevenueCat is configured
      final subscriptionService = ref.read(subscriptionServiceProvider);
      if (!subscriptionService.isConfigured) {
        Log.warning('RevenueCat not configured - skipping anonymous Pro check');
        return false;
      }
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
    // Matches native splash: styled logo on dark charcoal background
    return const Scaffold(
      backgroundColor: AppColors.splash,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogoStyled(size: 100),
            SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
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
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
