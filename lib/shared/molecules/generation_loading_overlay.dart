import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Overlay shown during AI message generation with rotating tips
class GenerationLoadingOverlay extends StatefulWidget {
  const GenerationLoadingOverlay({super.key});

  @override
  State<GenerationLoadingOverlay> createState() =>
      _GenerationLoadingOverlayState();
}

class _GenerationLoadingOverlayState extends State<GenerationLoadingOverlay> {
  int _currentTipIndex = 0;
  Timer? _timer;

  static const List<_Tip> _tips = [
    _Tip(emoji: '✨', text: 'Crafting the perfect words...'),
    _Tip(emoji: '💭', text: '"Prose" means natural, heartfelt language'),
    _Tip(emoji: '🎯', text: 'Each message is uniquely tailored for you'),
    _Tip(emoji: '💡', text: 'Tip: Add personal details for better results'),
    _Tip(emoji: '📝', text: "You'll get 3 options to choose from"),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_currentTipIndex];

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.screenPadding * 2),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated logo/spinner
              Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 40,
                      color: Colors.white,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1500.ms, color: Colors.white30)
                  .then()
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: 800.ms,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.05, 1.05),
                    end: const Offset(1, 1),
                    duration: 800.ms,
                  ),
              const SizedBox(height: AppSpacing.xl),
              // Tip emoji
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  tip.emoji,
                  key: ValueKey(_currentTipIndex),
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Tip text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  tip.text,
                  key: ValueKey('text_$_currentTipIndex'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _tips.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentTipIndex ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentTipIndex
                          ? AppColors.primary
                          : AppColors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tip {
  const _Tip({required this.emoji, required this.text});

  final String emoji;
  final String text;
}
