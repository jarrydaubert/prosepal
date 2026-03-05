import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/preference_keys.dart';
import '../core/providers/providers.dart';
import '../core/services/log_service.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/lock_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/error/force_update_screen.dart';
import '../features/generate/generate_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/results/results_screen.dart';
import '../features/settings/feedback_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/settings_screen.dart';
import '../shared/theme/app_colors.dart';

/// Routes that don't require onboarding completion
const _publicRoutes = {
  '/splash',
  '/onboarding',
  '/terms',
  '/privacy',
  '/init-error',
};

/// Routes that are part of the auth flow
const _authRoutes = {'/auth', '/lock'};

/// Deterministic startup route decision.
@visibleForTesting
String determineStartupRoute({
  required bool hasCompletedOnboarding,
  required bool isLoggedIn,
  required bool biometricsEnabled,
  required bool biometricsAvailable,
  required bool hasProRestore,
  required bool hasInitError,
}) {
  if (hasInitError) return '/init-error';
  if (!hasCompletedOnboarding) return '/onboarding';
  if (biometricsEnabled && biometricsAvailable) return '/lock';
  if (hasProRestore) return '/auth?restore=true';
  return '/home';
}

/// Fallback route when startup resolution exceeds its time budget.
@visibleForTesting
String determineStartupFallbackRoute({
  required bool hasCompletedOnboarding,
  required bool hasInitError,
}) {
  if (hasInitError) return '/init-error';
  return hasCompletedOnboarding ? '/home' : '/onboarding';
}

/// Resolve startup route with an explicit timeout budget.
@visibleForTesting
Future<StartupRouteResolution> resolveStartupRouteWithTimeout({
  required Future<String> Function() resolver,
  required Duration timeout,
  required String fallbackRoute,
}) async {
  try {
    final route = await resolver().timeout(timeout);
    return StartupRouteResolution(route: route, timedOut: false);
  } on TimeoutException {
    return StartupRouteResolution(route: fallbackRoute, timedOut: true);
  }
}

/// Whether splash should bypass async route resolution and navigate directly.
@visibleForTesting
bool shouldShortCircuitStartupResolution({
  required bool hasCompletedOnboarding,
  required bool hasInitError,
}) => hasInitError || !hasCompletedOnboarding;

/// Startup route resolution result with explicit timeout metadata.
class StartupRouteResolution {
  const StartupRouteResolution({required this.route, required this.timedOut});

  final String route;
  final bool timedOut;
}

@visibleForTesting
Map<String, Object> startupPhaseTelemetryParams({
  required String phase,
  required int durationMs,
  required int budgetMs,
  required bool timedOut,
  required String outcome,
}) => <String, Object>{
  'phase': phase,
  'duration_ms': durationMs,
  'budget_ms': budgetMs,
  'timed_out': timedOut,
  'outcome': outcome,
};

