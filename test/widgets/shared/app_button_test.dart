import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/shared/atoms/app_button.dart';

void main() {
  group('AppButton', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Click Me',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Press',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Press'));
      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when disabled', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disabled'));
      expect(pressed, isFalse);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Label should be hidden when loading
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('does not call onPressed when loading', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Loading',
              onPressed: () => pressed = true,
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppButton));
      expect(pressed, isFalse);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'With Icon',
              icon: Icons.send,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });

    group('button styles', () {
      testWidgets('renders primary style as ElevatedButton', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                label: 'Primary',
                style: AppButtonStyle.primary,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('renders secondary style as ElevatedButton', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                label: 'Secondary',
                style: AppButtonStyle.secondary,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('renders outline style as OutlinedButton', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                label: 'Outline',
                style: AppButtonStyle.outline,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('renders text style as TextButton', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                label: 'Text',
                style: AppButtonStyle.text,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.byType(TextButton), findsOneWidget);
      });
    });

    group('button sizes', () {
      testWidgets('renders small size', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                label: 'Small',
                size: AppButtonSize.small,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('Small'), findsOneWidget);
      });

      testWidgets('renders medium size (default)', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                label: 'Medium',
                size: AppButtonSize.medium,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('Medium'), findsOneWidget);
      });

      testWidgets('renders large size', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                label: 'Large',
                size: AppButtonSize.large,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('Large'), findsOneWidget);
      });
    });

    testWidgets('respects isFullWidth false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Compact',
              isFullWidth: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Compact'), findsOneWidget);
    });
  });

  group('AppGradientButton', () {
    // Note: AppGradientButton uses flutter_animate which has infinite animations
    // Use pump() with duration instead of pumpAndSettle()

    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGradientButton(
              label: 'Gradient',
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Gradient'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGradientButton(
              label: 'Tap',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Tap'));
      expect(pressed, isTrue);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGradientButton(
              label: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGradientButton(
              label: 'Generate',
              icon: Icons.auto_awesome,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('does not call onPressed when loading', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGradientButton(
              label: 'Loading',
              onPressed: () => pressed = true,
              isLoading: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byType(AppGradientButton));
      expect(pressed, isFalse);
    });
  });
}
