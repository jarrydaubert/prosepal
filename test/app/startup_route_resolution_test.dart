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
      final route = await resolveStartupRouteWithTimeout(
        resolver: () async => '/home',
        timeout: const Duration(milliseconds: 50),
        fallbackRoute: '/onboarding',
      );

      expect(route, '/home');
    });

    test('returns fallback route when resolver exceeds timeout', () async {
      final route = await resolveStartupRouteWithTimeout(
        resolver: () async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return '/home';
        },
        timeout: const Duration(milliseconds: 5),
        fallbackRoute: '/onboarding',
      );

      expect(route, '/onboarding');
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
}
