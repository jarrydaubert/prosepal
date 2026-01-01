import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../shared/atoms/app_button.dart';
import '../../shared/theme/app_colors.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  int? _copiedIndex;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 300),
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
        context.go('/');
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
            title: const Text(
              'Your Messages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            leading: _CloseButton(
              onPressed: () {
                resetGenerationForm(ref);
                context.go('/');
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _MessageCard(
                        key: ValueKey('message_$index'),
                        message: message,
                        index: index,
                        isCopied: _copiedIndex == index,
                        onCopy: () => _copyMessage(message.text, index),
                        onShare: () => _shareMessage(message.text),
                      )
                          .animate(key: ValueKey('msg_anim_$index'))
                          .fadeIn(
                            delay: Duration(milliseconds: index * 100),
                            duration: 350.ms,
                          )
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            delay: Duration(milliseconds: index * 100),
                            duration: 350.ms,
                            curve: Curves.easeOut,
                          ),
                    );
                  },
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
                          icon: Icons.refresh,
                          onPressed: () {
                            resetGenerationForm(ref);
                            context.go('/');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 20,
            maxBlastForce: 30,
            minBlastForce: 10,
            emissionFrequency: 0.05,
            gravity: 0.2,
            colors: const [
              AppColors.primary,
              AppColors.primaryLight,
              Color(0xFFFFA726),
              Color(0xFF66BB6A),
              Color(0xFFB47CFF),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copyMessage(String text, int index) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    setState(() => _copiedIndex = index);

    _confettiController.play();

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

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copiedIndex = null);
    }
  }

  Future<void> _shareMessage(String text) async {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'Message from Prosepal'),
    );
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Semantics(
        label: 'Close and return home',
        button: true,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
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
}

class _ContextHeader extends StatelessWidget {
  const _ContextHeader({required this.result});

  final GenerationResult result;

  @override
  Widget build(BuildContext context) {
    return Semantics(
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
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Message option ${index + 1}',
      child: Container(
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
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
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
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
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
