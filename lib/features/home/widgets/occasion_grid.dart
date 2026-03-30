import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/occasion.dart';
import '../../../shared/components/app_emoji.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/app_spacing.dart';

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
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.xxxl,
            horizontal: AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OccasionEmptyStateIcon(),
              SizedBox(height: AppSpacing.md),
              Text(
                'No occasions found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try searching for "birthday" or "thank you"',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 210,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: 100,
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
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.highlighted
                  ? AppColors.primary
                  : widget.occasion.borderColor,
              width: widget.highlighted ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (widget.highlighted ? AppColors.primary : AppColors.bgDeep)
                        .withValues(alpha: widget.highlighted ? 0.18 : 0.14),
                blurRadius: widget.highlighted ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 170;
                return Padding(
                  padding: EdgeInsets.all(compact ? 8 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: compact ? 2 : 0,
                          left: compact ? 1 : 0,
                        ),
                        child: AppEmoji(
                          emoji: widget.occasion.emoji,
                          size: compact ? 30 : 36,
                        ),
                      ),
                      Text(
                        widget.occasion.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 15 : 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textOnLight,
                          height: compact ? 1.05 : 1.1,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _OccasionEmptyStateIcon extends StatelessWidget {
  const _OccasionEmptyStateIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
      border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.45),
        width: 1.5,
      ),
    ),
    child: const Icon(
      AppIcons.search,
      size: AppSpacing.iconSizeXL,
      color: AppColors.primary,
    ),
  );
}
