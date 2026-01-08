import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A card with delightful tap feedback.
///
/// Features:
/// - Scale down on press (0.97)
/// - Subtle shadow change
/// - Haptic feedback
/// - Optional ripple effect
class TappableCard extends StatefulWidget {
  const TappableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.elevation = 0,
    this.pressedElevation = 2,
    this.enableHaptic = true,
    this.selected = false,
    this.selectedBorderColor,
    this.selectedBorderWidth = 2,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final double elevation;
  final double pressedElevation;
  final bool enableHaptic;
  final bool selected;
  final Color? selectedBorderColor;
  final double selectedBorderWidth;

  @override
  State<TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<TappableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.pressedElevation,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.enableHaptic) {
    }
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        widget.borderRadius ?? BorderRadius.circular(AppSpacing.radiusMedium);

    final effectiveBorderColor = widget.selected
        ? (widget.selectedBorderColor ?? AppColors.primary)
        : widget.borderColor;

    final effectiveBorderWidth = widget.selected
        ? widget.selectedBorderWidth
        : (widget.borderColor != null ? 1.0 : 0.0);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? AppColors.surface,
                borderRadius: borderRadius,
                border: effectiveBorderWidth > 0
                    ? Border.all(
                        color: effectiveBorderColor!,
                        width: effectiveBorderWidth,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: _elevationAnimation.value * 4,
                    offset: Offset(0, _elevationAnimation.value),
                  ),
                  if (widget.selected)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Selection chip with bounce animation
class SelectableChip extends StatefulWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.selectedColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? selectedColor;

  @override
  State<SelectableChip> createState() => _SelectableChipState();
}

class _SelectableChipState extends State<SelectableChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void didUpdateWidget(SelectableChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.selectedColor ?? AppColors.primary;

    return GestureDetector(
      onTap: () {
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final bounce = 1.0 + (_controller.value * 0.1);
          return Transform.scale(scale: bounce, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? accentColor.withValues(alpha: 0.15)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: widget.selected ? accentColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.selected
                      ? accentColor
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.selected ? accentColor : AppColors.textPrimary,
                  fontWeight: widget.selected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
              if (widget.selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_rounded, size: 16, color: accentColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
