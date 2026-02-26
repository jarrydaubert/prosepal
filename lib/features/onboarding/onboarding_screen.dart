import 'package:flutter/material.dart';
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

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      emoji: '✨',
      title: 'Perfect Words for\nEvery Occasion',
      subtitle:
          'Birthday, wedding, sympathy, thank you — we help you write heartfelt messages that truly connect.',
      gradientColors: [Color(0xFFE57373), Color(0xFFFF8A65)],
    ),
    _OnboardingPage(
      emoji: '🎯',
      title: 'Personalized\nJust for You',
      subtitle:
          'Tell us about the recipient and occasion, and our AI crafts 3 unique message options tailored to your needs.',
      gradientColors: [Color(0xFF7E57C2), Color(0xFFB388FF)],
    ),
    _OnboardingPage(
      emoji: '⚡',
      title: 'Quick & Easy',
      subtitle:
          'Standing in the card aisle? Get beautiful messages in seconds. Copy, paste, done.',
      gradientColors: [Color(0xFF26A69A), Color(0xFF80CBC4)],
    ),
    _OnboardingPage(
      emoji: '📝',
      title: 'Why Prosepal?',
      subtitle:
          '"Prose" (prohz) means everyday language — warm, natural words. We\'re your pal for heartfelt messages.',
      gradientColors: [Color(0xFFFFB74D), Color(0xFFFFD54F)],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 400),
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

    return Scaffold(
      body: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              currentGradient[0].withValues(alpha: 0.15),
              currentGradient[1].withValues(alpha: 0.08),
              Colors.white,
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: Text('Skip'),
                  ),
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
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: _currentPage == index
                                ? LinearGradient(
                                    colors: _pages[_currentPage].gradientColors,
                                  )
                                : null,
                            color: _currentPage == index
                                ? null
                                : AppColors.textHint.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    // Button with gradient
                    Container(
                      width: double.infinity,
                      height: AppSpacing.buttonHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _pages[_currentPage].gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _pages[_currentPage].gradientColors[0]
                                .withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMedium,
                            ),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Continue',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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
          // Large emoji with gradient background
          Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      page.gradientColors[0].withValues(alpha: 0.2),
                      page.gradientColors[1].withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: page.gradientColors[0].withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(page.emoji, style: TextStyle(fontSize: 64)),
                ),
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 500.ms)
              .scale(
                begin: Offset(0.8, 0.8),
                end: Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),
          SizedBox(height: AppSpacing.xxl),
          // Title with gradient text
          ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: page.gradientColors,
                ).createShader(bounds),
                child: Text(
                  page.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0, duration: 400.ms),
          SizedBox(height: AppSpacing.lg),
          // Subtitle
          Text(
                page.subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0, duration: 400.ms),
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
