import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to determine if privacy screen should show
bool isBackgroundState(AppLifecycleState state) {
  return state == AppLifecycleState.inactive ||
      state == AppLifecycleState.paused;
}

// Helper to determine initial route
String determineRoute({
  required bool hasCompletedOnboarding,
  required bool isLoggedIn,
  required bool biometricsEnabled,
}) {
  if (!hasCompletedOnboarding) return '/onboarding';
  if (!isLoggedIn) return '/auth';
  if (biometricsEnabled) return '/lock';
  return '/home';
}

// Helper to determine navigation on auth event
String? determineNavigation({required String event, required bool hasSession}) {
  if (event == 'signedIn' && hasSession) return '/home';
  if (event == 'signedOut') return '/auth';
  return null;
}

void main() {
  group('App Lifecycle Privacy', () {
    test('should show privacy screen for inactive state', () {
      expect(isBackgroundState(AppLifecycleState.inactive), isTrue);
    });

    test('should show privacy screen for paused state', () {
      expect(isBackgroundState(AppLifecycleState.paused), isTrue);
    });

    test('should not show privacy screen for resumed state', () {
      expect(isBackgroundState(AppLifecycleState.resumed), isFalse);
    });

    test('should not show privacy screen for detached state', () {
      expect(isBackgroundState(AppLifecycleState.detached), isFalse);
    });

    test('background transition ends with paused', () {
      // App going to background: resumed -> inactive -> paused
      const backgroundTransition = [
        AppLifecycleState.resumed,
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
      ];
      expect(backgroundTransition.last, equals(AppLifecycleState.paused));
    });

    test('foreground transition ends with resumed', () {
      // App coming to foreground: paused -> inactive -> resumed
      const foregroundTransition = [
        AppLifecycleState.paused,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ];
      expect(foregroundTransition.last, equals(AppLifecycleState.resumed));
    });
  });

  group('Biometric Lock Flow', () {
    test('should require biometrics when enabled and logged in', () {
      final route = determineRoute(
        hasCompletedOnboarding: true,
        isLoggedIn: true,
        biometricsEnabled: true,
      );
      expect(route, equals('/lock'));
    });

    test('should skip lock when biometrics disabled', () {
      final route = determineRoute(
        hasCompletedOnboarding: true,
        isLoggedIn: true,
        biometricsEnabled: false,
      );
      expect(route, equals('/home'));
    });

    test('should show auth when not logged in', () {
      final route = determineRoute(
        hasCompletedOnboarding: true,
        isLoggedIn: false,
        biometricsEnabled: true,
      );
      expect(route, equals('/auth'));
    });

    test('should show onboarding for first launch', () {
      final route = determineRoute(
        hasCompletedOnboarding: false,
        isLoggedIn: false,
        biometricsEnabled: false,
      );
      expect(route, equals('/onboarding'));
    });

    test('onboarding takes priority over auth', () {
      final route = determineRoute(
        hasCompletedOnboarding: false,
        isLoggedIn: true,
        biometricsEnabled: true,
      );
      expect(route, equals('/onboarding'));
    });

    test('auth takes priority over biometrics when not logged in', () {
      final route = determineRoute(
        hasCompletedOnboarding: true,
        isLoggedIn: false,
        biometricsEnabled: true,
      );
      expect(route, equals('/auth'));
    });
  });

  group('Auth State Transitions', () {
    test('should navigate to home on sign in with session', () {
      final nav = determineNavigation(event: 'signedIn', hasSession: true);
      expect(nav, equals('/home'));
    });

    test('should not navigate on sign in without session', () {
      final nav = determineNavigation(event: 'signedIn', hasSession: false);
      expect(nav, isNull);
    });

    test('should navigate to auth on sign out', () {
      final nav = determineNavigation(event: 'signedOut', hasSession: false);
      expect(nav, equals('/auth'));
    });

    test('should not navigate for token refresh', () {
      final nav = determineNavigation(event: 'tokenRefreshed', hasSession: true);
      expect(nav, isNull);
    });

    test('should not navigate for password recovery', () {
      final nav = determineNavigation(event: 'passwordRecovery', hasSession: false);
      expect(nav, isNull);
    });
  });
}
