import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosepal/core/config/preference_keys.dart';
import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/core/services/usage_service.dart';
import 'package:prosepal/features/results/results_screen.dart';
import 'package:prosepal/shared/components/generation_loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_ai_service.dart';
import '../../mocks/mock_auth_service.dart';
import '../../mocks/mock_device_fingerprint_service.dart';
import '../../mocks/mock_history_service.dart';
import '../../mocks/mock_rate_limit_service.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  GenerationResult createTestResult({
    Occasion occasion = Occasion.birthday,
    Relationship relationship = Relationship.closeFriend,
    Tone tone = Tone.heartfelt,
    int messageCount = 3,
  }) {
    final now = DateTime.now().toUtc();
    return GenerationResult(
      occasion: occasion,
      relationship: relationship,
      tone: tone,
      length: MessageLength.standard,
      messages: List.generate(
        messageCount,
        (i) => GeneratedMessage(
          id: 'msg-$i',
          text: 'Test message ${i + 1} for ${occasion.label}',
          occasion: occasion,
          relationship: relationship,
          tone: tone,
          createdAt: now,
        ),
      ),
    );
  }

  Widget buildTestWidget({GenerationResult? result}) {
    final router = GoRouter(
      initialLocation: '/results',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/results',
          builder: (context, state) => const ResultsScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (result != null)
          generationResultProvider.overrideWith((ref) => result),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ResultsScreen', () {
    group('Display', () {
      testWidgets('shows app bar with title', (tester) async {
        await tester.pumpWidget(buildTestWidget(result: createTestResult()));
        await tester.pumpAndSettle();

        expect(find.text('Your Messages'), findsOneWidget);
      });

      testWidgets('shows context header with occasion info', (tester) async {
        final result = createTestResult(
          occasion: Occasion.wedding,
          relationship: Relationship.family,
          tone: Tone.formal,
        );

        await tester.pumpWidget(buildTestWidget(result: result));
        await tester.pumpAndSettle();

        expect(find.text('Wedding - Family'), findsOneWidget);
        expect(find.text('Formal tone'), findsOneWidget);
        expect(find.text('💒'), findsOneWidget);
      });

      testWidgets('shows all generated messages', (tester) async {
        final result = createTestResult();

        await tester.pumpWidget(buildTestWidget(result: result));
        await tester.pumpAndSettle();

        expect(find.text('Option 1'), findsOneWidget);
        expect(find.text('Option 2'), findsOneWidget);
        expect(find.text('Option 3'), findsOneWidget);
        expect(find.text('Test message 1 for Birthday'), findsOneWidget);
        expect(find.text('Test message 2 for Birthday'), findsOneWidget);
        expect(find.text('Test message 3 for Birthday'), findsOneWidget);
      });

      testWidgets('shows Start Over button', (tester) async {
        await tester.pumpWidget(buildTestWidget(result: createTestResult()));
        await tester.pumpAndSettle();

        expect(find.text('Start Over'), findsOneWidget);
        expect(find.byIcon(Icons.home_outlined), findsOneWidget);
        expect(find.text('Unlock Pro'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      });
    });

    group('Message Actions', () {
      testWidgets('each message has Copy button', (tester) async {
        final result = createTestResult(messageCount: 2);

        await tester.pumpWidget(buildTestWidget(result: result));
        await tester.pumpAndSettle();

        expect(find.text('Copy'), findsNWidgets(2));
      });

      testWidgets('each message has Share button', (tester) async {
        final result = createTestResult(messageCount: 2);

        await tester.pumpWidget(buildTestWidget(result: result));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.share_outlined), findsNWidgets(2));
      });
    });

    group('Navigation', () {
      testWidgets('close button navigates to home', (tester) async {
        await tester.pumpWidget(buildTestWidget(result: createTestResult()));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
      });

      testWidgets('Start Over button navigates to home', (tester) async {
        await tester.pumpWidget(buildTestWidget(result: createTestResult()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Over'));
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
      });

      testWidgets('redirects to home if no result', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
      });
    });

    group('Regeneration', () {
      testWidgets(
        'shows loading overlay and regenerates for anonymous Pro users',
        (tester) async {
          await prefs.setBool(PreferenceKeys.reviewHasRequested, true);

          final mockAi = MockAiService()
            ..simulateDelay = const Duration(milliseconds: 300);
          final mockAuth = MockAuthService()..setLoggedIn(false);
          final mockFingerprint = MockDeviceFingerprintService();
          final mockRateLimit = MockRateLimitService(
            deviceFingerprint: mockFingerprint,
          );
          final usageService = UsageService(
            prefs,
            mockFingerprint,
            mockRateLimit,
          );
          final mockHistory = MockHistoryService();

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                generationResultProvider.overrideWith(
                  (ref) => createTestResult(),
                ),
                aiServiceProvider.overrideWithValue(mockAi),
                authServiceProvider.overrideWithValue(mockAuth),
                usageServiceProvider.overrideWithValue(usageService),
                historyServiceProvider.overrideWithValue(mockHistory),
                isProProvider.overrideWith((ref) => true),
              ],
              child: MaterialApp.router(
                routerConfig: GoRouter(
                  initialLocation: '/results',
                  routes: [
                    GoRoute(
                      path: '/',
                      builder: (context, state) =>
                          const Scaffold(body: Text('Home')),
                    ),
                    GoRoute(
                      path: '/results',
                      builder: (context, state) => const ResultsScreen(),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Regenerate'));
          await tester.pump();

          expect(find.byType(GenerationLoadingOverlay), findsOneWidget);

          // Deterministic pump window (avoid pumpAndSettle with active animations).
          await tester.pump(const Duration(milliseconds: 1500));

          expect(mockAi.generateCallCount, 1);
          expect(usageService.getTotalCount(), 1);
          expect(find.byType(GenerationLoadingOverlay), findsNothing);

          // Allow delayed flutter_animate timers to drain before test teardown.
          await tester.pump(const Duration(seconds: 3));
        },
      );

      testWidgets('blocks anonymous free regenerate on results screen', (
        tester,
      ) async {
        await prefs.setBool(PreferenceKeys.reviewHasRequested, true);

        final mockAi = MockAiService();
        final mockAuth = MockAuthService()..setLoggedIn(false);
        final mockFingerprint = MockDeviceFingerprintService();
        final mockRateLimit = MockRateLimitService(
          deviceFingerprint: mockFingerprint,
        );
        final usageService = UsageService(
          prefs,
          mockFingerprint,
          mockRateLimit,
        );
        final mockHistory = MockHistoryService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              generationResultProvider.overrideWith(
                (ref) => createTestResult(),
              ),
              aiServiceProvider.overrideWithValue(mockAi),
              authServiceProvider.overrideWithValue(mockAuth),
              usageServiceProvider.overrideWithValue(usageService),
              historyServiceProvider.overrideWithValue(mockHistory),
              isProProvider.overrideWith((ref) => false),
            ],
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/results',
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) =>
                        const Scaffold(body: Text('Home')),
                  ),
                  GoRoute(
                    path: '/results',
                    builder: (context, state) => const ResultsScreen(),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Unlock Pro'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);

        await tester.tap(find.text('Unlock Pro'));
        await tester.pump(const Duration(milliseconds: 400));

        expect(mockAi.generateCallCount, 0);
        expect(usageService.getTotalCount(), 0);
        expect(
          find.text('Regenerate is a Pro feature. Upgrade to Pro!'),
          findsOneWidget,
        );

        // Dismiss paywall to avoid pending flutter_animate timers at teardown.
        final maybeLater = find.text('Maybe Later');
        if (maybeLater.evaluate().isNotEmpty) {
          await tester.tap(maybeLater);
          await tester.pump(const Duration(milliseconds: 300));
        }

        // Allow delayed animation timers to drain.
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('blocks authenticated free regenerate on results screen', (
        tester,
      ) async {
        await prefs.setBool(PreferenceKeys.reviewHasRequested, true);

        final mockAi = MockAiService();
        final mockAuth = MockAuthService()..setLoggedIn(true);
        final mockFingerprint = MockDeviceFingerprintService();
        final mockRateLimit = MockRateLimitService(
          deviceFingerprint: mockFingerprint,
        );
        final usageService = UsageService(
          prefs,
          mockFingerprint,
          mockRateLimit,
        );
        final mockHistory = MockHistoryService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              generationResultProvider.overrideWith(
                (ref) => createTestResult(),
              ),
              aiServiceProvider.overrideWithValue(mockAi),
              authServiceProvider.overrideWithValue(mockAuth),
              usageServiceProvider.overrideWithValue(usageService),
              historyServiceProvider.overrideWithValue(mockHistory),
              isProProvider.overrideWith((ref) => false),
            ],
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/results',
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) =>
                        const Scaffold(body: Text('Home')),
                  ),
                  GoRoute(
                    path: '/results',
                    builder: (context, state) => const ResultsScreen(),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Unlock Pro'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);

        await tester.tap(find.text('Unlock Pro'));
        await tester.pump(const Duration(milliseconds: 400));

        expect(mockAi.generateCallCount, 0);
        expect(usageService.getTotalCount(), 0);
        expect(
          find.text('Regenerate is a Pro feature. Upgrade to Pro!'),
          findsOneWidget,
        );

        final maybeLater = find.text('Maybe Later');
        if (maybeLater.evaluate().isNotEmpty) {
          await tester.tap(maybeLater);
          await tester.pump(const Duration(milliseconds: 300));
        }

        await tester.pump(const Duration(seconds: 3));
      });
    });

    group('All Occasions', () {
      for (final occasion in Occasion.values) {
        testWidgets('displays ${occasion.label} correctly', (tester) async {
          final result = createTestResult(occasion: occasion);

          await tester.pumpWidget(buildTestWidget(result: result));
          await tester.pumpAndSettle();

          expect(find.text(occasion.emoji), findsOneWidget);
          expect(find.textContaining(occasion.label), findsWidgets);
        });
      }
    });

    group('Accessibility', () {
      testWidgets('close button has semantic label', (tester) async {
        await tester.pumpWidget(buildTestWidget(result: createTestResult()));
        await tester.pumpAndSettle();

        final closeButton = find.byIcon(Icons.close);
        expect(closeButton, findsOneWidget);

        // Close button is inside a GestureDetector with Semantics
        final gestureDetector = find.ancestor(
          of: closeButton,
          matching: find.byType(GestureDetector),
        );
        expect(gestureDetector, findsOneWidget);
      });

      testWidgets('message text is selectable', (tester) async {
        await tester.pumpWidget(buildTestWidget(result: createTestResult()));
        await tester.pumpAndSettle();

        expect(find.byType(SelectableText), findsWidgets);
      });
    });
  });
}
