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
import '../../shared/components/app_button.dart';
import '../../shared/theme/app_colors.dart';
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
  late ConfettiController _confettiController;

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(generationResultProvider);

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
            leading: _CloseButton(
              onPressed: () {
                resetGenerationForm(ref);
                context.go('/home');
              },
            ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Built with Google Gemini',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                          icon: Icons.home_outlined,
                          onPressed: () {
                            resetGenerationForm(ref);
                            context.go('/home');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Regenerate',
                          icon: Icons.auto_awesome,
                          isLoading: _isRegenerating,
                          onPressed: _isRegenerating
                              ? null
                              : () => _regenerate(result),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Confetti overlay for first message celebration
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [
              AppColors.primary,
              AppColors.success,
              Color(0xFFFFD700),
              Color(0xFFFF69B4),
            ],
            numberOfParticles: 20,
            gravity: 0.3,
          ),
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
        _confettiController.play();
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: AppColors.primary,
                    size: 16,
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
      if (mounted && !isPro) {
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.success,
                    size: 16,
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

  Future<void> _regenerate(GenerationResult currentResult) async {
    Log.info('Regenerate requested', {'occasion': currentResult.occasion.name});

    setState(() => _isRegenerating = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final usageService = ref.read(usageServiceProvider);
      final historyService = ref.read(historyServiceProvider);

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

      // Save to history
      await historyService.saveGeneration(result);

      // Force Riverpod to re-read usage
      ref.invalidate(remainingGenerationsProvider);
      ref.invalidate(totalUsageProvider);

      // Check for review prompt
      final reviewService = ref.read(reviewServiceProvider);
      final totalGenerations = usageService.getTotalCount();
      await reviewService.checkAndRequestReview(totalGenerations);

      // Update results
      ref.read(generationResultProvider.notifier).state = result;

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
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Semantics(
      label: 'Close and return home',
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(Icons.close, color: AppColors.primary, size: 20),
        ),
      ),
    ),
  );
}

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.occasion.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: result.occasion.borderColor, width: 3),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: result.occasion.borderColor, width: 2),
            ),
            child: Center(
              child: Text(
                result.occasion.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.occasion.label} - ${result.relationship.label}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${result.tone.label} tone',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
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
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Option ${index + 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Share button
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onPressed: onShare,
                ),
                const SizedBox(width: 8),
                // Copy button
                _ActionButton(
                  icon: isCopied ? Icons.check : Icons.copy,
                  label: isCopied ? 'Copied!' : 'Copy',
                  isPrimary: true,
                  isSuccess: isCopied,
                  onPressed: onCopy,
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
                fontSize: 15,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSuccess
                ? AppColors.success.withValues(alpha: 0.15)
                : isPrimary
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
