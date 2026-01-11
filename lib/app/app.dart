import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/providers/providers.dart';
import '../core/services/log_service.dart';

import '../shared/theme/app_colors.dart';
import '../shared/theme/app_theme.dart';
import 'router.dart';

class ProsepalApp extends ConsumerStatefulWidget {
  const ProsepalApp({super.key, this.router});

  /// Optional custom router (used for route guards with SharedPreferences).
  /// If not provided, falls back to default appRouter without guards.
  final GoRouter? router;

  @override
  ConsumerState<ProsepalApp> createState() => _ProsepalAppState();
}

class _ProsepalAppState extends ConsumerState<ProsepalApp>
    with WidgetsBindingObserver {
  bool _isInBackground = false;
  DateTime? _backgroundedAt;
  StreamSubscription<AuthState>? _authSubscription;

  // Require re-auth if backgrounded for more than this duration
  // 60s is reasonable for a content app (not banking-level security)
  static const _lockTimeout = Duration(seconds: 60);

  /// Get the router to use (custom or default)
  GoRouter get _router => widget.router ?? appRouter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAuthListener();
    _setupErrorBoundary();
  }

  /// Set up user-friendly error widget for widget build errors
  void _setupErrorBoundary() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Log to Crashlytics (already configured in main.dart)
      Log.error('Widget build error', details.exception, details.stack);

      return Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.orange[700],
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please restart the app',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    };
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasInBackground = _isInBackground;
    setState(() {
      // Flutter 3.13+ added 'hidden' for brief non-visible transitions
      _isInBackground =
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden;
    });

    // Track when app was backgrounded for timeout calculation
    if (_isInBackground && !wasInBackground) {
      _backgroundedAt = DateTime.now();
      Log.info('App backgrounded');
    } else if (!_isInBackground && wasInBackground) {
      Log.info('App resumed');
      _checkBiometricLockOnResume();
    }
  }

  /// Check if biometric re-authentication is required on resume
  Future<void> _checkBiometricLockOnResume() async {
    // Skip if we don't have a background timestamp
    if (_backgroundedAt == null) return;

    // Skip if backgrounded for less than timeout (e.g., brief phone call)
    final elapsed = DateTime.now().difference(_backgroundedAt!);
    if (elapsed < _lockTimeout) {
      Log.info('Skip biometric lock - backgrounded only ${elapsed.inSeconds}s');
      return;
    }

    // Skip if already on lock screen or splash
    final currentPath = _router.routerDelegate.currentConfiguration.fullPath;
    if (currentPath == '/lock' || currentPath == '/splash') {
      return;
    }

    // Check if biometrics are enabled
    try {
      final biometricService = ref.read(biometricServiceProvider);
      final isEnabled = await biometricService.isEnabled;
      final isAvailable =
          (await biometricService.availableBiometrics).isNotEmpty;

      if (isEnabled && isAvailable) {
        Log.info('Biometric lock on resume - redirecting to /lock');
        _router.go('/lock');
      }
    } catch (e) {
      Log.warning('Failed to check biometric lock on resume', {'error': '$e'});
    }
  }

  void _setupAuthListener() {
    // Skip if Supabase isn't initialized (e.g., integration tests with mocks)
    try {
      final supabase = Supabase.instance;
      if (!supabase.isInitialized) return;

      // Listen for auth state changes (magic link, OAuth callback, etc.)
      _authSubscription = supabase.client.auth.onAuthStateChange.listen((
        data,
      ) async {
        final event = data.event;
        final session = data.session;
        Log.info('Auth state changed', {
          'event': event.name,
          'hasSession': session != null,
          'userId': session?.user.id.substring(0, 8),
        });

        if (event == AuthChangeEvent.signedIn && session != null) {
          // Identify with RevenueCat to restore Pro entitlements
          // This is safe - "New Customers" metric tracks first purchase, not identification
          try {
            await ref
                .read(subscriptionServiceProvider)
                .identifyUser(session.user.id);
            Log.info('Auth listener: RevenueCat identified');
          } catch (e) {
            Log.warning('Auth listener: RevenueCat identify failed', {
              'error': '$e',
            });
          }

          // Sync usage from server (restores usage after reinstall)
          try {
            await ref.read(usageServiceProvider).syncFromServer();
            Log.info('Auth listener: Usage synced from server');
          } catch (e) {
            Log.warning('Auth listener: Usage sync failed', {'error': '$e'});
          }

          // Navigate after sign-in
          // - Magic links: user returns to app, listener must navigate
          // - Apple/Google/Email buttons: AuthScreen navigates directly
          // - To avoid race conditions, only navigate if on auth screens
          //   (Apple/Google navigate immediately, won't be on /auth anymore)
          // Note: fullPath check is simple but sufficient for current routes
          final currentPath =
              _router.routerDelegate.currentConfiguration.fullPath;
          if (currentPath.startsWith('/auth')) {
            // Still on auth screen = magic link callback, navigate away
            Log.info(
              'Auth listener: Magic link sign-in, navigating to /home (from $currentPath)',
            );
            _router.go('/home');
          }
        } else if (event == AuthChangeEvent.signedOut) {
          // Clear sync marker so next user gets fresh sync
          try {
            await ref.read(usageServiceProvider).clearSyncMarker();
            Log.info('Auth listener: Sync marker cleared (signedOut)');
          } catch (e) {
            Log.warning('Auth listener: Clear sync marker failed', {
              'error': '$e',
            });
          }
          // Note: Navigation is handled by caller (settings_screen)
          // Sign out → /home, Delete account → /onboarding
        }
      });
    } catch (_) {
      // Supabase not initialized - skip auth listener (integration tests with mocks)
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Prosepal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
