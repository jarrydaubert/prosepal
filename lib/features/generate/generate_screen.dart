import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../shared/atoms/app_button.dart';
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
        context.go('/');
      });
      return SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(occasion.emoji),
            Gap(AppSpacing.sm),
            Text(occasion.label),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
              duration: Duration(milliseconds: 300),
              child: _buildStep(context),
            ),
          ),

          // Error message
          if (error != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error),
                    Gap(AppSpacing.sm),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
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
    );
  }

  Widget _buildStep(BuildContext context) {
    return switch (_currentStep) {
      0 => RelationshipPicker(
        key: ValueKey('relationship'),
        selectedRelationship: ref.watch(selectedRelationshipProvider),
        onSelected: (r) {
          ref.read(selectedRelationshipProvider.notifier).state = r;
        },
      ),
      1 => ToneSelector(
        key: ValueKey('tone'),
        selectedTone: ref.watch(selectedToneProvider),
        onSelected: (t) {
          ref.read(selectedToneProvider.notifier).state = t;
        },
      ),
      2 => DetailsInput(
        key: ValueKey('details'),
        recipientName: ref.watch(recipientNameProvider),
        personalDetails: ref.watch(personalDetailsProvider),
        onRecipientNameChanged: (name) {
          ref.read(recipientNameProvider.notifier).state = name;
        },
        onPersonalDetailsChanged: (details) {
          ref.read(personalDetailsProvider.notifier).state = details;
        },
      ),
      _ => SizedBox.shrink(),
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
        recipientName: recipientName.isNotEmpty ? recipientName : null,
        personalDetails: personalDetails.isNotEmpty ? personalDetails : null,
      );

      await usageService.recordGeneration();

      ref.read(generationResultProvider.notifier).state = result;
      ref.read(isGeneratingProvider.notifier).state = false;

      if (!mounted) return;
      context.pushNamed('results');
    } catch (e, stack) {
      debugPrint('Generation error: $e');
      debugPrint('Stack trace: $stack');
      ref.read(isGeneratingProvider.notifier).state = false;
      ref.read(generationErrorProvider.notifier).state =
          'Failed to generate messages: $e';
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color: isActive || isCompleted
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
