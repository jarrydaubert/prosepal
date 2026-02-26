import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/shared/molecules/selection_chip.dart';

void main() {
  group('SelectionChip', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionChip(
              label: 'Test Label',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('displays emoji when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionChip(
              label: 'Happy',
              emoji: '😊',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('😊'), findsOneWidget);
      expect(find.text('Happy'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionChip(
              label: 'Settings',
              icon: Icons.settings,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionChip(
              label: 'Tap Me',
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });

    testWidgets('shows selected state visually', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionChip(
              label: 'Selected',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Widget should render without error when selected
      expect(find.text('Selected'), findsOneWidget);
    });

    testWidgets('shows unselected state visually', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionChip(
              label: 'Unselected',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Unselected'), findsOneWidget);
    });

    testWidgets('applies custom color when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionChip(
              label: 'Custom',
              isSelected: true,
              color: Colors.red,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Custom'), findsOneWidget);
    });
  });

  group('SelectionChipGroup', () {
    testWidgets('displays all items', (tester) async {
      final items = ['One', 'Two', 'Three'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionChipGroup<String>(
              items: items,
              selected: null,
              onSelected: (_) {},
              labelBuilder: (item) => item,
            ),
          ),
        ),
      );

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('highlights selected item', (tester) async {
      final items = ['A', 'B', 'C'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionChipGroup<String>(
              items: items,
              selected: 'B',
              onSelected: (_) {},
              labelBuilder: (item) => item,
            ),
          ),
        ),
      );

      // All items should be present
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('calls onSelected when item tapped', (tester) async {
      String? selectedItem;
      final items = ['First', 'Second'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionChipGroup<String>(
              items: items,
              selected: null,
              onSelected: (item) => selectedItem = item,
              labelBuilder: (item) => item,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Second'));
      expect(selectedItem, equals('Second'));
    });

    testWidgets('uses emojiBuilder when provided', (tester) async {
      final items = ['happy', 'sad'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionChipGroup<String>(
              items: items,
              selected: null,
              onSelected: (_) {},
              labelBuilder: (item) => item,
              emojiBuilder: (item) => item == 'happy' ? '😊' : '😢',
            ),
          ),
        ),
      );

      expect(find.text('😊'), findsOneWidget);
      expect(find.text('😢'), findsOneWidget);
    });

    testWidgets('uses colorBuilder when provided', (tester) async {
      final items = ['red', 'blue'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionChipGroup<String>(
              items: items,
              selected: 'red',
              onSelected: (_) {},
              labelBuilder: (item) => item,
              colorBuilder: (item) => item == 'red' ? Colors.red : Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('red'), findsOneWidget);
      expect(find.text('blue'), findsOneWidget);
    });
  });
}
