import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/features/paywall/paywall_screen.dart';

import '../../mocks/mock_subscription_service.dart';

/// PaywallScreen tests
///
/// Note: PaywallScreen uses flutter_animate which creates timers that need
/// manual advancing in tests. Tests focus on verifiable behavior without
/// waiting for all animations to complete.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSubscriptionService mockSubscriptionService;

  setUp(() {
    mockSubscriptionService = MockSubscriptionService();
  });

  tearDown(() {
    mockSubscriptionService.reset();
  });

  Widget createTestablePaywallScreen({
    required MockSubscriptionService subscriptionService,
    bool isPro = false,
    void Function(String)? onNavigate,
  }) {
    // Use a shell route so pop() has somewhere to go
    final router = GoRouter(
      initialLocation: '/paywall',
      routes: [
        ShellRoute(
          builder: (context, state, child) => child,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(body: Text('Home')),
            ),
            GoRoute(
              path: '/paywall',
              builder: (context, state) => const PaywallScreen(),
            ),
            GoRoute(
              path: '/privacy',
              name: 'privacy',
              builder: (context, state) {
                onNavigate?.call('privacy');
                return const Scaffold(body: Text('Privacy'));
              },
            ),
            GoRoute(
              path: '/terms',
              name: 'terms',
              builder: (context, state) {
                onNavigate?.call('terms');
                return const Scaffold(body: Text('Terms'));
              },
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        subscriptionServiceProvider.overrideWithValue(subscriptionService),
        isProProvider.overrideWith((ref) => isPro),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('PaywallScreen Fallback UI', () {
    testWidgets('shows header and features when paywall fails to load',
        (tester) async {
      // Simulate RevenueCat failure - this triggers fallback UI
      mockSubscriptionService.methodErrors['showPaywall'] = Exception('fail');

      await tester.pumpWidget(
        createTestablePaywallScreen(
          subscriptionService: mockSubscriptionService,
        ),
      );

      // Advance animations
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Unlock Prosepal Pro'), findsOneWidget);
      expect(
        find.text('Write the perfect message, every time'),
        findsOneWidget,
      );
    });

    testWidgets('displays Pro feature list', (tester) async {
      mockSubscriptionService.methodErrors['showPaywall'] = Exception('fail');

      await tester.pumpWidget(
        createTestablePaywallScreen(
          subscriptionService: mockSubscriptionService,
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Unlimited message generations'), findsOneWidget);
      expect(find.text('All occasions & tones'), findsOneWidget);
      expect(find.text('No ads, ever'), findsOneWidget);
    });

    testWidgets('shows error message when paywall fails to load', (tester) async {
      // Simulate RevenueCat failure
      mockSubscriptionService.methodErrors['showPaywall'] = Exception('fail');

      await tester.pumpWidget(
        createTestablePaywallScreen(
          subscriptionService: mockSubscriptionService,
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Unable to Load'), findsOneWidget);
    });

    testWidgets('shows close button', (tester) async {
      mockSubscriptionService.methodErrors['showPaywall'] = Exception('fail');

      await tester.pumpWidget(
        createTestablePaywallScreen(
          subscriptionService: mockSubscriptionService,
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows Try Again button when paywall fails', (tester) async {
      mockSubscriptionService.methodErrors['showPaywall'] = Exception('fail');

      await tester.pumpWidget(
        createTestablePaywallScreen(
          subscriptionService: mockSubscriptionService,
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('shows legal and restore links', (tester) async {
      mockSubscriptionService.methodErrors['showPaywall'] = Exception('fail');

      await tester.pumpWidget(
        createTestablePaywallScreen(
          subscriptionService: mockSubscriptionService,
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Terms'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
    });
  });

  group('PaywallScreen Service Integration', () {
    testWidgets('calls showPaywall on init', (tester) async {
      mockSubscriptionService.showPaywallResult = false;

      await tester.pumpWidget(
        createTestablePaywallScreen(
          subscriptionService: mockSubscriptionService,
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(mockSubscriptionService.showPaywallCallCount, 1);
    });

    testWidgets('scrolls to reveal Restore link', (tester) async {
      mockSubscriptionService.showPaywallResult = false;

      await tester.pumpWidget(
        createTestablePaywallScreen(
          subscriptionService: mockSubscriptionService,
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify Restore is findable (may need scroll)
      final restoreFinder = find.text('Restore');
      expect(restoreFinder, findsOneWidget);
    });
  });

  group('PaywallScreen Navigation', () {
    testWidgets('Privacy link triggers navigation', (tester) async {
      mockSubscriptionService.showPaywallResult = false;
      String? navigatedTo;

      await tester.pumpWidget(
        createTestablePaywallScreen(
          subscriptionService: mockSubscriptionService,
          onNavigate: (route) => navigatedTo = route,
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Scroll to reveal Privacy link
      await tester.dragUntilVisible(
        find.text('Privacy'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pump();

      await tester.tap(find.text('Privacy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(navigatedTo, 'privacy');
    });

    testWidgets('Terms link triggers navigation', (tester) async {
      mockSubscriptionService.showPaywallResult = false;
      String? navigatedTo;

      await tester.pumpWidget(
        createTestablePaywallScreen(
          subscriptionService: mockSubscriptionService,
          onNavigate: (route) => navigatedTo = route,
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Scroll to reveal Terms link
      await tester.dragUntilVisible(
        find.text('Terms'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pump();

      await tester.tap(find.text('Terms'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(navigatedTo, 'terms');
    });
  });

  group('PaywallScreen Restore Flow', () {
    testWidgets('Restore button calls restorePurchases', (tester) async {
      mockSubscriptionService.showPaywallResult = false;
      mockSubscriptionService.restoreResult = false;

      await tester.pumpWidget(
        createTestablePaywallScreen(
          subscriptionService: mockSubscriptionService,
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Scroll to reveal Restore link
      await tester.dragUntilVisible(
        find.text('Restore'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pump();

      await tester.tap(find.text('Restore'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(mockSubscriptionService.restorePurchasesCallCount, 1);
    });
  });
}
