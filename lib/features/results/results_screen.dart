import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/preference_keys.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/log_service.dart';
import '../../core/services/usage_service.dart';
import '../../shared/components/app_back_button.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_emoji.dart';
import '../../shared/components/app_surface_card.dart';
import '../../shared/components/generation_loading_overlay.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/utils/keyboard_utils.dart';
import '../paywall/paywall_sheet.dart';
import 'save_to_calendar_dialog.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  int? _copiedIndex;
  bool _isRegenerating = false;
  bool _showConfetti = false;
  Timer? _confettiHideTimer;
  late ConfettiController _confettiController;
  static const Duration _confettiDuration = Duration(milliseconds: 1400);
  static const Duration _minRegenerationOverlayDuration = Duration(
    milliseconds: 700,
  );

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: _confettiDuration);
  }

  @override
  void dispose() {
    _confettiHideTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(generationResultProvider);
    final canRegenerate = !_isRegenerating;
    final isPro = ref.watch(isProProvider);

    if (result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              result.recipientName?.isNotEmpty ?? false
                  ? 'For ${result.recipientName}'
                  : 'Your Messages',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            leading: AppBackButton(onPressed: _returnHome),
          ),
          body: Column(
            children: [
              // Context header
              _ContextHeader(result: result),

              // Messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: result.messages.length,
                  itemBuilder: (context, index) {
                    final message = result.messages[index];
                    final card = _MessageCard(
                      key: ValueKey('message_$index'),
                      message: message,
                      index: index,
                      isCopied: _copiedIndex == index,
                      onCopy: () => _copyMessage(message.text, index),
                      onShare: () => _shareMessage(message.text, index),
                    );

                    // Skip animations if user prefers reduced motion
                    if (_reduceMotion) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: card,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: card
                          .animate(key: ValueKey('msg_anim_$index'))
                          .fadeIn(duration: 200.ms)
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            duration: 200.ms,
                            curve: Curves.easeOut,
                          ),
                    );
                  },
                ),
              ),

              // Gemini attribution
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  'Built with Google Gemini',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  textAlign: TextAlign.center,
                ),
              ),

              // Bottom actions
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Start Over',
                          style: AppButtonStyle.outline,
                          icon: AppIcons.startOver,
                          onPressed: _returnHome,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: isPro ? 'Regenerate' : 'Unlock Pro',
                          icon: isPro ? AppIcons.regenerate : AppIcons.unlock,
                          isLoading: _isRegenerating,
                          onPressed: canRegenerate
                              ? () => isPro
                                    ? _regenerate(result)
                                    : _showUpgradeCTA()
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Confetti overlay only when active (reduces idle frame work).
        if (_showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.025,
                    numberOfParticles: 14,
                    gravity: 0.28,
                    minBlastForce: 8,
                    maxBlastForce: 18,
                    minimumSize: const Size(4, 4),
                    maximumSize: const Size(8, 8),
                    colors: const [
                      AppColors.primary,
                      AppColors.success,
                      Color(0xFFFFD700),
                      Color(0xFFFF69B4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_isRegenerating)
          Positioned.fill(
            child: GenerationLoadingOverlay(accentColor: result.occasion.color),
          ),
      ],
    );
  }

  Future<void> _copyMessage(String text, int index) async {
    final result = ref.read(generationResultProvider);
    final isPro = ref.read(isProProvider);
    Log.info('Message copied', {'option': index + 1});
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedIndex = index);

    // Check if this is the user's first message copy
    final prefs = await SharedPreferences.getInstance();
    final isFirstMessage =
        !(prefs.getBool(PreferenceKeys.hasGeneratedFirstMessage) ??
            PreferenceKeys.hasGeneratedFirstMessageDefault);

    if (isFirstMessage) {
      // Mark first message as done
      await prefs.setBool(PreferenceKeys.hasGeneratedFirstMessage, true);
      Log.info('First message activation', {'option': index + 1});
      Log.event('first_message_activated', {
        'occasion': result?.occasion.name ?? 'unknown',
        'option': index + 1,
      });

      // Celebration: confetti + special snackbar
      if (!_reduceMotion) {
        _confettiHideTimer?.cancel();
        if (mounted) {
          setState(() => _showConfetti = true);
        }
        _confettiController.play();
        _confettiHideTimer = Timer(
          _confettiDuration + const Duration(milliseconds: 250),
          () {
            if (mounted) {
              setState(() => _showConfetti = false);
            }
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.celebrate,
                    color: AppColors.primary,
                    size: AppSpacing.iconSizeXS,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Your first message! You just saved 10 minutes.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
      }

      // Show paywall after celebration (value-first approach)
      await Future.delayed(const Duration(seconds: 3));
      var shouldShowPaywall = !isPro;
      if (shouldShowPaywall) {
        final subscriptionService = ref.read(subscriptionServiceProvider);
        if (subscriptionService.isConfigured) {
          final runtimeIsPro = await subscriptionService.isPro();
          if (runtimeIsPro != isPro) {
            Log.warning(
              'First-message paywall entitlement mismatch corrected',
              {'providerIsPro': isPro, 'runtimeIsPro': runtimeIsPro},
            );
          }
          shouldShowPaywall = !runtimeIsPro;
        }
      }

      if (mounted && shouldShowPaywall) {
        showPaywall(context, source: 'first_message');
      }
    } else {
      // Regular copy feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.copied,
                    color: AppColors.success,
                    size: AppSpacing.iconSizeXS,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Message copied!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copiedIndex = null);

      // Show save to calendar dialog after copy (skip on first message - paywall shown)
      if (result != null && !isFirstMessage) {
        _showSaveToCalendarDialog(result);
      }
    }
  }

  void _returnHome() {
    resetGenerationForm(ref);
    ref.read(dismissHomeKeyboardProvider.notifier).state = true;
    ref.read(occasionSearchProvider.notifier).state = '';
    dismissKeyboard(context);
    context.go('/home');
  }

  void _showSaveToCalendarDialog(GenerationResult result) {
    showDialog<bool>(
      context: context,
      builder: (context) => SaveToCalendarDialog(result: result),
    ).then((saved) {
      if (saved ?? false) {
        ref.invalidate(upcomingOccasionsProvider);
      }
    });
  }

  Future<void> _shareMessage(String text, int index) async {
    Log.info('Message shared', {'option': index + 1});
    await SharePlus.instance.share(
      ShareParams(
        text: '$text\n\n— Created with Prosepal',
        subject: 'Message from Prosepal',
      ),
    );
  }

  void _showUpgradeCTA() {
    _showRegenerationError('Regenerate is a Pro feature. Upgrade to Pro!');
    if (mounted) {
      unawaited(
        showPaywall(context, source: 'regenerate_blocked', force: true),
      );
    }
  }

  Future<void> _regenerate(GenerationResult currentResult) async {
    if (_isRegenerating) return;
    final startedAt = DateTime.now();

    Log.info('Regenerate requested', {'occasion': currentResult.occasion.name});

    setState(() => _isRegenerating = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final usageService = ref.read(usageServiceProvider);
      final authService = ref.read(authServiceProvider);
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final historyService = ref.read(historyServiceProvider);
      var isPro = ref.read(isProProvider);

      // Re-check entitlement directly with RevenueCat to avoid stale provider
      // state allowing free-tier users to regenerate.
      if (subscriptionService.isConfigured) {
        final runtimeIsPro = await subscriptionService.isPro();
        if (runtimeIsPro != isPro) {
          Log.warning('Regenerate entitlement mismatch corrected', {
            'providerIsPro': isPro,
            'runtimeIsPro': runtimeIsPro,
          });
        }
        isPro = runtimeIsPro;
      }

      // Regeneration is a Pro-only feature. Free users receive one generation
      // from the wizard flow and are routed to paywall for additional options.
      if (!isPro) {
        _showUpgradeCTA();
        return;
      }

      final useUkSpelling = ref.read(isUkSpellingProvider);
      final result = await aiService.generateMessages(
        occasion: currentResult.occasion,
        relationship: currentResult.relationship,
        tone: currentResult.tone,
        length: currentResult.length,
        recipientName: currentResult.recipientName,
        personalDetails: currentResult.personalDetails,
        useUkSpelling: useUkSpelling,
      );

      if (authService.isLoggedIn) {
        try {
          final usageResult = await usageService.checkAndIncrementServerSide(
            isPro: isPro,
          );
          if (!usageResult.allowed) {
            _showRegenerationError(
              usageResult.errorMessage ?? 'Usage limit reached',
            );
            return;
          }
        } on UsageCheckException catch (e) {
          _showRegenerationError(e.message);
          return;
        }
      } else {
        await usageService.recordGeneration(isPro: isPro);
      }

      // Force Riverpod to re-read usage
      ref.invalidate(remainingGenerationsProvider);
      ref.invalidate(totalUsageProvider);

      // Update results
      ref.read(generationResultProvider.notifier).state = result;

      try {
        await historyService.saveGeneration(result);
      } on Exception catch (e) {
        Log.warning('Failed to save regenerated history', {'error': '$e'});
      }

      try {
        final reviewService = ref.read(reviewServiceProvider);
        final totalGenerations = usageService.getTotalCount();
        await reviewService.checkAndRequestReview(totalGenerations);
      } on Exception catch (e) {
        Log.warning('Failed to evaluate review prompt', {'error': '$e'});
      }

      Log.info('Regeneration success', {
        'messageCount': result.messages.length,
      });
    } on Exception catch (e) {
      Log.warning('Regeneration failed', {'error': '$e'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < _minRegenerationOverlayDuration) {
        await Future<void>.delayed(_minRegenerationOverlayDuration - elapsed);
      }
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
  }

  void _showRegenerationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _ContextHeader extends StatelessWidget {
  const _ContextHeader({required this.result});

  final GenerationResult result;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Generated ${result.occasion.label} message for ${result.relationship.label} with ${result.tone.label} tone',
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            result.occasion.backgroundColor,
            result.occasion.borderColor.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: result.occasion.borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: result.occasion.borderColor.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: result.occasion.borderColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AppEmoji(emoji: result.occasion.emoji, size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgDeep.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: const Text(
                        'READY TO USE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${result.occasion.label} - ${result.relationship.label}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${result.tone.label} tone',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Pick the version that feels most like you, then copy it as-is or tweak a line before sending.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textOnLight,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    super.key,
    required this.message,
    required this.index,
    required this.isCopied,
    required this.onCopy,
    required this.onShare,
  });

  final GeneratedMessage message;
  final int index;
  final bool isCopied;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Message option ${index + 1}',
    child: AppSurfaceCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      borderColor: AppColors.primary,
      borderWidth: AppSurfaceTokens.emphasizedBorderWidth,
      boxShadow: [
        BoxShadow(
          color: AppColors.bgDeep.withValues(alpha: 0.12),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            margin: const EdgeInsets.fromLTRB(2, 2, 2, 0),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final showDescriptor = constraints.maxWidth >= 320;
                    return Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Option ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnLight,
                            ),
                          ),
                        ),
                        if (showDescriptor) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            index == 0 ? 'Most versatile' : 'Another direction',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnLight.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Message content
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              message.text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.72,
                color: AppColors.textOnLight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: AppIcons.share,
                    label: 'Share',
                    onPressed: onShare,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                    icon: isCopied ? AppIcons.copied : AppIcons.copy,
                    label: isCopied ? 'Copied!' : 'Copy',
                    isPrimary: true,
                    isSuccess: isCopied,
                    onPressed: onCopy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isSuccess = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final color = isSuccess
        ? AppColors.success
        : isPrimary
        ? AppColors.primary
        : AppColors.textSecondary;

    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 92;
            final showLabel = constraints.maxWidth >= 72;
            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppSpacing.sm : AppSpacing.md,
                vertical: compact ? AppSpacing.sm : AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isSuccess
                    ? AppColors.success.withValues(alpha: 0.15)
                    : isPrimary
                    ? AppColors.primary
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                border: Border.all(
                  color: isPrimary ? AppColors.primaryDark : color,
                  width: isPrimary ? 1.5 : 2,
                ),
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: compact ? 12 : AppSpacing.iconSizeXS,
                    color: isPrimary ? AppColors.textOnPrimary : color,
                  ),
                  if (showLabel) ...[
                    SizedBox(width: compact ? 2 : AppSpacing.xs),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w700,
                          color: isPrimary ? AppColors.textOnPrimary : color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
