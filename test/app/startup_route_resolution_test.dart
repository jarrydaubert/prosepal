library;

import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/app/router.dart';

void main() {
  group('determineStartupRoute', () {
    test('returns init error route when init error is present', () {
      final route = determineStartupRoute(
        hasCompletedOnboarding: true,
        isLoggedIn: true,
        biometricsEnabled: true,
        biometricsAvailable: true,
        hasProRestore: true,
        hasInitError: true,
      );

      expect(route, '/init-error');
    });

    test('returns onboarding route when user is not onboarded', () {
      final route = determineStartupRoute(
        hasCompletedOnboarding: false,
        isLoggedIn: false,
        biometricsEnabled: false,
        biometricsAvailable: false,
        hasProRestore: false,
        hasInitError: false,
      );

      expect(route, '/onboarding');
    });

    test('returns lock when biometrics are enabled and available', () {
      final route = determineStartupRoute(
        hasCompletedOnboarding: true,
        isLoggedIn: true,
        biometricsEnabled: true,
        biometricsAvailable: true,
        hasProRestore: false,
        hasInitError: false,
      );

      expect(route, '/lock');
    });

    test('routes to auth restore when anonymous Pro restore is available', () {
      final route = determineStartupRoute(
        hasCompletedOnboarding: true,
        isLoggedIn: false,
        biometricsEnabled: false,
        biometricsAvailable: false,
        hasProRestore: true,
        hasInitError: false,
      );

      expect(route, '/auth?restore=true');
    });

    test('defaults to home when no higher-priority route applies', () {
      final route = determineStartupRoute(
        hasCompletedOnboarding: true,
        isLoggedIn: true,
        biometricsEnabled: false,
        biometricsAvailable: false,
        hasProRestore: false,
        hasInitError: false,
      );

      expect(route, '/home');
    });
  });

  group('determineStartupFallbackRoute', () {
    test('prefers init error route when init error exists', () {
      final route = determineStartupFallbackRoute(
        hasCompletedOnboarding: true,
        hasInitError: true,
      );

      expect(route, '/init-error');
    });

    test('uses onboarding fallback for first launch', () {
      final route = determineStartupFallbackRoute(
        hasCompletedOnboarding: false,
        hasInitError: false,
      );

      expect(route, '/onboarding');
    });

    test('uses home fallback for onboarded users', () {
      final route = determineStartupFallbackRoute(
        hasCompletedOnboarding: true,
        hasInitError: false,
      );

      expect(route, '/home');
    });
  });

  group('resolveStartupRouteWithTimeout', () {
    test('returns resolved route before timeout', () async {
      final result = await resolveStartupRouteWithTimeout(
        resolver: () async => '/home',
        timeout: const Duration(milliseconds: 50),
        fallbackRoute: '/onboarding',
      );

      expect(result.route, '/home');
      expect(result.timedOut, isFalse);
    });

    test('returns fallback route when resolver exceeds timeout', () async {
      final result = await resolveStartupRouteWithTimeout(
        resolver: () async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return '/home';
        },
        timeout: const Duration(milliseconds: 5),
        fallbackRoute: '/onboarding',
      );

      expect(result.route, '/onboarding');
      expect(result.timedOut, isTrue);
    });

    test(
      'does not report timeout when resolved route matches fallback route',
      () async {
        final result = await resolveStartupRouteWithTimeout(
          resolver: () async => '/onboarding',
          timeout: const Duration(milliseconds: 50),
          fallbackRoute: '/onboarding',
        );

        expect(result.route, '/onboarding');
        expect(result.timedOut, isFalse);
      },
    );

    test('marks timeout when fallback route is used after timeout', () async {
      final result = await resolveStartupRouteWithTimeout(
        resolver: () async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return '/onboarding';
        },
        timeout: const Duration(milliseconds: 1),
        fallbackRoute: '/onboarding',
      );

      expect(result.route, '/onboarding');
      expect(result.timedOut, isTrue);
    });

    test('does not swallow non-timeout errors', () async {
      expect(
        () => resolveStartupRouteWithTimeout(
          resolver: () async => throw StateError('boom'),
          timeout: const Duration(milliseconds: 30),
          fallbackRoute: '/home',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('shouldShortCircuitStartupResolution', () {
    test('short-circuits when init error is present', () {
      final result = shouldShortCircuitStartupResolution(
        hasCompletedOnboarding: true,
        hasInitError: true,
      );

      expect(result, isTrue);
    });

    test('short-circuits for first launch onboarding path', () {
      final result = shouldShortCircuitStartupResolution(
        hasCompletedOnboarding: false,
        hasInitError: false,
      );

      expect(result, isTrue);
    });

    test('does not short-circuit for normal onboarded startup', () {
      final result = shouldShortCircuitStartupResolution(
        hasCompletedOnboarding: true,
        hasInitError: false,
      );

      expect(result, isFalse);
    });
  });

  group('startup telemetry payload helpers', () {
    test('startupPhaseTelemetryParams emits stable analytics payload keys', () {
      final payload = startupPhaseTelemetryParams(
        phase: 'identity',
        durationMs: 800,
        budgetMs: 4000,
        timedOut: false,
        outcome: 'ok',
      );

      expect(payload['phase'], 'identity');
      expect(payload['duration_ms'], 800);
      expect(payload['budget_ms'], 4000);
      expect(payload['timed_out'], false);
      expect(payload['outcome'], 'ok');
    });

    test('startupRoutingSummaryAnalyticsParams normalizes nullable values', () {
      final payload = startupRoutingSummaryAnalyticsParams(
        initWaitMs: 1200,
        splashHoldMs: 200,
        routeResolutionMs: 300,
        initPhaseOutcome: 'ready',
        identityPhaseMs: 90,
        identityPhaseOutcome: 'ok',
        entitlementsPhaseMs: 110,
        entitlementsPhaseOutcome: 'authenticated_skipped',
        usedFallback: true,
        fallbackReason: null,
        resolvedRoute: null,
      );

      expect(payload['init_wait_ms'], 1200);
      expect(payload['route_resolution_ms'], 300);
      expect(payload['used_fallback'], true);
      expect(payload['fallback_reason'], 'none');
      expect(payload['resolved_route'], 'unknown');
    });
  });
}
