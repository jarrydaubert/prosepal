import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/features/calendar/add_occasion_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHarness() => ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const AddOccasionSheet(),
                );
              },
              child: const Text('Open Add Occasion'),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('Add occasion sheet can be dismissed with top close button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildHarness());
    await tester.tap(find.text('Open Add Occasion'));
    await tester.pumpAndSettle();

    expect(find.text('Add Occasion'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Add Occasion'), findsNothing);
  });

  testWidgets('Add occasion sheet can be dismissed with Cancel action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildHarness());
    await tester.tap(find.text('Open Add Occasion'));
    await tester.pumpAndSettle();

    expect(find.text('Add Occasion'), findsOneWidget);

    final cancelButton = find.text('Cancel').first;
    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.text('Add Occasion'), findsNothing);
  });
}
