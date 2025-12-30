import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Unified brand colors - coral gradient throughout
  static const List<Color> _brandGradient = [
    Color(0xFFE57373),
    Color(0xFFEF9A9A),
  ];

  // Reduced from 4 to 3 pages - more concise, value-focused
  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      emoji: '💬',
      title: 'Stuck on What\nto Write?',
      subtitle:
          'Birthday, wedding, sympathy — finding the right words is hard. We make it easy.',
      gradientColors: _brandGradient,
    ),
    _OnboardingPage(
      emoji: '✨',
      title: 'AI-Crafted\nMessages',
      subtitle:
          'Tell us the occasion and relationship. Get 3 unique, heartfelt messages in seconds.',
      gradientColors: _brandGradient,
    ),
    _OnboardingPage(
      emoji: '🎉',
      title: 'Try 3 Free\nMessages',
      subtitle:
          'No account needed to start. Standing in the card aisle? We\'ve got you.',
      gradientColors: _brandGradient,
    ),
  ];

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
    if (mounted) context.go('/auth');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentGradient = _pages[_currentPage].gradientColors;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              currentGradient[0].withValues(alpha: 0.12),
              currentGradient[1].withValues(alpha: 0.06),
              Colors.white,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with progress and skip
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    // Progress indicator
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: (_currentPage + 1) / _pages.length,
                          ),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                  Color.lerp(
                                    currentGradient[0],
                                    currentGradient[1],
                                    0.5,
                                  ),
                                ),
                                minHeight: 4,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Skip button
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary.withValues(
                          alpha: 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _OnboardingPageWidget(
                      key: ValueKey(index),
                      page: page,
                      isActive: index == _currentPage,
                    );
                  },
                ),
              ),
              // Page indicators and button
              Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  children: [
                    // Dots with improved styling
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: _currentPage == index
                                ? LinearGradient(
                                    colors: _pages[_currentPage].gradientColors,
                                  )
                                : null,
                            color: _currentPage == index
                                ? null
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    // Button with gradient and scale animation
                    _AnimatedButton(
                      onPressed: _nextPage,
                      gradient: LinearGradient(
                        colors: _pages[_currentPage].gradientColors,
                      ),
                      shadowColor: _pages[_currentPage].gradientColors[0],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage ? 'Get Started' : 'Continue',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (isLastPage) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated button with scale effect on press
class _AnimatedButton extends StatefulWidget {
  const _AnimatedButton({
    required this.onPressed,
    required this.gradient,
    required this.shadowColor,
    required this.child,
  });

  final VoidCallback onPressed;
  final Gradient gradient;
  final Color shadowColor;
  final Widget child;

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: AppSpacing.buttonHeight,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withValues(alpha: 0.35),
                blurRadius: _isPressed ? 8 : 16,
                offset: Offset(0, _isPressed ? 2 : 6),
              ),
            ],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _OnboardingPageWidget extends StatelessWidget {
  const _OnboardingPageWidget({
    super.key,
    required this.page,
    required this.isActive,
  });

  final _OnboardingPage page;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding * 1.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large emoji with glassmorphism container
          Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(44),
                  boxShadow: [
                    BoxShadow(
                      color: page.gradientColors[0].withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(44),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            page.gradientColors[0].withValues(alpha: 0.15),
                            page.gradientColors[1].withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(44),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          page.emoji,
                          style: const TextStyle(fontSize: 68),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 600.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
          SizedBox(height: AppSpacing.xxl + 8),
          // Title with gradient text
          ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: page.gradientColors,
                ).createShader(bounds),
                child: Text(
                  page.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 180.ms, duration: 500.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ),
          SizedBox(height: AppSpacing.lg + 4),
          // Subtitle with improved styling
          Text(
                page.subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 350.ms, duration: 500.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
}
