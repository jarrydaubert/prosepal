import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/log_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

/// Data model for onboarding pages - clean separation of concerns
class OnboardingPageData {
  const OnboardingPageData({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;
}

/// Onboarding content - easy to modify without touching widget code
const _onboardingPages = [
  OnboardingPageData(
    emoji: '💬',
    title: 'Perfect Words,\nEvery Time',
    subtitle:
        'Struggling to find the right words? Prosepal uses AI to craft heartfelt messages for any occasion.',
  ),
  OnboardingPageData(
    emoji: '✨',
    title: 'Magical\nCustomization',
    subtitle:
        "Tell us who it's for and the vibe you want. We'll generate a personalized greeting in seconds.",
  ),
  OnboardingPageData(
    emoji: '🎉',
    title: 'Try 1 Free\nMessage',
    subtitle:
        "No account needed to start. Standing in the card aisle? We've got you.",
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    Log.info('Onboarding started');
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    Log.info('Onboarding completed');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
    // Go straight to home - honor "No account needed" promise
    // Auth is only required when user exhausts free token or wants to purchase
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _onboardingPages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with progress and skip
            Padding(
              padding: const EdgeInsets.symmetric(
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
                          end: (_currentPage + 1) / _onboardingPages.length,
                        ),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          backgroundColor: AppColors.primaryLight,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.primary),
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
                      foregroundColor: AppColors.textSecondary,
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
                itemCount: _onboardingPages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _onboardingPages[index];
                  return _OnboardingPageWidget(
                    key: ValueKey('page_$index'),
                    page: page,
                  );
                },
              ),
            ),
            // Page indicators and button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                children: [
                  // Animated page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingPages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 30 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Action button with scale animation
                  _AnimatedButton(
                    onPressed: _nextPage,
                    child: Text(
                      isLastPage ? 'Get Started' : 'Continue',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated button with scale effect on press
class _AnimatedButton extends StatefulWidget {
  const _AnimatedButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback onPressed;
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
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          height: AppSpacing.buttonHeight,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
  });

  final OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 380;
    
    // Responsive sizing
    final emojiContainerSize = size.width * 0.45; // ~45% of screen width
    final emojiSize = emojiContainerSize * 0.4;
    final titleSize = isSmallScreen ? 24.0 : 28.0;
    final subtitleSize = isSmallScreen ? 15.0 : 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large emoji with bold border container
          Container(
            width: emojiContainerSize,
            height: emojiContainerSize,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.primary, width: 4),
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: TextStyle(fontSize: emojiSize),
              ),
            ),
          )
              .animate(key: ValueKey('emoji_${page.emoji}'))
              .fadeIn(duration: 400.ms)
              .scale(delay: 100.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          )
              .animate(key: ValueKey('title_${page.title}'))
              .fadeIn(delay: 300.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Description
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: subtitleSize,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ).animate(key: ValueKey('desc_${page.subtitle}')).fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}
