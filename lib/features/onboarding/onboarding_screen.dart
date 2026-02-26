import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/preference_keys.dart';
import '../../core/providers/providers.dart';
import '../../core/services/log_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../paywall/paywall_sheet.dart';

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

/// Onboarding content - concise, value-focused copy
const _onboardingPages = [
  OnboardingPageData(
    emoji: '✍️',
    title: 'The Right Words,\nRight Now',
    subtitle:
        'AI-powered messages for birthdays, thank yous, sympathy, and 40+ occasions.',
  ),
  OnboardingPageData(
    emoji: '⚡',
    title: 'Pick. Tap.\nDone.',
    subtitle:
        'Choose the occasion and tone. Get 3 personalized options instantly.',
  ),
  OnboardingPageData(
    emoji: '🎁',
    title: 'Your First One\nis Free',
    subtitle: 'No sign-up required. Try it now.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    Log.info('Onboarding started');
  }

  void _nextPage() {
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    Log.info('Onboarding completed');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PreferenceKeys.hasCompletedOnboarding, true);

    if (!mounted) return;

    // Check if user already has Pro (e.g., from App Store restore on reinstall)
    final hasPro = ref.read(isProProvider);
    final isLoggedIn = ref.read(authServiceProvider).isLoggedIn;

    if (hasPro && !isLoggedIn) {
      // Has Pro but not signed in - prompt to claim subscription
      Log.info('Onboarding: -> /auth?restore=true (has Pro, not signed in)');
      context.go('/auth?restore=true&autorestore=true');
    } else if (hasPro) {
      // Has Pro and signed in - go home
      Log.info('Onboarding: -> /home (has Pro, signed in)');
      context.go('/home');
    } else {
      // No Pro - go to home and show paywall sheet for Day 0 conversions
      // User can dismiss to try their 1 free message first
      Log.info('Onboarding: -> /home + paywall sheet (no Pro)');
      context.go('/home');
      // Show paywall sheet after navigation completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPaywall(context, source: 'onboarding');
      });
    }
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
            // Top bar with progress (skip button removed - onboarding is init cover)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.sm,
              ),
              child: Semantics(
                label:
                    'Onboarding progress: step ${_currentPage + 1} of ${_onboardingPages.length}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: (_currentPage + 1) / _onboardingPages.length,
                    ),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      backgroundColor: AppColors.primaryLight,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
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
                    pageNumber: index + 1,
                    totalPages: _onboardingPages.length,
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
                  Builder(
                    builder: (context) {
                      final reduceMotion = MediaQuery.of(
                        context,
                      ).disableAnimations;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _onboardingPages.length,
                          (index) => AnimatedContainer(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 300),
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
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Action button with scale animation
                  // On last page, wait for services to initialize before allowing "Get Started"
                  _GetStartedButton(
                    isLastPage: isLastPage,
                    onContinue: _nextPage,
                    onGetStarted: _completeOnboarding,
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

/// Get Started button that watches init status on last page.
///
/// Shows loading state if services aren't ready on the final onboarding page.
class _GetStartedButton extends ConsumerWidget {
  const _GetStartedButton({
    required this.isLastPage,
    required this.onContinue,
    required this.onGetStarted,
  });

  final bool isLastPage;
  final VoidCallback onContinue;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On last page, check if services are ready
    if (isLastPage) {
      final initStatus = ref.watch(initStatusProvider);

      // Show loading button if not ready
      if (!initStatus.criticalReady) {
        return _AnimatedButton(
          onPressed: null, // Disabled
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }

      // Ready - show Get Started
      return _AnimatedButton(
        onPressed: onGetStarted,
        child: const Text(
          'Get Started',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Not last page - show Continue
    return _AnimatedButton(
      onPressed: onContinue,
      child: const Text(
        'Continue',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Animated button with scale effect on press
class _AnimatedButton extends StatefulWidget {
  const _AnimatedButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed; // Nullable for disabled state
  final Widget child;

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTapDown: _isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: _isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: _isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed && !reduceMotion ? 0.96 : 1.0,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isEnabled ? 1.0 : 0.7,
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
      ),
    );
  }
}

class _OnboardingPageWidget extends StatelessWidget {
  const _OnboardingPageWidget({
    super.key,
    required this.page,
    required this.pageNumber,
    required this.totalPages,
  });

  final OnboardingPageData page;
  final int pageNumber;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 380;

    // Responsive sizing
    final emojiContainerSize = size.width * 0.45; // ~45% of screen width
    final emojiSize = emojiContainerSize * 0.4;
    final titleSize = isSmallScreen ? 24.0 : 28.0;
    final subtitleSize = isSmallScreen ? 15.0 : 16.0;

    final isLastPage = pageNumber == totalPages;

    return Semantics(
      label:
          'Onboarding page $pageNumber of $totalPages: ${page.title.replaceAll('\n', ' ')}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large emoji with bold border container
            _buildEmojiContainer(emojiContainerSize, emojiSize),

            const SizedBox(height: 48),

            // Title
            _buildTitle(titleSize),

            const SizedBox(height: 16),

            // Description
            _buildSubtitle(subtitleSize),

            // Pro teaser on last slide
            if (isLastPage) ...[const SizedBox(height: 24), _buildProTeaser()],
          ],
        ),
      ),
    );
  }

  Widget _buildProTeaser() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.primaryLight.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: 16,
          color: AppColors.primary.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 6),
        Text(
          'Go Pro for 500 messages/month',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.primary.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  /// No animation - instant display for snappy feel
  Widget _buildEmojiContainer(double containerSize, double emojiSize) =>
      Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.primary, width: 4),
        ),
        child: Center(
          child: Text(page.emoji, style: TextStyle(fontSize: emojiSize)),
        ),
      );

  /// No animation - instant display
  Widget _buildTitle(double titleSize) => Text(
    page.title,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: titleSize,
      fontWeight: FontWeight.bold,
      color: AppColors.primary,
    ),
  );

  /// No animation - instant display
  Widget _buildSubtitle(double subtitleSize) => Text(
    page.subtitle,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: subtitleSize,
      color: Colors.grey[700],
      height: 1.5,
    ),
  );
}
