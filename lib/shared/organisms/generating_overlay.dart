import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Immersive full-screen overlay shown during AI message generation.
///
/// Features:
/// - Gradient background with subtle animation
/// - Floating orbs/particles effect
/// - Rotating inspirational messages
/// - Smooth 60fps animations
class GeneratingOverlay extends StatefulWidget {
  const GeneratingOverlay({super.key, this.occasionColor});

  /// Optional accent color based on selected occasion
  final Color? occasionColor;

  @override
  State<GeneratingOverlay> createState() => _GeneratingOverlayState();
}

class _GeneratingOverlayState extends State<GeneratingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;
  int _messageIndex = 0;

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

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Cycle through messages
    _cycleMessages();
  }

  void _cycleMessages() {
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
        _cycleMessages();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Color get _accentColor => widget.occasionColor ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
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
                    // Animated icon/visual
                    _buildAnimatedVisual(),
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
    ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut);
  }

  List<Widget> _buildFloatingOrbs() {
    final random = math.Random(42); // Fixed seed for consistent positions
    return List.generate(8, (index) {
      final size = 60.0 + random.nextDouble() * 100;
      final left = random.nextDouble() * 400 - 50;
      final top = random.nextDouble() * 800 - 100;
      final delay = random.nextInt(2000);

      return Positioned(
            left: left,
            top: top,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 0.8 + _pulseController.value * 0.4;
                final opacity = 0.1 + _pulseController.value * 0.15;
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
            ),
          )
          .animate(delay: Duration(milliseconds: delay))
          .fadeIn(duration: 1000.ms)
          .then()
          .animate(onComplete: (c) => c.repeat(reverse: true))
          .moveY(
            begin: 0,
            end: -20,
            duration: 3000.ms,
            curve: Curves.easeInOut,
          );
    });
  }

  Widget _buildAnimatedVisual() {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateController.value * 2 * math.pi * 0.1,
          child: child,
        );
      },
      child: Container(
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
            // Outer ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Container(
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
                );
              },
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
      ),
    ).animate().scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1, 1),
      duration: 600.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildMessage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        );
      },
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
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
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
            );
      }),
    );
  }
}

/// Shows the generating overlay as a modal
Future<void> showGeneratingOverlay(
  BuildContext context, {
  Color? occasionColor,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => GeneratingOverlay(occasionColor: occasionColor),
  );
}

/// Wrapper to show/hide overlay based on loading state
class GeneratingOverlayWrapper extends StatelessWidget {
  const GeneratingOverlayWrapper({
    super.key,
    required this.isGenerating,
    required this.child,
    this.occasionColor,
  });

  final bool isGenerating;
  final Widget child;
  final Color? occasionColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isGenerating)
          Positioned.fill(
            child: GeneratingOverlay(occasionColor: occasionColor),
          ),
      ],
    );
  }
}