@visibleForTesting
Map<String, Object> startupRoutingSummaryAnalyticsParams({
  required int initWaitMs,
  required int splashHoldMs,
  required int routeResolutionMs,
  required String initPhaseOutcome,
  required int identityPhaseMs,
  required String identityPhaseOutcome,
  required int entitlementsPhaseMs,
  required String entitlementsPhaseOutcome,
  required bool usedFallback,
  required String? fallbackReason,
  required String? resolvedRoute,
}) => <String, Object>{
  'init_wait_ms': initWaitMs,
  'splash_hold_ms': splashHoldMs,
  'route_resolution_ms': routeResolutionMs,
  'init_phase_outcome': initPhaseOutcome,
  'identity_phase_ms': identityPhaseMs,
  'identity_phase_outcome': identityPhaseOutcome,
  'entitlements_phase_ms': entitlementsPhaseMs,
  'entitlements_phase_outcome': entitlementsPhaseOutcome,
  'used_fallback': usedFallback,
  'fallback_reason': fallbackReason ?? 'none',
  'resolved_route': resolvedRoute ?? 'unknown',
};

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
    path: '/init-error',
    name: 'init-error',
    builder: (context, state) => const _InitErrorScreen(),
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
      final autoRestore = state.uri.queryParameters['autorestore'] == 'true';
      return AuthScreen(
        redirectTo: redirectTo,
        isProRestore: isRestore,
        autoRestore: autoRestore,
      );
    },
  ),
  // Auth callback routes - Supabase SDK handles the auth, these just redirect
  // The deep link is processed by supabase_flutter before reaching the router,
  // but go_router still tries to match the path, so we need placeholder routes.
  GoRoute(path: '/auth/login-callback', redirect: (context, state) => '/home'),
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
  static const _pollInterval = Duration(milliseconds: 120);
  static const _maxWaitForInit = Duration(seconds: 12);
  static const _routeResolutionTimeout = Duration(seconds: 10);
  static const _minVisibleDuration = Duration(milliseconds: 500);
  static const _deviceStateSyncTimeout = Duration(seconds: 3);
  static const _biometricCheckTimeout = Duration(seconds: 2);
  static const _anonymousProCheckTimeout = Duration(seconds: 3);

  bool _hasNavigated = false;
  bool _hasProFromRestore = false;
  late final DateTime _shownAt;
  int _identityPhaseMs = 0;
  int _entitlementsPhaseMs = 0;
  String _identityPhaseOutcome = 'not_started';
  String _entitlementsPhaseOutcome = 'not_started';

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
    _waitForInitAndNavigate();
  }

  Future<void> _waitForInitAndNavigate() async {
    final startedAt = DateTime.now();
    var initErrorDetected = false;
    var initWaitMs = 0;
    var initPhaseOutcome = 'unknown';
    var splashHoldMs = 0;
    var routeResolutionMs = 0;
    var usedFallback = false;
    String? fallbackReason;
    String? resolvedRoute;
    _identityPhaseMs = 0;
    _entitlementsPhaseMs = 0;
    _identityPhaseOutcome = 'not_started';
    _entitlementsPhaseOutcome = 'not_started';

    // Wait for Supabase to be ready (required for auth)
    // RevenueCat can timeout - we'll proceed without it if needed
    while (mounted) {
      final elapsed = DateTime.now().difference(startedAt);
      initWaitMs = elapsed.inMilliseconds;
      if (elapsed >= _maxWaitForInit) {
        initPhaseOutcome = 'timeout';
        Log.warning('Splash init wait timeout reached', {
          'timeoutMs': _maxWaitForInit.inMilliseconds,
        });
        break;
      }

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
        initPhaseOutcome = 'init_error';
        Log.error('Init failed', {'error': status.error});
        initErrorDetected = true;
        break;
      }

      // Supabase ready = we can proceed
      // (RevenueCat ready OR timed out = we can check Pro status)
      // (RemoteConfig ready OR debug mode = force update check complete)
      if (status.isSupabaseReady &&
          (status.isRevenueCatReady || status.isTimedOut)) {
        initPhaseOutcome = status.isTimedOut
            ? 'supabase_ready_revenuecat_timeout'
            : 'ready';
        break;
      }

      // Wait a bit before checking again
      await Future<void>.delayed(_pollInterval);
    }

    if (mounted && !_hasNavigated) {
      _logStartupPhase(
        phase: 'init',
        durationMs: initWaitMs,
        budgetMs: _maxWaitForInit.inMilliseconds,
        outcome: initPhaseOutcome,
        timedOut: initPhaseOutcome == 'timeout',
      );

      final visibleFor = DateTime.now().difference(_shownAt);
      if (visibleFor < _minVisibleDuration) {
        final hold = _minVisibleDuration - visibleFor;
        splashHoldMs = hold.inMilliseconds;
        await Future<void>.delayed(hold);
      }
      _hasNavigated = true;
      final prefs = ref.read(sharedPreferencesProvider);
      final hasCompletedOnboarding =
          prefs.getBool(PreferenceKeys.hasCompletedOnboarding) ??
          PreferenceKeys.hasCompletedOnboardingDefault;
      final fallbackRoute = determineStartupFallbackRoute(
        hasCompletedOnboarding: hasCompletedOnboarding,
        hasInitError: initErrorDetected,
      );
      if (shouldShortCircuitStartupResolution(
        hasCompletedOnboarding: hasCompletedOnboarding,
        hasInitError: initErrorDetected,
      )) {
        // Deterministic short-circuit for first launch / init error paths.
        // Avoids unnecessary async checks that can trigger false timeout
        // fallbacks on slow devices during onboarding entry.
        resolvedRoute = fallbackRoute;
        usedFallback = true;
        fallbackReason = initErrorDetected
            ? 'init_error'
            : 'first_launch_onboarding';
        _logStartupPhase(
          phase: 'routing',
          durationMs: routeResolutionMs,
          budgetMs: _routeResolutionTimeout.inMilliseconds,
          outcome: 'short_circuit',
          timedOut: false,
        );
        _logStartupRoutingSummary(
          initWaitMs: initWaitMs,
          splashHoldMs: splashHoldMs,
          routeResolutionMs: routeResolutionMs,
          initPhaseOutcome: initPhaseOutcome,
          identityPhaseMs: _identityPhaseMs,
          identityPhaseOutcome: _identityPhaseOutcome,
          entitlementsPhaseMs: _entitlementsPhaseMs,
          entitlementsPhaseOutcome: _entitlementsPhaseOutcome,
          usedFallback: usedFallback,
          fallbackReason: fallbackReason,
          resolvedRoute: resolvedRoute,
        );
        _navigateToInitialRoute(fallbackRoute);
        return;
      }
      try {
        final routeResolveStartedAt = DateTime.now();
        final resolution = await resolveStartupRouteWithTimeout(
          resolver: () => _determineInitialRoute(
            hasCompletedOnboarding: hasCompletedOnboarding,
            hasInitError: initErrorDetected,
          ),
          timeout: _routeResolutionTimeout,
          fallbackRoute: fallbackRoute,
        );
        routeResolutionMs = DateTime.now()
            .difference(routeResolveStartedAt)
            .inMilliseconds;

        if (resolution.timedOut) {
          usedFallback = true;
          fallbackReason = 'route_resolution_timeout';
          Log.warning('Startup route resolution timed out; applying fallback', {
            'timeoutMs': _routeResolutionTimeout.inMilliseconds,
            'fallbackRoute': fallbackRoute,
          });
        }
        _logStartupPhase(
          phase: 'routing',
          durationMs: routeResolutionMs,
          budgetMs: _routeResolutionTimeout.inMilliseconds,
          outcome: resolution.timedOut ? 'timeout_fallback' : 'resolved',
          timedOut: resolution.timedOut,
        );

        resolvedRoute = resolution.route;
        _logStartupRoutingSummary(
          initWaitMs: initWaitMs,
          splashHoldMs: splashHoldMs,
          routeResolutionMs: routeResolutionMs,
          initPhaseOutcome: initPhaseOutcome,
          identityPhaseMs: _identityPhaseMs,
          identityPhaseOutcome: _identityPhaseOutcome,
          entitlementsPhaseMs: _entitlementsPhaseMs,
          entitlementsPhaseOutcome: _entitlementsPhaseOutcome,
          usedFallback: usedFallback,
          fallbackReason: fallbackReason,
          resolvedRoute: resolvedRoute,
        );
        if (!mounted) return;
        _navigateToInitialRoute(resolution.route);
      } on Exception catch (e) {
        usedFallback = true;
        fallbackReason = 'route_resolution_exception';
        resolvedRoute = fallbackRoute;
        Log.warning('Startup route resolution failed; applying fallback', {
          'fallbackRoute': fallbackRoute,
          'error': '$e',
        });
        _logStartupPhase(
          phase: 'routing',
          durationMs: routeResolutionMs,
          budgetMs: _routeResolutionTimeout.inMilliseconds,
          outcome: 'exception_fallback',
          timedOut: false,
        );
        _logStartupRoutingSummary(
          initWaitMs: initWaitMs,
          splashHoldMs: splashHoldMs,
          routeResolutionMs: routeResolutionMs,
          initPhaseOutcome: initPhaseOutcome,
          identityPhaseMs: _identityPhaseMs,
          identityPhaseOutcome: _identityPhaseOutcome,
          entitlementsPhaseMs: _entitlementsPhaseMs,
          entitlementsPhaseOutcome: _entitlementsPhaseOutcome,
          usedFallback: usedFallback,
          fallbackReason: fallbackReason,
          resolvedRoute: resolvedRoute,
        );
        if (!mounted) return;
        _navigateToInitialRoute(fallbackRoute);
      }
    }
  }

  void _logStartupRoutingSummary({
    required int initWaitMs,
    required int splashHoldMs,
    required int routeResolutionMs,
    required String initPhaseOutcome,
    required int identityPhaseMs,
    required String identityPhaseOutcome,
    required int entitlementsPhaseMs,
    required String entitlementsPhaseOutcome,
    required bool usedFallback,
    required String? fallbackReason,
    required String? resolvedRoute,
  }) {
    Log.info('Startup routing summary', {
      'initWaitMs': initWaitMs,
      'splashHoldMs': splashHoldMs,
      'routeResolutionMs': routeResolutionMs,
      'initPhaseOutcome': initPhaseOutcome,
      'identityPhaseMs': identityPhaseMs,
      'identityPhaseOutcome': identityPhaseOutcome,
      'entitlementsPhaseMs': entitlementsPhaseMs,
      'entitlementsPhaseOutcome': entitlementsPhaseOutcome,
      'usedFallback': usedFallback,
      'fallbackReason': fallbackReason,
      'resolvedRoute': resolvedRoute,
    });
    unawaited(
      Log.event(
        'startup_routing_summary',
        startupRoutingSummaryAnalyticsParams(
          initWaitMs: initWaitMs,
          splashHoldMs: splashHoldMs,
          routeResolutionMs: routeResolutionMs,
          initPhaseOutcome: initPhaseOutcome,
          identityPhaseMs: identityPhaseMs,
          identityPhaseOutcome: identityPhaseOutcome,
          entitlementsPhaseMs: entitlementsPhaseMs,
          entitlementsPhaseOutcome: entitlementsPhaseOutcome,
          usedFallback: usedFallback,
          fallbackReason: fallbackReason,
          resolvedRoute: resolvedRoute,
        ),
      ),
    );
  }

  void _logStartupPhase({
    required String phase,
    required int durationMs,
    required int budgetMs,
    required String outcome,
    required bool timedOut,
  }) {
    Log.info('Startup phase telemetry', {
      'phase': phase,
      'durationMs': durationMs,
      'budgetMs': budgetMs,
      'timedOut': timedOut,
      'outcome': outcome,
    });
    unawaited(
      Log.event(
        'startup_phase',
        startupPhaseTelemetryParams(
          phase: phase,
          durationMs: durationMs,
          budgetMs: budgetMs,
          timedOut: timedOut,
          outcome: outcome,
        ),
      ),
    );
  }

  void _navigateToInitialRoute(String route) {
    if (!mounted) return;

    final logMessage = switch (route) {
      '/onboarding' => 'Router: -> /onboarding (not onboarded)',
      '/lock' => 'Router: -> /lock (biometrics enabled)',
      '/auth?restore=true' =>
        'Router: -> /auth?restore=true (has Pro, not signed in)',
      '/home' => 'Router: -> /home (default)',
      '/init-error' => 'Router: -> /init-error (startup init error)',
      _ => 'Router: -> $route',
    };
    Log.info(logMessage);
    context.go(route);
  }

  Future<String> _determineInitialRoute({
    required bool hasCompletedOnboarding,
    required bool hasInitError,
  }) async {
    if (!mounted) return '/init-error';

    if (hasInitError) {
      _hasProFromRestore = false;
      Log.info('Router: Initial navigation', {
        'onboarded': hasCompletedOnboarding,
        'loggedIn': false,
        'bioEnabled': false,
        'bioAvailable': false,
        'hasProRestore': _hasProFromRestore,
        'initError': true,
      });
      return '/init-error';
    }

    // Fast-path first-launch onboarding. Avoid running additional startup
    // checks (device sync/auth/pro restore) when we already know route intent.
    if (!hasCompletedOnboarding) {
      _hasProFromRestore = false;
      Log.info('Router: Initial navigation', {
        'onboarded': false,
        'loggedIn': false,
        'bioEnabled': false,
        'bioAvailable': false,
        'hasProRestore': _hasProFromRestore,
        'initError': false,
      });
      return '/onboarding';
    }

    _startDeviceStateSyncBackground();

    final authService = ref.read(authServiceProvider);
    final identityPhaseStartedAt = DateTime.now();
    final isLoggedIn = authService.isLoggedIn;
    final biometricService = ref.read(biometricServiceProvider);
    final biometricsEnabled = await biometricService.isEnabled.timeout(
      _biometricCheckTimeout,
      onTimeout: () {
        Log.warning(
          'Biometric enabled check exceeded splash budget; assuming disabled',
          {'timeoutMs': _biometricCheckTimeout.inMilliseconds},
        );
        return false;
      },
    );
    if (!mounted) return '/init-error';

    var biometricsAvailable = false;
    if (biometricsEnabled) {
      final available = await biometricService.availableBiometrics.timeout(
        _biometricCheckTimeout,
        onTimeout: () {
          Log.warning(
            'Biometric availability check exceeded splash budget; assuming unavailable',
            {'timeoutMs': _biometricCheckTimeout.inMilliseconds},
          );
          return const [];
        },
      );
      if (!mounted) return '/init-error';
      biometricsAvailable = available.isNotEmpty;
      if (!biometricsAvailable) {
        Log.warning('Biometrics enabled but unavailable - auto-disabling');
        await biometricService.setEnabled(false);
        if (!mounted) return '/init-error';
      }
    }
    _identityPhaseMs = DateTime.now()
        .difference(identityPhaseStartedAt)
        .inMilliseconds;
    _identityPhaseOutcome = 'ok';
    _logStartupPhase(
      phase: 'identity',
      durationMs: _identityPhaseMs,
      budgetMs:
          (_biometricCheckTimeout + _biometricCheckTimeout).inMilliseconds,
      outcome: _identityPhaseOutcome,
      timedOut: false,
    );

    final entitlementsPhaseStartedAt = DateTime.now();
    if (!isLoggedIn) {
      _hasProFromRestore = await _checkAnonymousProStatus().timeout(
        _anonymousProCheckTimeout,
        onTimeout: () {
          Log.warning(
            'Anonymous Pro check exceeded splash budget; assuming no restore',
            {'timeoutMs': _anonymousProCheckTimeout.inMilliseconds},
          );
          return false;
        },
      );
      if (!mounted) return '/init-error';
      _entitlementsPhaseOutcome = _hasProFromRestore
          ? 'anonymous_pro_detected'
          : 'anonymous_no_pro';
    } else {
      _entitlementsPhaseOutcome = 'authenticated_skipped';
    }
    _entitlementsPhaseMs = DateTime.now()
        .difference(entitlementsPhaseStartedAt)
        .inMilliseconds;
    _logStartupPhase(
      phase: 'entitlements',
      durationMs: _entitlementsPhaseMs,
      budgetMs: _anonymousProCheckTimeout.inMilliseconds,
      outcome: _entitlementsPhaseOutcome,
      timedOut:
          _entitlementsPhaseMs > _anonymousProCheckTimeout.inMilliseconds &&
          !isLoggedIn,
    );

    if (!mounted) return '/init-error';

    Log.info('Router: Initial navigation', {
      'onboarded': hasCompletedOnboarding,
      'loggedIn': isLoggedIn,
      'bioEnabled': biometricsEnabled,
      'bioAvailable': biometricsAvailable,
      'hasProRestore': _hasProFromRestore,
      'initError': false,
    });

    return determineStartupRoute(
      hasCompletedOnboarding: hasCompletedOnboarding,
      isLoggedIn: isLoggedIn,
      biometricsEnabled: biometricsEnabled,
      biometricsAvailable: biometricsAvailable,
      hasProRestore: _hasProFromRestore,
      hasInitError: hasInitError,
    );
  }

  void _startDeviceStateSyncBackground() {
    final usageService = ref.read(usageServiceProvider);
    unawaited(
      usageService
          .syncDeviceStateFromServer()
          .timeout(
            _deviceStateSyncTimeout,
            onTimeout: () {
              Log.warning(
                'Device state sync exceeded splash budget; continuing startup',
                {'timeoutMs': _deviceStateSyncTimeout.inMilliseconds},
              );
            },
          )
          .catchError((Object error, StackTrace stackTrace) {
            Log.warning('Device state sync failed during startup', {
              'error': '$error',
            });
          }),
    );
  }

  Future<bool> _checkAnonymousProStatus() async {
    if (!mounted) return false;

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      if (!subscriptionService.isConfigured) {
        Log.warning('RevenueCat not configured - skipping anonymous Pro check');
        return false;
      }
      final customerInfo = await Purchases.getCustomerInfo().timeout(
        _anonymousProCheckTimeout,
      );
      final hasPro = customerInfo.entitlements.active.containsKey('pro');
      if (hasPro) {
        Log.info('Anonymous user has Pro - prompting sign-in to claim');
      }
      return hasPro;
    } on TimeoutException {
      Log.warning('Anonymous Pro check timed out - continuing without restore');
      return false;
    } on Exception catch (e) {
      Log.warning('Failed to check anonymous Pro status', {'error': '$e'});
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(initStatusProvider);
    final loadingLabel = switch (status) {
      InitStatus(forceUpdateRequired: true) => 'Update required',
      InitStatus(supabaseReady: false) => 'Securing sign-in...',
      InitStatus(
        supabaseReady: true,
        revenueCatReady: false,
        timedOut: false,
      ) =>
        'Syncing subscriptions...',
      _ => 'Preparing your workspace...',
    };

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgDark, AppColors.bgDeep],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Prosepal',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 26),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                loadingLabel,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Startup initialization error surface.
class _InitErrorScreen extends StatelessWidget {
  const _InitErrorScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 54,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Startup issue detected',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'We could not complete startup checks. '
                'Please verify your connection and retry.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/splash'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                ),
                child: const Text('Retry Startup'),
              ),
            ],
          ),
        ),
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
              const Text(
                "The page you're looking for doesn't exist.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
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
