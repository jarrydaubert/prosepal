import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/occasion.dart';
import '../../../shared/theme/app_colors.dart';

class OccasionGrid extends StatelessWidget {
  const OccasionGrid({
    super.key,
    required this.occasions,
    required this.onOccasionSelected,
    this.showFirstActionHint = false,
    this.onHintDismissed,
  });

  final List<Occasion> occasions;
  final void Function(Occasion) onOccasionSelected;
  final bool showFirstActionHint;
  final VoidCallback? onHintDismissed;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Show empty state if no matches
    if (occasions.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'No occasions found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching for "birthday" or "thank you"',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final occasion = occasions[index];
        final isBirthday = occasion == Occasion.birthday;
        final shouldPulse = showFirstActionHint && isBirthday;

        final tile = _OccasionTile(
          key: ValueKey('occasion_${occasion.name}'),
          occasion: occasion,
          highlighted: shouldPulse,
          onTap: () {
            onHintDismissed?.call();
            onOccasionSelected(occasion);
          },
        );

        // Skip staggered animations if user prefers reduced motion
        // Also skip if filtered (search active) - feels snappier
        if (reduceMotion || occasions.length != Occasion.values.length) {
          // Still apply pulse to birthday even with reduced motion (uses opacity only)
          if (shouldPulse && !reduceMotion) {
            return tile
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 800.ms,
                  curve: Curves.easeInOut,
                );
          }
          return tile;
        }

        // Cap stagger delay at 8 items (2 rows) to prevent blank screen on fast scroll
        final staggerDelay = index < 8 ? index * 25 : 200;
        var animatedTile = tile
            .animate(key: ValueKey('occasion_anim_$index'))
            .fadeIn(
              delay: Duration(milliseconds: staggerDelay),
              duration: 150.ms,
            )
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              delay: Duration(milliseconds: staggerDelay),
              duration: 150.ms,
              curve: Curves.easeOut,
            );

        // Add pulse animation for Birthday when hint is shown
        if (shouldPulse) {
          animatedTile = animatedTile
              .then(delay: 300.ms)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 800.ms,
                curve: Curves.easeInOut,
              );
        }

        return animatedTile;
      }, childCount: occasions.length),
    );
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _OccasionTile extends StatefulWidget {
  const _OccasionTile({
    super.key,
    required this.occasion,
    required this.onTap,
    this.highlighted = false,
  });

  final Occasion occasion;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  State<_OccasionTile> createState() => _OccasionTileState();
}

class _OccasionTileState extends State<_OccasionTile>
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
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) => _controller.forward();

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${widget.occasion.label} occasion',
    button: true,
    hint:
        'Double tap to create a ${widget.occasion.label.toLowerCase()} message',
    child: AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.occasion.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.highlighted
                  ? AppColors.primary
                  : widget.occasion.borderColor,
              width: widget.highlighted ? 4 : 3,
            ),
            boxShadow: widget.highlighted
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.occasion.borderColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.occasion.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.occasion.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
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
