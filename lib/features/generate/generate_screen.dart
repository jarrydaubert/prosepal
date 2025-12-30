import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/ai_service.dart';
import '../../shared/atoms/app_button.dart';
import '../../shared/molecules/generation_loading_overlay.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
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

  @override
  Widget build(BuildContext context) {
    final occasion = ref.watch(selectedOccasionProvider);
    final relationship = ref.watch(selectedRelationshipProvider);
    final tone = ref.watch(selectedToneProvider);
    final isGenerating = ref.watch(isGeneratingProvider);
    final error = ref.watch(generationErrorProvider);
    final remaining = ref.watch(remainingGenerationsProvider);
    final isPro = ref.watch(isProProvider);

    if (occasion == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(occasion.emoji),
                const Gap(AppSpacing.sm),
                Text(occasion.label),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
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
              // Progress indicator
              _StepIndicator(currentStep: _currentStep),

              // Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(context),
                ),
              ),

              // Error message with dismiss
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const Gap(AppSpacing.sm),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(generationErrorProvider.notifier).state =
                                null;
                          },
                          child: const Icon(
                            Icons.close,
                            color: AppColors.error,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
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
        // Loading overlay
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
      final canGenerate = isPro || remaining > 0;

      if (!canGenerate) {
        return AppButton(
          label: 'Upgrade to Continue',
          icon: Icons.star,
          style: AppButtonStyle.secondary,
          onPressed: () => context.pushNamed('paywall'),
        );
      }

      return AppGradientButton(
        label: isGenerating ? 'Generating...' : 'Generate Messages',
        icon: Icons.auto_awesome,
        isLoading: isGenerating,
        onPressed: canGenerate ? () => _generate(context) : null,
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

      final result = await aiService.generateMessages(
        occasion: occasion,
        relationship: relationship,
        tone: tone,
        length: length,
        recipientName: recipientName.isNotEmpty ? recipientName : null,
        personalDetails: personalDetails.isNotEmpty ? personalDetails : null,
      );

      await usageService.recordGeneration();

      // Check if we should request a review (after 3rd generation)
      final reviewService = ref.read(reviewServiceProvider);
      final totalGenerations = usageService.getTotalCount();
      await reviewService.checkAndRequestReview(totalGenerations);

      ref.read(generationResultProvider.notifier).state = result;
      ref.read(isGeneratingProvider.notifier).state = false;

      if (!mounted) return;
      context.pushNamed('results');
    } on AiNetworkException {
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state =
          'Please check your internet connection and try again.';
    } on AiRateLimitException {
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state =
          'Too many requests. Please wait a moment and try again.';
    } on AiContentBlockedException {
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state =
          'Unable to generate this message. Please try different wording.';
    } on AiServiceException catch (e) {
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state = e.message;
    } catch (e) {
      debugPrint('Unexpected generation error: $e');
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state =
          'Something went wrong. Please try again.';
    }
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
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
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
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive || isCompleted
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
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
