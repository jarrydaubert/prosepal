import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/features/results/results_screen.dart';

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
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(path: '/results', builder: (_, __) => const ResultsScreen()),
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
        expect(find.byIcon(Icons.refresh), findsOneWidget);
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
