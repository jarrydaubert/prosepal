import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Immersive full-screen overlay shown during AI message generation.
///
/// Features:
/// - Full-screen gradient background
/// - Floating orbs/particles animation
/// - Rotating inspirational messages
/// - Smooth 60fps animations
class GenerationLoadingOverlay extends StatefulWidget {
  const GenerationLoadingOverlay({super.key, this.accentColor});

  /// Optional accent color based on selected occasion
  final Color? accentColor;

  @override
  State<GenerationLoadingOverlay> createState() =>
      _GenerationLoadingOverlayState();
}

class _GenerationLoadingOverlayState extends State<GenerationLoadingOverlay>
    with TickerProviderStateMixin {
  int _messageIndex = 0;
  Timer? _messageTimer;
  late final AnimationController _pulseController;

  static const _messages = [
    'Finding the perfect words...',
    'Crafting something special...',
    'Adding a personal touch...',
    'Almost there...',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _messageTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Color get _accentColor => widget.accentColor ?? AppColors.primary;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Generating messages, please wait',
    child: Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _accentColor.withValues(alpha: 0.95),
              _accentColor.withValues(alpha: 0.85),
              AppColors.primaryDark.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Floating orbs background
            ..._buildFloatingOrbs(),

            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated sparkle icon
                    _buildAnimatedIcon(),
                    const SizedBox(height: AppSpacing.xxl),

                    // Rotating message
                    _buildMessage(),
                    const SizedBox(height: AppSpacing.xl),

                    // Progress dots
                    _buildProgressDots(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut);

  List<Widget> _buildFloatingOrbs() {
    final random = math.Random(42); // Fixed seed for consistent positions
    return List.generate(8, (index) {
      final size = 60.0 + random.nextDouble() * 100;
      final left = random.nextDouble() * MediaQuery.of(context).size.width;
      final top = random.nextDouble() * MediaQuery.of(context).size.height;
      final delay = random.nextInt(2000);

      return Positioned(
        left: left - size / 2,
        top: top - size / 2,
        child:
            AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 0.8 + _pulseController.value * 0.4;
                    final opacity = 0.08 + _pulseController.value * 0.12;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: opacity),
                        ),
                      ),
                    );
                  },
                )
                .animate(delay: Duration(milliseconds: delay))
                .fadeIn(duration: 1000.ms),
      );
    });
  }

  Widget _buildAnimatedIcon() =>
      Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) => Container(
                width: 100 + _pulseController.value * 15,
                height: 100 + _pulseController.value * 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.3 - _pulseController.value * 0.2,
                    ),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Inner sparkle icon
            const Icon(Icons.auto_awesome, color: Colors.white, size: 48)
                .animate(onComplete: (c) => c.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 1000.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(1, 1),
                  duration: 1000.ms,
                  curve: Curves.easeInOut,
                ),
          ],
        ),
      ).animate().scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1, 1),
        duration: 600.ms,
        curve: Curves.easeOutBack,
      );

  Widget _buildMessage() => AnimatedSwitcher(
    duration: const Duration(milliseconds: 400),
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    ),
    child: Text(
      _messages[_messageIndex],
      key: ValueKey(_messageIndex),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.center,
    ),
  );

  Widget _buildProgressDots() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      3,
      (index) =>
          Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              )
              .animate(
                delay: Duration(milliseconds: index * 200),
                onComplete: (c) => c.repeat(),
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.3, 1.3),
                duration: 600.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.3, 1.3),
                end: const Offset(1, 1),
                duration: 600.ms,
              ),
    ),
  );
}
