import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/providers/providers.dart';
import '../core/services/biometric_service.dart';
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
import '../features/settings/feedback_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
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
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding =
        prefs.getBool('hasCompletedOnboarding') ?? false;
    final authService = ref.read(authServiceProvider);
    final isLoggedIn = authService.isLoggedIn;
    final biometricsEnabled = await BiometricService.instance.isEnabled;

    // Auto-restore: Check if anonymous user has Pro from previous purchase
    // This catches reinstalls where user purchased but isn't signed in yet
    if (!isLoggedIn) {
      _hasProFromRestore = await _checkAnonymousProStatus();
    }

    if (!hasCompletedOnboarding) {
      context.go('/onboarding');
    } else if (isLoggedIn && biometricsEnabled) {
      context.go('/lock');
    } else if (_hasProFromRestore) {
      // Has Pro but not signed in - prompt to claim it
      context.go('/auth?restore=true');
    } else {
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Prosepal',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
