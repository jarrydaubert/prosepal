import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Canonical tokens for light-surface cards across core app screens.
class AppSurfaceTokens {
  AppSurfaceTokens._();

  static const double radius = AppSpacing.radiusLarge;
  static const double borderWidth = 1;
  static const double emphasizedBorderWidth = 2;
  static const double strongBorderWidth = 3;

  static const EdgeInsets cardPadding = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets compactPadding = EdgeInsets.all(AppSpacing.md);
}

/// Shared light-surface card primitive to keep spacing/radius/border consistent.
class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = AppSurfaceTokens.cardPadding,
    this.margin,
    this.backgroundColor = AppColors.surfaceLight,
    this.borderColor = AppColors.borderOnLight,
    this.borderWidth = AppSurfaceTokens.borderWidth,
    this.borderRadius = AppSurfaceTokens.radius,
    this.boxShadow,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    final card = Container(
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: boxShadow,
      ),
      child: content,
    );

    if (margin == null) {
      return card;
    }
    return Padding(padding: margin!, child: card);
  }
}
