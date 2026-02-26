import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/occasion.dart';
import '../../../shared/theme/app_colors.dart';

class OccasionGrid extends StatelessWidget {
  const OccasionGrid({
    super.key,
    required this.occasions,
    required this.onOccasionSelected,
  });

  final List<Occasion> occasions;
  final void Function(Occasion) onOccasionSelected;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Show empty state if no matches
    if (occasions.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'No occasions found',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
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
        final tile = _OccasionTile(
          key: ValueKey('occasion_${occasion.name}'),
          occasion: occasion,
          onTap: () => onOccasionSelected(occasion),
        );

        // Skip staggered animations if user prefers reduced motion
        // Also skip if filtered (search active) - feels snappier
        if (reduceMotion || occasions.length != Occasion.values.length) {
          return tile;
        }

        // Cap stagger delay at 8 items (2 rows) to prevent blank screen on fast scroll
        final staggerDelay = index < 8 ? index * 25 : 200;
        return tile
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
      }, childCount: occasions.length),
    );
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _OccasionTile extends StatefulWidget {
  const _OccasionTile({super.key, required this.occasion, required this.onTap});

  final Occasion occasion;
  final VoidCallback onTap;

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
      begin: 1.0,
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
  Widget build(BuildContext context) {
    return Semantics(
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
          child: Container(
            decoration: BoxDecoration(
              color: widget.occasion.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.occasion.borderColor, width: 3),
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
}
