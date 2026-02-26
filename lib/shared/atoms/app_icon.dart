import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppIconSize { small, medium, large }

class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.icon,
    this.size = AppIconSize.medium,
    this.color,
  });

  final IconData icon;
  final AppIconSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconSize = switch (size) {
      AppIconSize.small => AppSpacing.iconSizeSmall,
      AppIconSize.medium => AppSpacing.iconSize,
      AppIconSize.large => AppSpacing.iconSizeLarge,
    };

    return Icon(
      icon,
      size: iconSize,
      color: color ?? AppColors.textPrimary,
    );
  }
}

/// Icon with circular background
class AppCircleIcon extends StatelessWidget {
  const AppCircleIcon({
    super.key,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
  });

  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: iconColor ?? AppColors.primary,
      ),
    );
  }
}

/// Emoji icon for occasions
class AppEmojiIcon extends StatelessWidget {
  const AppEmojiIcon({
    super.key,
    required this.emoji,
    this.size = 32,
    this.backgroundColor,
  });

  final String emoji;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (backgroundColor != null) {
      return Container(
        width: size * 1.5,
        height: size * 1.5,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: size),
          ),
        ),
      );
    }

    return Text(
      emoji,
      style: TextStyle(fontSize: size),
    );
  }
}
