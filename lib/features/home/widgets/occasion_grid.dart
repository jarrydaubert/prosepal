import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/models/occasion.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';

class OccasionGrid extends StatelessWidget {
  const OccasionGrid({super.key, required this.onOccasionSelected});

  final void Function(Occasion) onOccasionSelected;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      // Responsive grid: adapts columns based on screen width
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200, // Each tile max 200px wide
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.4,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final occasion = Occasion.values[index];
        return OccasionTile(
              occasion: occasion,
              onTap: () => onOccasionSelected(occasion),
            )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 50),
              duration: 300.ms,
            )
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              delay: Duration(milliseconds: index * 50),
              duration: 300.ms,
              curve: Curves.easeOut,
            );
      }, childCount: Occasion.values.length),
    );
  }
}

class OccasionTile extends StatefulWidget {
  const OccasionTile({super.key, required this.occasion, required this.onTap});

  final Occasion occasion;
  final VoidCallback onTap;

  @override
  State<OccasionTile> createState() => _OccasionTileState();
}

class _OccasionTileState extends State<OccasionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) => _controller.forward();

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.occasion.label} occasion',
      button: true,
      hint: 'Double tap to create a ${widget.occasion.label.toLowerCase()} message',
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.occasion.backgroundColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: widget.occasion.borderColor),
              boxShadow: [
                BoxShadow(
                  color: widget.occasion.borderColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.occasion.emoji, style: const TextStyle(fontSize: 32)),
                const Gap(AppSpacing.sm),
                Text(
                  widget.occasion.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
