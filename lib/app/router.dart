import 'package:flutter/material.dart';
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
import '../features/error/force_update_screen.dart';
import '../features/generate/generate_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/results/results_screen.dart';
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
GoRouter createAppRouter(SharedPreferences prefs) => GoRouter(
  initialLocation: '/splash',
  errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  redirect: (context, state) => _routeGuard(state, prefs),
  routes: _routes,
);

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
      final autoRestore = state.uri.queryParameters['autorestore'] == 'true';
      return AuthScreen(
        redirectTo: redirectTo,
        isProRestore: isRestore,
        autoRestore: autoRestore,
      );
    },
  ),
  GoRoute(
    path: '/auth/email',
    name: 'emailAuth',
    builder: (context, state) => EmailAuthScreen(
      autoPurchase: state.uri.queryParameters['autoPurchase'] == 'true',
      packageId: state.uri.queryParameters['package'],
      showPaywallAfterAuth:
          state.uri.queryParameters['showPaywallAfterAuth'] == 'true',
    ),
  ),
  // Auth callback routes - Supabase SDK handles the auth, these just redirect
  // The deep link is processed by supabase_flutter before reaching the router,
  // but go_router still tries to match the path, so we need placeholder routes.
  GoRoute(path: '/auth/login-callback', redirect: (context, state) => '/home'),
  GoRoute(path: '/auth/reset-callback', redirect: (context, state) => '/auth'),
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
  // /paywall route removed - now using showPaywall() bottom sheet
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
    path: '/calendar',
    name: 'calendar',
    builder: (context, state) => const CalendarScreen(),
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

/// Splash screen that shows during init and determines initial route
class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  bool _hasNavigated = false;
  bool _hasProFromRestore = false;

  @override
  void initState() {
    super.initState();
    _waitForInitAndNavigate();
  }

  Future<void> _waitForInitAndNavigate() async {
    // Wait for Supabase to be ready (required for auth)
    // RevenueCat can timeout - we'll proceed without it if needed
    while (mounted) {
      final status = ref.read(initStatusProvider);

      // Check for force update first (highest priority)
      if (status.forceUpdateRequired && status.forceUpdateStoreUrl != null) {
        Log.warning('Force update required - showing update screen');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ForceUpdateScreen(storeUrl: status.forceUpdateStoreUrl!),
            ),
          );
        }
        return;
      }

      // Check for critical error
      if (status.hasError) {
        Log.error('Init failed', {'error': status.error});
        // Could show error screen, for now just navigate
        break;
      }

      // Supabase ready = we can proceed
      // (RevenueCat ready OR timed out = we can check Pro status)
      // (RemoteConfig ready OR debug mode = force update check complete)
      if (status.isSupabaseReady &&
          (status.isRevenueCatReady || status.isTimedOut)) {
        break;
      }

      // Wait a bit before checking again
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      await _determineInitialRoute();
    }
  }

  Future<void> _determineInitialRoute() async {
    // Sync device state from server FIRST - ensures accurate state on home screen
    final usageService = ref.read(usageServiceProvider);
    await usageService.syncDeviceStateFromServer();

    final prefs = ref.read(sharedPreferencesProvider);
    final hasCompletedOnboarding =
        prefs.getBool(PreferenceKeys.hasCompletedOnboarding) ??
        PreferenceKeys.hasCompletedOnboardingDefault;
    final authService = ref.read(authServiceProvider);
    final isLoggedIn = authService.isLoggedIn;
    final biometricService = ref.read(biometricServiceProvider);
    final biometricsEnabled = await biometricService.isEnabled;

    var biometricsAvailable = false;
    if (biometricsEnabled) {
      final available = await biometricService.availableBiometrics;
      biometricsAvailable = available.isNotEmpty;
      if (!biometricsAvailable) {
        Log.warning('Biometrics enabled but unavailable - auto-disabling');
        await biometricService.setEnabled(false);
      }
    }

    if (!isLoggedIn) {
      _hasProFromRestore = await _checkAnonymousProStatus();
    }

    if (!mounted) return;

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
      Log.info('Router: -> /lock (biometrics enabled)');
      context.go('/lock');
    } else if (_hasProFromRestore) {
      Log.info('Router: -> /auth?restore=true (has Pro, not signed in)');
      context.go('/auth?restore=true');
    } else {
      Log.info('Router: -> /home (default)');
      context.go('/home');
    }
  }

  Future<bool> _checkAnonymousProStatus() async {
    try {
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.splash,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogoStyled(),
          const SizedBox(height: 24),
          Text(
            'Prosepal',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Error screen for unknown routes (404)
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) => Scaffold(
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
                "The page you're looking for doesn't exist.",
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
