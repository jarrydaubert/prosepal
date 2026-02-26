/// Journey 11: Auth Race + Entitlement Edge Cases
///
/// Covers high-risk auth/monetization edges:
/// 1. Rapid double-tap on auth action should not trigger duplicate sign-ins.
/// 2. Auto-restore flow should identify user and still route safely on restore failure.
/// 3. Stale local Pro cache must not grant Pro access without matching user context.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prosepal/core/config/preference_keys.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/features/auth/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/mocks/mock_auth_service.dart';
import '../../test/mocks/mock_biometric_service.dart';
import '../../test/mocks/mock_subscription_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late MockAuthService mockAuth;
  late MockSubscriptionService mockSubscription;
  late MockBiometricService mockBiometric;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      PreferenceKeys.hasCompletedOnboarding: true,
    });
    prefs = await SharedPreferences.getInstance();
    mockAuth = MockAuthService();
    mockSubscription = MockSubscriptionService();
    mockBiometric = MockBiometricService();
  });

  tearDown(() {
    mockAuth.dispose();
    mockSubscription.dispose();
    mockBiometric.reset();
  });

  Widget buildHarness({
    required String initialLocation,
    String? redirectTo,
    bool autoRestore = false,
    bool seedStaleProCache = false,
  }) {
    if (seedStaleProCache) {
      prefs.setBool(PreferenceKeys.proStatusCache, true);
      prefs.setString(
        PreferenceKeys.proStatusCacheUserId,
        'stale-user-id-from-previous-install',
      );
    } else {
      prefs.remove(PreferenceKeys.proStatusCache);
      prefs.remove(PreferenceKeys.proStatusCacheUserId);
    }

    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/auth',
          builder: (context, state) =>
              AuthScreen(redirectTo: redirectTo, autoRestore: autoRestore),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const _ProStatusProbe(),
        ),
        GoRoute(
          path: '/terms',
          name: 'terms',
          builder: (context, state) => const Scaffold(body: Text('Terms')),
        ),
        GoRoute(
          path: '/privacy',
          name: 'privacy',
          builder: (context, state) => const Scaffold(body: Text('Privacy')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(mockAuth),
        subscriptionServiceProvider.overrideWithValue(mockSubscription),
        biometricServiceProvider.overrideWithValue(mockBiometric),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> pumpFor(
    WidgetTester tester,
    Duration total, {
    Duration step = const Duration(milliseconds: 100),
  }) async {
    var elapsed = Duration.zero;
    while (elapsed < total) {
      await tester.pump(step);
      elapsed += step;
    }
  }

  Future<void> waitForCondition(
    WidgetTester tester, {
    required bool Function() condition,
    Duration timeout = const Duration(seconds: 10),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    var elapsed = Duration.zero;
    while (elapsed < timeout) {
      if (condition()) return;
      await tester.pump(step);
      elapsed += step;
    }
  }

  group('Journey 11: Auth + Entitlement Edge Cases', () {
    testWidgets('J11.1: rapid double-tap triggers a single sign-in attempt', (
      tester,
    ) async {
      mockAuth.simulateDelay = const Duration(milliseconds: 250);

      await tester.pumpWidget(buildHarness(initialLocation: '/auth'));
      await pumpFor(tester, const Duration(milliseconds: 800));

      final googleSignIn = find.text('Sign in with Google');
      expect(googleSignIn, findsOneWidget);

      await tester.tap(googleSignIn);
      await tester.tap(googleSignIn);
      await tester.pump();
      await waitForCondition(
        tester,
        condition: () => mockAuth.signInWithGoogleCallCount == 1,
      );
      await waitForCondition(
        tester,
        condition: () => find.text('Home').evaluate().isNotEmpty,
      );

      expect(mockAuth.signInWithGoogleCallCount, 1);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('J11.2: auto-restore flow identifies user then routes safely', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(initialLocation: '/auth', autoRestore: true),
      );
      await pumpFor(tester, const Duration(milliseconds: 800));

      final googleSignIn = find.text('Sign in with Google');
      expect(googleSignIn, findsOneWidget);

      await tester.tap(googleSignIn);
      await tester.pump();
      await waitForCondition(
        tester,
        condition: () => mockSubscription.identifyUserCallCount == 1,
      );
      await waitForCondition(
        tester,
        condition: () => find.text('Home').evaluate().isNotEmpty,
      );

      expect(mockSubscription.identifyUserCallCount, 1);
      expect(mockSubscription.lastIdentifiedUserId, isNotNull);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('J11.3: stale local Pro cache does not grant Pro access', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(initialLocation: '/settings', seedStaleProCache: true),
      );
      await pumpFor(tester, const Duration(seconds: 1));

      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('PRO'), findsNothing);
    });
  });
}

class _ProStatusProbe extends ConsumerWidget {
  const _ProStatusProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);
    return Scaffold(
      body: Center(
        child: Text(
          isPro ? 'PRO' : 'FREE',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
