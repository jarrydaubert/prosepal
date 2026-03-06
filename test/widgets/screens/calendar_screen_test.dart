import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/providers/providers.dart';
import 'package:prosepal/features/calendar/calendar_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SavedOccasion sampleOccasion() => SavedOccasion(
    id: 'occasion-1',
    occasion: Occasion.birthday,
    date: DateTime.now().add(const Duration(days: 65)),
    recipientName: 'Jarryd',
    createdAt: DateTime.now(),
  );

  Widget buildHarness(List<SavedOccasion> occasions) {
    final router = GoRouter(
      initialLocation: '/calendar',
      routes: [
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Home Screen')),
        ),
        GoRoute(
          path: '/generate',
          builder: (context, state) =>
              const Scaffold(body: Text('Generate Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        upcomingOccasionsProvider.overrideWith((ref) async => occasions),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('empty state shows primary add CTA without floating add button', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness(const []));
    await tester.pumpAndSettle();

    expect(find.text('No upcoming occasions'), findsOneWidget);
    expect(find.text('Add Your First Occasion'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Add Occasion'), findsNothing);
  });

  testWidgets('saved occasions show floating add button', (tester) async {
    await tester.pumpWidget(buildHarness([sampleOccasion()]));
    await tester.pumpAndSettle();

    expect(find.text('Birthday'), findsOneWidget);
    expect(find.text('for Jarryd'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Add Occasion'), findsOneWidget);
  });

  testWidgets('narrow occasion cards do not overflow action chips', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(576, 1280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildHarness([sampleOccasion()]));
    await tester.pumpAndSettle();

    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
