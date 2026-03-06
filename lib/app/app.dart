import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/preference_keys.dart';
import '../core/providers/providers.dart';
import '../core/services/auth_telemetry.dart';
import '../core/services/log_service.dart';
import '../shared/theme/app_colors.dart';
import '../shared/theme/app_theme.dart';
import 'auth_identity_sync.dart';
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
  static const _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
  static const _lifecycleResumeDebounce = Duration(milliseconds: 1200);
  static const _lockRedirectDebounce = Duration(seconds: 2);
  bool _isInBackground = false;
  bool _isBiometricResumeCheckInFlight = false;
  DateTime? _backgroundedAt;
  DateTime? _lastResumedAt;
  DateTime? _lastLockRedirectAt;
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
    // flutter_test enforces that tests restore global ErrorWidget.builder.
    // Skip customization there to avoid false negatives in test harnesses.
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    if (_isFlutterTest || bindingType.contains('Test')) return;

    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Log to Crashlytics (already configured in main.dart)
      Log.error('Widget build error', details.exception, details.stack);

      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final scheme = ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
      );

      return Container(
        color: scheme.surface,
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
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please restart the app',
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
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
    final now = DateTime.now();
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
      _backgroundedAt = now;
      Log.info('App backgrounded');
    } else if (!_isInBackground && wasInBackground) {
      if (_lastResumedAt != null &&
          now.difference(_lastResumedAt!) < _lifecycleResumeDebounce) {
        Log.info('Skip duplicate app resume callback', {
          'elapsedMs': now.difference(_lastResumedAt!).inMilliseconds,
        });
        return;
      }
      _lastResumedAt = now;
      Log.info('App resumed');
      unawaited(_checkBiometricLockOnResume(now: now));
    }
  }

  /// Check if biometric re-authentication is required on resume
  Future<void> _checkBiometricLockOnResume({DateTime? now}) async {
    if (_isBiometricResumeCheckInFlight) {
      Log.info('Skip biometric lock check - check already in flight');
      return;
    }
    _isBiometricResumeCheckInFlight = true;
    final checkedAt = now ?? DateTime.now();
    try {
      // Skip if we don't have a background timestamp
      if (_backgroundedAt == null) return;

      // Skip if backgrounded for less than timeout (e.g., brief phone call)
      final elapsed = checkedAt.difference(_backgroundedAt!);
      if (elapsed < _lockTimeout) {
        Log.info(
          'Skip biometric lock - backgrounded only ${elapsed.inSeconds}s',
        );
        return;
      }

      // Skip if already on lock screen or splash
      final currentPath = _router.routerDelegate.currentConfiguration.fullPath;
      if (currentPath == '/lock' || currentPath == '/splash') {
        return;
      }

      // Check if biometrics are enabled
      final biometricService = ref.read(biometricServiceProvider);
      final isEnabled = await biometricService.isEnabled;
      final isAvailable =
          (await biometricService.availableBiometrics).isNotEmpty;

      if (isEnabled && isAvailable) {
        if (_lastLockRedirectAt != null &&
            checkedAt.difference(_lastLockRedirectAt!) <
                _lockRedirectDebounce) {
          Log.info('Skip biometric lock redirect - recently redirected', {
            'elapsedMs': checkedAt
                .difference(_lastLockRedirectAt!)
                .inMilliseconds,
          });
          return;
        }
        _lastLockRedirectAt = checkedAt;
        Log.info('Biometric lock on resume - redirecting to /lock');
        _router.go('/lock');
      }
    } on Exception catch (e) {
      Log.warning('Failed to check biometric lock on resume', {'error': '$e'});
    } finally {
      _isBiometricResumeCheckInFlight = false;
    }
  }

  void _setupAuthListener() {
    // Skip if Supabase isn't initialized (accessing .instance throws if not)
    late final Supabase supabase;
    try {
      supabase = Supabase.instance;
      if (!supabase.isInitialized) return;
    } on Object catch (_) {
      // Supabase not initialized yet - skip auth listener
      return;
    }

    // Listen for auth state changes (OAuth callback, sign-in/out, etc.)
    _authSubscription = supabase.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final event = data.event;
      final session = data.session;
      final sessionUser = session?.user;
      final metadataProvider = AuthTelemetry.metadataProvider(
        sessionUser?.appMetadata,
      );
      final mostRecentIdentityProvider =
          AuthTelemetry.mostRecentIdentityProvider(
            sessionUser?.identities
                ?.map(
                  (identity) => {
                    'provider': identity.provider,
                    'lastSignInAt': identity.lastSignInAt,
                  },
                )
                .toList(),
            fallbackProvider: metadataProvider,
          );
      final interactiveAuthOverride = ref.read(
        interactiveAuthMethodOverrideProvider,
      );
      final effectiveSignedInProvider =
          event == AuthChangeEvent.signedIn &&
              interactiveAuthOverride != null &&
              interactiveAuthOverride.isNotEmpty
          ? interactiveAuthOverride
          : mostRecentIdentityProvider;
      final linkedProviders = AuthTelemetry.linkedProviders(
        metadataProvider: metadataProvider,
        metadataProvidersRaw: sessionUser?.appMetadata['providers'],
        identityProviders: sessionUser?.identities?.map((i) => i.provider),
      );
      final currentSessionSource = AuthTelemetry.currentSessionSource(
        hasSession: session != null,
        sessionProvider: effectiveSignedInProvider,
        fallbackProvider: metadataProvider,
      );
      Log.info('Auth state changed', {
        'event': event.name,
        'hasSession': session != null,
        'userId': AuthTelemetry.truncatedUserId(sessionUser?.id),
        'lastSignInProvider': AuthTelemetry.providerLabel(
          effectiveSignedInProvider,
        ),
        'currentSessionSource': currentSessionSource,
        'linkedProviders': AuthTelemetry.linkedProvidersValue(linkedProviders),
        'linkedProviderCount': linkedProviders.length,
      });
      unawaited(
        Log.event(
          'auth_state_changed',
          AuthTelemetry.authStateAnalyticsParams(
            event: event.name,
            hasSession: session != null,
            lastSignInProvider: AuthTelemetry.providerLabel(
              effectiveSignedInProvider,
            ),
            currentSessionSource: currentSessionSource,
            linkedProviderCount: linkedProviders.length,
          ),
        ),
      );

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut) {
        ref.read(interactiveAuthMethodOverrideProvider.notifier).state = null;
      }

      if (event == AuthChangeEvent.signedIn && session != null) {
        // Keep telemetry identity aligned with authenticated backend identity.
        await Log.setUserId(session.user.id);

        final prefs = ref.read(sharedPreferencesProvider);

        // Clear stale entitlement cache when account changes.
        final cachedProUserId = prefs.getString(
          PreferenceKeys.proStatusCacheUserId,
        );
        if (cachedProUserId != null && cachedProUserId != session.user.id) {
          await prefs.remove(PreferenceKeys.proStatusCache);
          await prefs.remove(PreferenceKeys.proStatusCacheUserId);
          ref.invalidate(customerInfoProvider);
          Log.info(
            'Auth listener: Cleared stale Pro cache after account switch',
          );
        }

        // Identify with RevenueCat to restore Pro entitlements
        try {
          final subscriptionService = ref.read(subscriptionServiceProvider);
          final hadPreSignInPro = await subscriptionService.isPro();
          if (hadPreSignInPro) {
            ref.read(proEntitlementHoldProvider.notifier).state = true;
          }
          final syncResult = await reconcileSubscriptionIdentityAfterSignIn(
            subscriptionService: subscriptionService,
            userId: session.user.id,
            hadPreSignInProOverride: hadPreSignInPro,
          );
          ref.read(proEntitlementHoldProvider.notifier).state = false;
          ref.invalidate(customerInfoProvider);
          Log.info('Auth listener: RevenueCat identified', {
            'preSignInPro': syncResult.hadPreSignInPro,
            'hasProAfterIdentify': syncResult.hasProAfterIdentify,
            'claimedViaSync': syncResult.claimedViaSync,
            'finalHasPro': syncResult.finalHasPro,
          });
        } on Exception catch (e) {
          ref.read(proEntitlementHoldProvider.notifier).state = false;
          Log.warning('Auth listener: RevenueCat identify failed', {
            'error': '$e',
          });
        }

        // Sync usage from server (restores usage after reinstall)
        try {
          await ref.read(usageServiceProvider).syncFromServer();
          ref.invalidate(remainingGenerationsProvider);
          Log.info('Auth listener: Usage synced from server');
        } on Exception catch (e) {
          Log.warning('Auth listener: Usage sync failed', {'error': '$e'});
        }

        // Auth screens own post-auth routing. Listener only synchronizes
        // identity, entitlement cache, and usage state.
      } else if (event == AuthChangeEvent.signedOut) {
        try {
          ref.read(proEntitlementHoldProvider.notifier).state = false;
          await Log.clearUserId();
          final prefs = ref.read(sharedPreferencesProvider);
          await prefs.remove(PreferenceKeys.proStatusCache);
          await prefs.remove(PreferenceKeys.proStatusCacheUserId);
          ref.invalidate(customerInfoProvider);
          ref.invalidate(remainingGenerationsProvider);

          await ref.read(usageServiceProvider).clearSyncMarker();
          Log.info('Auth listener: Sync marker cleared (signedOut)');
        } on Exception catch (e) {
          Log.warning('Auth listener: Clear sync marker failed', {
            'error': '$e',
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Prosepal',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    routerConfig: _router,
  );
}
