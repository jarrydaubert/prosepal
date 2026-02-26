import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonStyle { primary, secondary, outline, text }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonStyle style;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      AppButtonSize.small => AppSpacing.buttonHeightSmall,
      AppButtonSize.medium => AppSpacing.buttonHeight,
      AppButtonSize.large => AppSpacing.buttonHeight + 8,
    };

    final Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: style == AppButtonStyle.primary
                  ? AppColors.textOnPrimary
                  : AppColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSpacing.iconSizeSmall),
                SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    final buttonStyle = switch (style) {
      AppButtonStyle.primary => ElevatedButton.styleFrom(
        minimumSize: Size(isFullWidth ? double.infinity : 0, height),
      ),
      AppButtonStyle.secondary => ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        minimumSize: Size(isFullWidth ? double.infinity : 0, height),
      ),
      AppButtonStyle.outline => OutlinedButton.styleFrom(
        minimumSize: Size(isFullWidth ? double.infinity : 0, height),
      ),
      AppButtonStyle.text => TextButton.styleFrom(
        minimumSize: Size(isFullWidth ? double.infinity : 0, height),
      ),
    };

    return switch (style) {
      AppButtonStyle.primary || AppButtonStyle.secondary => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      ),
      AppButtonStyle.outline => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      ),
      AppButtonStyle.text => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      ),
    };
  }
}

/// Animated gradient button for CTAs
class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
          height: AppSpacing.buttonHeight,
          decoration: BoxDecoration(
            gradient: gradient ?? AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              color: AppColors.textOnPrimary,
                              size: AppSpacing.iconSizeSmall,
                            ),
                            SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            label,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.textOnPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: Offset(0.95, 0.95),
          end: Offset(1, 1),
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }
}
