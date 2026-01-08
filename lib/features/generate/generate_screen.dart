import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/log_service.dart';
import '../../core/services/usage_service.dart' show UsageCheckException;
import '../../shared/components/app_button.dart';
import '../../shared/components/generation_loading_overlay.dart';
import '../../shared/theme/app_colors.dart';
import 'widgets/details_input.dart';
import 'widgets/relationship_picker.dart';
import 'widgets/tone_selector.dart';

class GenerateScreen extends ConsumerStatefulWidget {
  const GenerateScreen({super.key});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  int _currentStep = 0;
  Timer? _errorDismissTimer;

  @override
  void dispose() {
    _errorDismissTimer?.cancel();
    super.dispose();
  }

  void _scheduleErrorDismiss() {
    _errorDismissTimer?.cancel();
    _errorDismissTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        ref.read(generationErrorProvider.notifier).state = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final occasion = ref.watch(selectedOccasionProvider);
    final relationship = ref.watch(selectedRelationshipProvider);
    final tone = ref.watch(selectedToneProvider);
    final isGenerating = ref.watch(isGeneratingProvider);
    final error = ref.watch(generationErrorProvider);
    final remaining = ref.watch(remainingGenerationsProvider);
    final isPro = ref.watch(isProProvider);

    ref.listen<String?>(generationErrorProvider, (previous, next) {
      if (next != null && previous == null) {
        _scheduleErrorDismiss();
      }
    });

    if (occasion == null) {
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
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: occasion.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: occasion.borderColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      occasion.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  occasion.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            leading: _BackButton(
              onPressed: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                } else {
                  resetGenerationForm(ref);
                  context.pop();
                }
              },
            ),
          ),
          body: Column(
            children: [
              _StepIndicator(currentStep: _currentStep),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(context),
                ),
              ),
              if (error != null)
                _ErrorBanner(
                  error: error,
                  onDismiss: () {
                    ref.read(generationErrorProvider.notifier).state = null;
                  },
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildBottomButton(
                    context,
                    occasion: occasion,
                    relationship: relationship,
                    tone: tone,
                    isGenerating: isGenerating,
                    remaining: remaining,
                    isPro: isPro,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isGenerating) const GenerationLoadingOverlay(),
      ],
    );
  }

  Widget _buildStep(BuildContext context) {
    return switch (_currentStep) {
      0 => RelationshipPicker(
        key: const ValueKey('relationship'),
        selectedRelationship: ref.watch(selectedRelationshipProvider),
        onSelected: (r) {
          ref.read(selectedRelationshipProvider.notifier).state = r;
        },
      ),
      1 => ToneSelector(
        key: const ValueKey('tone'),
        selectedTone: ref.watch(selectedToneProvider),
        onSelected: (t) {
          ref.read(selectedToneProvider.notifier).state = t;
        },
      ),
      2 => DetailsInput(
        key: const ValueKey('details'),
        recipientName: ref.watch(recipientNameProvider),
        personalDetails: ref.watch(personalDetailsProvider),
        selectedLength: ref.watch(selectedLengthProvider),
        onRecipientNameChanged: (name) {
          ref.read(recipientNameProvider.notifier).state = name;
        },
        onPersonalDetailsChanged: (details) {
          ref.read(personalDetailsProvider.notifier).state = details;
        },
        onLengthChanged: (length) {
          ref.read(selectedLengthProvider.notifier).state = length;
        },
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildBottomButton(
    BuildContext context, {
    required Occasion occasion,
    required Relationship? relationship,
    required Tone? tone,
    required bool isGenerating,
    required int remaining,
    required bool isPro,
  }) {
    final canProceed = switch (_currentStep) {
      0 => relationship != null,
      1 => tone != null,
      2 => true,
      _ => false,
    };

    final isLastStep = _currentStep == 2;

    if (isLastStep) {
      // Check if can generate
      // remaining already accounts for Pro monthly limit (500) or free limit (1)
      final canGenerate = remaining > 0;

      if (!canGenerate) {
        // Check if user is logged in - require auth before paywall
        final isLoggedIn = ref.read(authServiceProvider).isLoggedIn;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: 'Upgrade to Continue',
              icon: Icons.star,
              style: AppButtonStyle.secondary,
              onPressed: () {
                Log.info('Upgrade tapped', {
                  'source': 'generate',
                  'isLoggedIn': isLoggedIn,
                });
                if (isLoggedIn) {
                  context.pushNamed('paywall');
                } else {
                  // Require sign-in first, then redirect to paywall
                  context.push('/auth?redirect=paywall');
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              isLoggedIn ? 'Go Pro for more messages' : 'Sign in to go Pro',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        );
      }

      return AppButton(
        label: isGenerating ? 'Generating...' : 'Generate Messages',
        icon: Icons.auto_awesome,
        isLoading: isGenerating,
        onPressed: canGenerate && !isGenerating
            ? () => _generate(context)
            : null,
      );
    }

    return AppButton(
      label: 'Continue',
      onPressed: canProceed
          ? () {
              setState(() => _currentStep++);
            }
          : null,
    );
  }

  Future<void> _generate(BuildContext context) async {
    // Dismiss keyboard before starting generation
    FocusScope.of(context).unfocus();

    final occasion = ref.read(selectedOccasionProvider);
    final relationship = ref.read(selectedRelationshipProvider);
    final tone = ref.read(selectedToneProvider);
    final length = ref.read(selectedLengthProvider);
    final recipientName = ref.read(recipientNameProvider);
    final personalDetails = ref.read(personalDetailsProvider);

    if (occasion == null || relationship == null || tone == null) return;

    ref.read(isGeneratingProvider.notifier).state = true;
    ref.read(generationErrorProvider.notifier).state = null;

    try {
      final aiService = ref.read(aiServiceProvider);
      final usageService = ref.read(usageServiceProvider);
      final authService = ref.read(authServiceProvider);
      final isPro = ref.read(isProProvider);

      // Server-side usage check for authenticated users (prevents bypass)
      // Anonymous users fall back to client-side check (already done in canGenerate)
      if (authService.isLoggedIn) {
        try {
          final usageResult = await usageService.checkAndIncrementServerSide(
            isPro: isPro,
          );
          if (!usageResult.allowed) {
            ref.read(isGeneratingProvider.notifier).state = false;
            ref.read(generationErrorProvider.notifier).state =
                usageResult.errorMessage ?? 'Usage limit reached';
            return;
          }
        } on UsageCheckException catch (e) {
          ref.read(isGeneratingProvider.notifier).state = false;
          ref.read(generationErrorProvider.notifier).state = e.message;
          return;
        }
      }

      final result = await aiService.generateMessages(
        occasion: occasion,
        relationship: relationship,
        tone: tone,
        length: length,
        recipientName: recipientName.isNotEmpty ? recipientName : null,
        personalDetails: personalDetails.isNotEmpty ? personalDetails : null,
      );

      // For anonymous users, record generation client-side
      if (!authService.isLoggedIn) {
        await usageService.recordGeneration(isPro: isPro);
      }

      // Force Riverpod to re-read usage after recording
      ref.invalidate(remainingGenerationsProvider);
      ref.invalidate(totalUsageProvider);

      // Save to history for later viewing
      final historyService = ref.read(historyServiceProvider);
      await historyService.saveGeneration(result);

      // Check if we should request a review (after 3rd generation)
      final reviewService = ref.read(reviewServiceProvider);
      final totalGenerations = usageService.getTotalCount();
      await reviewService.checkAndRequestReview(totalGenerations);

      ref.read(generationResultProvider.notifier).state = result;
      ref.read(isGeneratingProvider.notifier).state = false;

      if (!mounted) return;
      unawaited(context.pushNamed('results'));
    } on AiNetworkException catch (e) {
      Log.warning('AI generation failed: network', {'error': e.message});
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state = e.message;
    } on AiRateLimitException catch (e) {
      Log.warning('AI generation failed: rate limit', {'error': e.message});
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state = e.message;
    } on AiContentBlockedException catch (e) {
      Log.warning('AI generation failed: content blocked', {
        'error': e.message,
      });
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state = e.message;
    } on AiUnavailableException catch (e) {
      Log.warning('AI generation failed: service unavailable', {
        'error': e.message,
      });
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state = e.message;
    } on AiEmptyResponseException catch (e) {
      Log.warning('AI generation failed: empty response', {'error': e.message});
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state =
          'No messages were generated. Please try again.';
    } on AiParseException catch (e) {
      Log.warning('AI generation failed: parse error', {
        'error': e.message,
        'code': e.errorCode,
        'original': '${e.originalError}',
      });
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state =
          'There was an issue processing the response. Please try again.';
    } on AiServiceException catch (e) {
      Log.warning('AI generation failed: service error', {
        'error': e.message,
        'code': e.errorCode,
      });
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state = e.message;
    } catch (e, stackTrace) {
      Log.error('AI generation failed: unexpected', e, stackTrace);
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state =
          'An unexpected error occurred. Please try again.';
    }
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
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
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  static const _stepLabels = ['Relationship', 'Tone', 'Details'];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${currentStep + 1} of 3: ${_stepLabels[currentStep]}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: List.generate(3, (index) {
            final isActive = index == currentStep;
            final isCompleted = index < currentStep;

            return Expanded(
              child: Semantics(
                label:
                    '${_stepLabels[index]}: ${isCompleted
                        ? 'completed'
                        : isActive
                        ? 'current'
                        : 'pending'}',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive || isCompleted
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(3),
                    border: isActive
                        ? Border.all(color: AppColors.primary, width: 1)
                        : null,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error, required this.onDismiss});

  final String error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: AppColors.error,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
