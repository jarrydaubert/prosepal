import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/features/settings/settings_screen.dart';

import '../../mocks/mock_auth_service.dart';
import '../../mocks/mock_biometric_service.dart';
import '../../mocks/mock_subscription_service.dart';

void main() {
  late SharedPreferences prefs;
  late MockAuthService mockAuth;
  late MockBiometricService mockBiometric;
  late MockSubscriptionService mockSubscription;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockAuth = MockAuthService();
    mockBiometric = MockBiometricService();
    mockSubscription = MockSubscriptionService();
  });

  tearDown(() {
    mockAuth.dispose();
    mockBiometric.reset();
    mockSubscription.reset();
  });

  Widget buildTestWidget({
    bool isPro = false,
    String? email,
    String? displayName,
    int totalGenerated = 0,
    bool biometricsSupported = true,
    bool biometricsEnabled = false,
  }) {
    if (email != null) {
      mockAuth.setLoggedIn(true, email: email, displayName: displayName);
    }

    mockBiometric.setSupported(biometricsSupported);
    mockBiometric.setMockEnabled(biometricsEnabled);

    if (totalGenerated > 0) {
      prefs.setInt('total_generation_count', totalGenerated);
    }

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/auth',
          builder: (_, __) => const Scaffold(body: Text('Auth')),
        ),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(
          path: '/paywall',
          name: 'paywall',
          builder: (_, __) => const Scaffold(body: Text('Paywall')),
        ),
        GoRoute(
          path: '/feedback',
          name: 'feedback',
          builder: (_, __) => const Scaffold(body: Text('Feedback')),
        ),
        GoRoute(
          path: '/terms',
          name: 'terms',
          builder: (_, __) => const Scaffold(body: Text('Terms')),
        ),
        GoRoute(
          path: '/privacy',
          name: 'privacy',
          builder: (_, __) => const Scaffold(body: Text('Privacy')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(mockAuth),
        biometricServiceProvider.overrideWithValue(mockBiometric),
        subscriptionServiceProvider.overrideWithValue(mockSubscription),
        isProProvider.overrideWith((ref) => isPro),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('SettingsScreen', () {
    group('Display', () {
      testWidgets('shows app bar with title', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('shows Account section with user info', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(email: 'test@example.com', displayName: 'Test User'),
        );
        await tester.pumpAndSettle();

        expect(find.text('ACCOUNT'), findsOneWidget);
        expect(find.text('Test User'), findsOneWidget);
        expect(find.text('test@example.com'), findsOneWidget);
      });

      testWidgets('shows user initial in avatar', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(email: 'jane@example.com', displayName: 'Jane Doe'),
        );
        await tester.pumpAndSettle();

        expect(find.text('J'), findsOneWidget);
      });

      testWidgets('shows email initial when no display name', (tester) async {
        await tester.pumpWidget(buildTestWidget(email: 'bob@example.com'));
        await tester.pumpAndSettle();

        expect(find.text('B'), findsOneWidget);
      });
    });

    group('Subscription Section', () {
      testWidgets('shows Free Plan for non-pro users', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Free Plan'), findsOneWidget);
        expect(find.text('Upgrade'), findsOneWidget);
      });

      testWidgets('shows Prosepal Pro for pro users', (tester) async {
        await tester.pumpWidget(buildTestWidget(isPro: true));
        await tester.pumpAndSettle();

        expect(find.text('Prosepal Pro'), findsOneWidget);
        expect(find.text('500 messages/month'), findsOneWidget);
        expect(find.text('Upgrade'), findsNothing);
      });

      testWidgets('shows Manage Subscription for pro users', (tester) async {
        await tester.pumpWidget(buildTestWidget(isPro: true));
        await tester.pumpAndSettle();

        expect(find.text('Manage Subscription'), findsOneWidget);
      });

      testWidgets('hides Manage Subscription for free users', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Manage Subscription'), findsNothing);
      });

      testWidgets('shows Restore Purchases option', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Restore Purchases'), findsOneWidget);
      });

      testWidgets('Upgrade button shows paywall sheet for anonymous user', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap upgrade - should show paywall sheet (modal)
        await tester.tap(find.text('Upgrade'));
        await tester.pump();

        // Verify a modal bottom sheet was shown (BottomSheet widget)
        expect(find.byType(BottomSheet), findsOneWidget);
      });
    });

    group('Security Section', () {
      // Biometrics only shown for signed-in users (prevents lockout)
      testWidgets('shows biometrics when supported and signed in', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(email: 'test@example.com'));
        await tester.pumpAndSettle();

        expect(find.text('SECURITY'), findsOneWidget);
        expect(find.text('Face ID'), findsOneWidget);
      });

      testWidgets('hides biometrics for anonymous users', (tester) async {
        await tester.pumpWidget(buildTestWidget(biometricsSupported: true));
        await tester.pumpAndSettle();

        // Anonymous users don't see biometrics (prevents lockout)
        expect(find.text('SECURITY'), findsNothing);
        expect(find.text('Face ID'), findsNothing);
      });

      testWidgets('hides biometrics when not supported', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            email: 'test@example.com',
            biometricsSupported: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('SECURITY'), findsNothing);
        expect(find.text('Face ID'), findsNothing);
      });

      testWidgets('shows switch for biometrics when signed in', (tester) async {
        await tester.pumpWidget(buildTestWidget(email: 'test@example.com'));
        await tester.pumpAndSettle();

        expect(find.byType(Switch), findsOneWidget);
      });

      testWidgets('switch reflects enabled state', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(email: 'test@example.com', biometricsEnabled: true),
        );
        await tester.pumpAndSettle();

        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isTrue);
      });

      testWidgets('switch reflects disabled state', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(email: 'test@example.com', biometricsEnabled: false),
        );
        await tester.pumpAndSettle();

        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isFalse);
      });
    });

    group('Stats Section', () {
      testWidgets('shows total messages generated', (tester) async {
        await tester.pumpWidget(buildTestWidget(totalGenerated: 42));
        await tester.pumpAndSettle();

        expect(find.text('YOUR STATS'), findsOneWidget);
        expect(find.text('42 messages generated'), findsOneWidget);
      });

      testWidgets('shows 0 for new users', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('0 messages generated'), findsOneWidget);
      });
    });

    group('Support Section', () {
      testWidgets('shows support options', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll down to find Support section
        await tester.scrollUntilVisible(
          find.text('SUPPORT'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('SUPPORT'), findsOneWidget);
        expect(find.text('Help & FAQ'), findsOneWidget);
        expect(find.text('Send Feedback'), findsOneWidget);
        expect(find.text('Rate Prosepal'), findsOneWidget);
      });

      testWidgets('Send Feedback navigates to feedback screen', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Send Feedback'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Send Feedback'));
        await tester.pumpAndSettle();

        expect(find.text('Feedback'), findsOneWidget);
      });
    });

    group('Legal Section', () {
      testWidgets('shows legal options', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('LEGAL'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('LEGAL'), findsOneWidget);
        expect(find.text('Terms of Service'), findsOneWidget);
        expect(find.text('Privacy Policy'), findsOneWidget);
      });

      testWidgets('Terms navigates to terms screen', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Terms of Service'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Terms of Service'));
        await tester.pumpAndSettle();

        expect(find.text('Terms'), findsOneWidget);
      });

      testWidgets('Privacy navigates to privacy screen', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Privacy Policy'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Privacy Policy'));
        await tester.pumpAndSettle();

        expect(find.text('Privacy'), findsOneWidget);
      });
    });

    group('Account Actions', () {
      testWidgets('shows account action options for signed-in user', (
        tester,
      ) async {
        // Account actions only show for signed-in users
        await tester.pumpWidget(buildTestWidget(email: 'test@example.com'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('ACCOUNT ACTIONS'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('ACCOUNT ACTIONS'), findsOneWidget);
        expect(find.text('Sign Out'), findsOneWidget);
        expect(find.text('Delete Account'), findsOneWidget);
      });

      testWidgets('hides account actions for anonymous user', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Account actions should NOT show for anonymous users
        expect(find.text('ACCOUNT ACTIONS'), findsNothing);
        expect(find.text('Sign Out'), findsNothing);
        expect(find.text('Delete Account'), findsNothing);
      });

      testWidgets('Sign Out shows confirmation dialog', (tester) async {
        await tester.pumpWidget(buildTestWidget(email: 'test@example.com'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Sign Out'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();

        expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('Sign Out cancel dismisses dialog', (tester) async {
        await tester.pumpWidget(buildTestWidget(email: 'test@example.com'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Sign Out'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Are you sure you want to sign out?'), findsNothing);
        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('Delete Account shows confirmation dialog', (tester) async {
        await tester.pumpWidget(buildTestWidget(email: 'test@example.com'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Delete Account'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete Account'));
        await tester.pumpAndSettle();

        expect(find.textContaining('permanently delete'), findsOneWidget);
      });

      testWidgets('Delete Account cancel dismisses dialog', (tester) async {
        await tester.pumpWidget(buildTestWidget(email: 'test@example.com'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Delete Account'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete Account'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.textContaining('permanently delete'), findsNothing);
      });
    });

    group('All Sections Scrollable', () {
      testWidgets('can scroll to all section headers', (tester) async {
        await tester.pumpWidget(buildTestWidget(email: 'test@example.com'));
        await tester.pumpAndSettle();

        // Top sections visible without scroll
        expect(find.text('ACCOUNT'), findsOneWidget);
        expect(find.text('SUBSCRIPTION'), findsOneWidget);

        // Scroll to bottom sections
        await tester.scrollUntilVisible(
          find.text('ACCOUNT ACTIONS'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('ACCOUNT ACTIONS'), findsOneWidget);
      });
    });
  });
}
