import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/shared/components/app_surface_card.dart';
import 'package:prosepal/shared/theme/app_colors.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets('AppSurfaceCard applies canonical light-surface defaults', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const AppSurfaceCard(child: SizedBox(width: 20, height: 20))),
    );

    final decoratedContainerFinder = find.descendant(
      of: find.byType(AppSurfaceCard),
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      ),
    );
    expect(decoratedContainerFinder, findsOneWidget);

    final container = tester.widget<Container>(decoratedContainerFinder);
    final decoration = container.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    final borderRadius = decoration.borderRadius! as BorderRadius;

    expect(decoration.color, AppColors.surfaceLight);
    expect(border.top.color, AppColors.borderOnLight);
    expect(border.top.width, AppSurfaceTokens.borderWidth);
    expect(borderRadius.topLeft.x, AppSurfaceTokens.radius);
    expect(borderRadius.topRight.x, AppSurfaceTokens.radius);

    final contentPaddingFinder = find.descendant(
      of: find.byType(AppSurfaceCard),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Padding && widget.padding == AppSurfaceTokens.cardPadding,
      ),
    );
    expect(contentPaddingFinder, findsOneWidget);
    final contentPadding = tester.widget<Padding>(contentPaddingFinder);
    expect(contentPadding.padding, AppSurfaceTokens.cardPadding);
  });

  testWidgets('AppSurfaceCard supports custom variant styling', (tester) async {
    final shadow = BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.2),
      blurRadius: 6,
      offset: const Offset(0, 2),
    );

    await tester.pumpWidget(
      _wrap(
        AppSurfaceCard(
          padding: null,
          margin: const EdgeInsets.all(10),
          backgroundColor: AppColors.primaryLight,
          borderColor: AppColors.primary,
          borderWidth: AppSurfaceTokens.strongBorderWidth,
          borderRadius: 20,
          clipBehavior: Clip.antiAlias,
          boxShadow: [shadow],
          child: const SizedBox(width: 32, height: 24),
        ),
      ),
    );

    final decoratedContainerFinder = find.descendant(
      of: find.byType(AppSurfaceCard),
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      ),
    );
    expect(decoratedContainerFinder, findsOneWidget);
    final container = tester.widget<Container>(decoratedContainerFinder);
    final decoration = container.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    final borderRadius = decoration.borderRadius! as BorderRadius;

    expect(container.clipBehavior, Clip.antiAlias);
    expect(decoration.color, AppColors.primaryLight);
    expect(border.top.color, AppColors.primary);
    expect(border.top.width, AppSurfaceTokens.strongBorderWidth);
    expect(borderRadius.topLeft.x, 20);
    expect(decoration.boxShadow, [shadow]);

    final marginPaddingFinder = find.descendant(
      of: find.byType(AppSurfaceCard),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Padding && widget.padding == const EdgeInsets.all(10),
      ),
    );
    expect(marginPaddingFinder, findsOneWidget);
    final marginPadding = tester.widget<Padding>(marginPaddingFinder);
    expect(marginPadding.padding, const EdgeInsets.all(10));
  });
}
