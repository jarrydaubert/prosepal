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
        maxCrossAxisExtent: 220,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.9,
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
                        .withValues(alpha: widget.highlighted ? 0.22 : 0.18),
                blurRadius: widget.highlighted ? 22 : 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 170;
                return Padding(
                  padding: EdgeInsets.all(
                    compact ? AppSpacing.md : AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: compact ? 46 : 58,
                            height: compact ? 46 : 58,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.occasion.borderColor,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.occasion.borderColor.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: AppEmoji(
                                emoji: widget.occasion.emoji,
                                size: compact ? 24 : AppSpacing.iconSizeLarge,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight.withValues(
                                  alpha: 0.92,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                                border: Border.all(
                                  color: widget.highlighted
                                      ? AppColors.primary
                                      : widget.occasion.borderColor.withValues(
                                          alpha: 0.65,
                                        ),
                                ),
                              ),
                              child: Text(
                                widget.highlighted
                                    ? (compact ? 'Start' : 'Start here')
                                    : 'Occasion',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: compact ? 9 : 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: compact ? 0.2 : 0.35,
                                  color: widget.highlighted
                                      ? AppColors.primaryDark
                                      : AppColors.textOnLightSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                      Text(
                        widget.occasion.label,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 16 : 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textOnLight,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _occasionBlurb(widget.occasion),
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 12 : 12.5,
                          height: 1.4,
                          color: AppColors.textOnLightSecondary,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            AppIcons.touch,
                            size: AppSpacing.iconSizeXS,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              compact ? 'Create' : 'Tap to create',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
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

String _occasionBlurb(Occasion occasion) {
  final prompt = occasion.prompt;
  final parts = prompt.split(' - ');
  final candidate = parts.length > 1 ? parts.last : prompt;
  if (candidate.isEmpty) return 'Warm words for the moment that matters.';
  return '${candidate[0].toUpperCase()}${candidate.substring(1)}';
}
