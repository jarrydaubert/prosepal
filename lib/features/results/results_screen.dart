import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../shared/atoms/app_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  int? _copiedIndex;

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(generationResultProvider);

    if (result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Messages'),
        leading: Semantics(
          label: 'Close and return home',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () {
              resetGenerationForm(ref);
              context.go('/');
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // Context header
          Semantics(
            label:
                'Generated ${result.occasion.label} message for ${result.relationship.label} with ${result.tone.label} tone',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: AppColors.surfaceVariant,
              child: Row(
                children: [
                  Text(result.occasion.emoji, style: const TextStyle(fontSize: 24)),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.occasion.label} • ${result.relationship.label}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${result.tone.label} tone',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: result.messages.length,
              itemBuilder: (context, index) {
                final message = result.messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child:
                      _MessageCard(
                            message: message,
                            index: index,
                            isCopied: _copiedIndex == index,
                            onCopy: () => _copyMessage(message.text, index),
                            onShare: () => _shareMessage(message.text),
                          )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: index * 100),
                            duration: 300.ms,
                          )
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            delay: Duration(milliseconds: index * 100),
                            duration: 300.ms,
                            curve: Curves.easeOut,
                          ),
                );
              },
            ),
          ),

          // Bottom actions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
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
    );
  }

  Future<void> _copyMessage(String text, int index) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedIndex = index);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              Gap(AppSpacing.sm),
              Text('Message copied to clipboard!'),
            ],
          ),
          duration: Duration(seconds: 2),
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.surfaceVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with actions
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    'Option ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  // Share button
                  Semantics(
                    label: 'Share option ${index + 1}',
                    button: true,
                    child: IconButton(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_outlined, size: 20),
                      tooltip: 'Share',
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  // Copy button
                  Semantics(
                    label: isCopied
                        ? 'Option ${index + 1} copied'
                        : 'Copy option ${index + 1}',
                    button: true,
                    child: TextButton.icon(
                      onPressed: onCopy,
                      icon: Icon(isCopied ? Icons.check : Icons.copy, size: 18),
                      label: Text(isCopied ? 'Copied!' : 'Copy'),
                      style: TextButton.styleFrom(
                        foregroundColor: isCopied
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Message content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SelectableText(
                message.text,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
