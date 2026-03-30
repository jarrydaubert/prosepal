import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/device_fingerprint_service.dart'
    show DeviceCheckReason;
import '../../core/services/log_service.dart';
import '../../core/services/usage_service.dart' show UsageCheckException;
import '../../shared/components/app_back_button.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_emoji.dart';
import '../../shared/components/generation_loading_overlay.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/keyboard_utils.dart';
import '../paywall/paywall_sheet.dart';
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
  Timer? _saveDebounceTimer;
  bool _restorationAttempted = false;

  @override
  void initState() {
    super.initState();
    // Entering generation flow should always clear home search state so users
    // don't return to a stale filtered home list.
    ref.read(occasionSearchProvider.notifier).state = '';
    // Attempt to restore form state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptRestoreFormState();
    });
  }

  @override
  void dispose() {
    _errorDismissTimer?.cancel();
    _saveDebounceTimer?.cancel();
    super.dispose();
  }

  /// Attempt to restore form state from previous session.
  ///
  /// Only runs once per screen lifecycle. Skips restoration if the user
  /// has already started interacting with the form.
  Future<void> _attemptRestoreFormState() async {
    if (_restorationAttempted) return;
    _restorationAttempted = true;

    final formRestoration = ref.read(formRestorationServiceProvider);
    final state = await formRestoration.restoreGenerateFormState();

    if (state == null || !mounted) return;

    // Only restore if current state is at the beginning
    // (user hasn't started filling out form yet)
    final currentOccasion = ref.read(selectedOccasionProvider);
    if (currentOccasion != null && _currentStep > 0) {
      // User has already started - don't overwrite
      await formRestoration.clearGenerateFormState();
      return;
    }

    // Restore state to providers
    ref.read(selectedOccasionProvider.notifier).state = state.occasion;
    ref.read(selectedRelationshipProvider.notifier).state = state.relationship;
    ref.read(selectedToneProvider.notifier).state = state.tone;
    ref.read(selectedLengthProvider.notifier).state = state.messageLength;
    ref.read(recipientNameProvider.notifier).state = state.recipientName;
    ref.read(personalDetailsProvider.notifier).state = state.personalDetails;

    if (mounted) {
      setState(() => _currentStep = state.currentStep);
    }

    Log.info('Form state restored from previous session', {
      'occasion': state.occasion.label,
      'step': state.currentStep,
    });
  }

  /// Save form state (debounced to avoid excessive writes).
  void _saveFormState() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(
      const Duration(milliseconds: 500),
      _saveFormStateImmediate,
    );
  }

  /// Save form state immediately (called on step change).
  void _saveFormStateImmediate() {
    final formRestoration = ref.read(formRestorationServiceProvider);
    final occasion = ref.read(selectedOccasionProvider);

    formRestoration.saveGenerateFormState(
      occasion: occasion,
      relationship: ref.read(selectedRelationshipProvider),
      tone: ref.read(selectedToneProvider),
      messageLength: ref.read(selectedLengthProvider),
      recipientName: ref.read(recipientNameProvider),
      personalDetails: ref.read(personalDetailsProvider),
      currentStep: _currentStep,
    );
  }

  void _scheduleErrorDismiss() {
    _errorDismissTimer?.cancel();
    _errorDismissTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        ref.read(generationErrorProvider.notifier).state = null;
      }
    });
  }

  String _anonymousFreeTierError(DeviceCheckReason reason) => switch (reason) {
    DeviceCheckReason.rateLimited =>
      'Too many attempts. Please wait a moment and try again.',
    DeviceCheckReason.alreadyUsed =>
      'This device has already used its free message. Upgrade to Pro for unlimited messages!',
    DeviceCheckReason.fingerprintUnavailable ||
    DeviceCheckReason.serverUnavailable ||
    DeviceCheckReason.serverError =>
      "We can't verify your free message right now. Please try again later.",
    DeviceCheckReason.newDevice || DeviceCheckReason.notUsedYet =>
      'Free message unavailable. Please try again.',
  };

  @override
  Widget build(BuildContext context) {
    final occasion = ref.watch(selectedOccasionProvider);
    final relationship = ref.watch(selectedRelationshipProvider);
    final tone = ref.watch(selectedToneProvider);
    final isGenerating = ref.watch(isGeneratingProvider);
    final error = ref.watch(generationErrorProvider);
    final remaining = ref.watch(remainingGenerationsProvider);
    final isPro = ref.watch(isProProvider);
    final showBottomAction = _shouldShowBottomAction(
      currentStep: _currentStep,
      relationship: relationship,
      tone: tone,
    );

    ref.listen<String?>(generationErrorProvider, (previous, next) {
      if (next != null && previous == null) {
        _scheduleErrorDismiss();
      }
    });

    // Save form state when key fields change (debounced to avoid excessive writes)
    ref.listen(selectedRelationshipProvider, (_, _) => _saveFormState());
    ref.listen(selectedToneProvider, (_, _) => _saveFormState());
    ref.listen(selectedLengthProvider, (_, _) => _saveFormState());
    ref.listen(recipientNameProvider, (_, _) => _saveFormState());
    ref.listen(personalDetailsProvider, (_, _) => _saveFormState());

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
                    child: AppEmoji(emoji: occasion.emoji, size: 18),
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
            leading: AppBackButton(
              onPressed: () {
                dismissKeyboard(context);
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                  _saveFormStateImmediate();
                } else {
                  // Going back to home - clear saved form state
                  ref
                      .read(formRestorationServiceProvider)
                      .clearGenerateFormState();
                  resetGenerationForm(ref);
                  ref.read(dismissHomeKeyboardProvider.notifier).state = true;
                  ref.read(occasionSearchProvider.notifier).state = '';
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
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
              if (showBottomAction)
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
            ],
          ),
        ),
        if (isGenerating) const GenerationLoadingOverlay(),
      ],
    );
  }

  Widget _buildStep(BuildContext context) => switch (_currentStep) {
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "You've used your free message!",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Continue with Pro',
              icon: Icons.star,
              style: AppButtonStyle.secondary,
              onPressed: () {
                Log.info('Upgrade tapped', {'source': 'generate'});
                // Always show paywall - it has inline auth
                showPaywall(context, source: 'generate', force: true);
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlimited messages for every occasion',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
              _saveFormStateImmediate();
            }
          : null,
    );
  }

  bool _shouldShowBottomAction({
    required int currentStep,
    required Relationship? relationship,
    required Tone? tone,
  }) {
    if (currentStep == 2) return true;
    if (currentStep == 0) return relationship != null;
    if (currentStep == 1) return tone != null;
    return false;
  }

  Future<void> _generate(BuildContext context) async {
    final container = ProviderScope.containerOf(context);

    // Prevent concurrent generation (race condition from rapid taps)
    if (container.read(isGeneratingProvider)) return;

    // Dismiss keyboard before starting generation
    dismissKeyboard(context);

    final occasion = container.read(selectedOccasionProvider);
    final relationship = container.read(selectedRelationshipProvider);
    final tone = container.read(selectedToneProvider);
    final length = container.read(selectedLengthProvider);
    final recipientName = container.read(recipientNameProvider);
    final personalDetails = container.read(personalDetailsProvider);

    if (occasion == null || relationship == null || tone == null) return;

    final isGeneratingNotifier = container.read(isGeneratingProvider.notifier);
    final generationErrorNotifier = container.read(
      generationErrorProvider.notifier,
    );
    final generationResultNotifier = container.read(
      generationResultProvider.notifier,
    );
    final formRestorationService = container.read(
      formRestorationServiceProvider,
    );
    final reviewService = container.read(reviewServiceProvider);
    final historyService = container.read(historyServiceProvider);
    final aiService = container.read(aiServiceProvider);
    final usageService = container.read(usageServiceProvider);
    final authService = container.read(authServiceProvider);
    final isPro = container.read(isProProvider);
    final useUkSpelling = container.read(isUkSpellingProvider);

    isGeneratingNotifier.state = true;
    generationErrorNotifier.state = null;

    try {
      if (!authService.isLoggedIn && !isPro) {
        // Fast local guard prevents repeated free generations if server sync lags.
        if (!usageService.canGenerateFree()) {
          isGeneratingNotifier.state = false;
          generationErrorNotifier.state =
              'Free message already used. Upgrade to Pro for more!';
          return;
        }

        // Anonymous free tier: server-side device fingerprint check (prevents reinstall abuse)
        try {
          final deviceCheck = await usageService
              .checkDeviceFreeTierServerSide();
          if (!deviceCheck.allowed) {
            isGeneratingNotifier.state = false;
            generationErrorNotifier.state = _anonymousFreeTierError(
              deviceCheck.reason,
            );
            return;
          }
        } on Exception catch (e) {
          Log.warning('Device fingerprint check failed', {'error': '$e'});
          isGeneratingNotifier.state = false;
          generationErrorNotifier.state = _anonymousFreeTierError(
            DeviceCheckReason.serverError,
          );
          return;
        }
      }

      Log.event('generate_started', {
        'occasion': occasion.name,
        'has_personal_details': personalDetails.isNotEmpty,
      });
      final result = await aiService.generateMessages(
        occasion: occasion,
        relationship: relationship,
        tone: tone,
        length: length,
        recipientName: recipientName.isNotEmpty ? recipientName : null,
        personalDetails: personalDetails.isNotEmpty ? personalDetails : null,
        useUkSpelling: useUkSpelling,
      );

      // Canonical charge rule: only consume usage after AI returns a
      // user-presentable result. If charge verification then fails, we fail
      // closed and do not navigate to results.
      if (authService.isLoggedIn) {
        try {
          final usageResult = await usageService.checkAndIncrementServerSide(
            isPro: isPro,
          );
          if (!usageResult.allowed) {
            isGeneratingNotifier.state = false;
            generationErrorNotifier.state =
                usageResult.errorMessage ?? 'Usage limit reached';
            return;
          }
        } on UsageCheckException catch (e) {
          isGeneratingNotifier.state = false;
          generationErrorNotifier.state = e.message;
          return;
        }
      } else {
        await usageService.recordGeneration(isPro: isPro);
      }

      // Force Riverpod to re-read usage after recording
      container.invalidate(remainingGenerationsProvider);
      container.invalidate(totalUsageProvider);

      Log.event('generation_completed', {
        'occasion': occasion.name,
        'message_count': result.messages.length,
      });

      generationResultNotifier.state = result;
      isGeneratingNotifier.state = false;

      // Clear form restoration state - generation successful
      formRestorationService.clearGenerateFormState();

      try {
        await historyService.saveGeneration(result);
      } on Exception catch (e) {
        Log.warning('Failed to save generation history', {'error': '$e'});
      }

      try {
        final totalGenerations = usageService.getTotalCount();
        await reviewService.checkAndRequestReview(totalGenerations);
      } on Exception catch (e) {
        Log.warning('Failed to evaluate review prompt', {'error': '$e'});
      }

      if (!mounted) return;
      unawaited(context.pushNamed('results'));
    } on AiNetworkException catch (e) {
      Log.warning('AI generation failed: network', {'error': e.message});
      isGeneratingNotifier.state = false;
      generationErrorNotifier.state = e.message;
    } on AiRateLimitException catch (e) {
      Log.warning('AI generation failed: rate limit', {'error': e.message});
      isGeneratingNotifier.state = false;
      generationErrorNotifier.state = e.message;
    } on AiContentBlockedException catch (e) {
      Log.warning('AI generation failed: content blocked', {
        'error': e.message,
      });
      isGeneratingNotifier.state = false;
      generationErrorNotifier.state = e.message;
    } on AiUnavailableException catch (e) {
      Log.warning('AI generation failed: service unavailable', {
        'error': e.message,
      });
      isGeneratingNotifier.state = false;
      generationErrorNotifier.state = e.message;
    } on AiEmptyResponseException catch (e) {
      Log.warning('AI generation failed: empty response', {'error': e.message});
      isGeneratingNotifier.state = false;
      generationErrorNotifier.state =
          'No messages were generated. Please try again.';
    } on AiParseException catch (e) {
      Log.warning('AI generation failed: parse error', {
        'error': e.message,
        'code': e.errorCode,
        'original': '${e.originalError}',
      });
      isGeneratingNotifier.state = false;
      generationErrorNotifier.state =
          'There was an issue processing the response. Please try again.';
    } on AiServiceException catch (e) {
      Log.warning('AI generation failed: service error', {
        'error': e.message,
        'code': e.errorCode,
      });
      isGeneratingNotifier.state = false;
      generationErrorNotifier.state = e.message;
    } on Exception catch (e, stackTrace) {
      Log.error('AI generation failed: unexpected', e, stackTrace);
      isGeneratingNotifier.state = false;
      generationErrorNotifier.state =
          'An unexpected error occurred. Please try again.';
    }
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  static const _stepLabels = ['Relationship', 'Tone', 'Details'];

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Step ${currentStep + 1} of 3: ${_stepLabels[currentStep]}',
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bars
          Row(
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
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Step labels
          Row(
            children: List.generate(3, (index) {
              final isActive = index == currentStep;
              final isCompleted = index < currentStep;

              return Expanded(
                child: Text(
                  _stepLabels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive || isCompleted
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error, required this.onDismiss});

  final String error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Padding(
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
              child: const Icon(Icons.close, color: AppColors.error, size: 16),
            ),
          ),
        ],
      ),
    ),
  );
}
