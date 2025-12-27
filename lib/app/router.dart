import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/biometric_service.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/email_auth_screen.dart';
import '../features/auth/lock_screen.dart';
import '../features/generate/generate_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/paywall/paywall_screen.dart';
import '../features/results/results_screen.dart';
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
      builder: (context, state) => const AuthScreen(),
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
      builder: (context, state) => const PaywallScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

/// Splash screen that determines initial route
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final biometricsEnabled = await BiometricService.instance.isEnabled;

    if (!hasCompletedOnboarding) {
      context.go('/onboarding');
    } else if (!isLoggedIn) {
      context.go('/auth');
    } else if (biometricsEnabled) {
      context.go('/lock');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE57373), Color(0xFFFFAB91)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Prosepal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
