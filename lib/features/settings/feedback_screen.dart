import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/providers.dart';
import '../../core/services/diagnostic_service.dart';
import '../../shared/atoms/app_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _controller = TextEditingController();
  bool _isSending = false;
  bool _includeLogs = true; // Default ON to help troubleshooting

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final message = _controller.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }

    setState(() => _isSending = true);

    String fullMessage = message;
    if (_includeLogs) {
      final isRcConfigured = ref.read(subscriptionServiceProvider).isConfigured;
      final diagnosticReport = await DiagnosticService.generateReport(
        isRevenueCatConfigured: isRcConfigured,
      );
      fullMessage = '$message\n\n$diagnosticReport';
    }

    final subject = Uri.encodeComponent('Prosepal Feedback');
    final body = Uri.encodeComponent(fullMessage);

    final uri = Uri.parse(
      'mailto:support@prosepal.app?subject=$subject&body=$body',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      if (mounted) Navigator.pop(context);
    } else {
      // Fallback: offer to copy email content
      if (mounted) {
        final shouldCopy = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No email app found'),
            content: const Text(
              'Copy feedback to clipboard? You can paste it into your email app and send to support@prosepal.app',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Copy'),
              ),
            ],
          ),
        );

        if (shouldCopy == true && mounted) {
          await Clipboard.setData(
            ClipboardData(
              text:
                  'To: support@prosepal.app\nSubject: Prosepal Feedback\n\n$fullMessage',
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied! Paste into your email app')),
          );
        }
      }
    }

    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _shareDiagnostics() async {
    final isRcConfigured = ref.read(subscriptionServiceProvider).isConfigured;
    final report = await DiagnosticService.generateReport(
      isRevenueCatConfigured: isRcConfigured,
    );

    if (!mounted) return;

    // Show the report to user first, then let them share
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DiagnosticReportSheet(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Send Feedback')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Questions, bugs, or feature requests? We'd love to hear from you.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Gap(AppSpacing.lg),
              Expanded(
                child: Semantics(
                  label: 'Feedback message input',
                  hint: 'Enter your feedback, bug report, or feature request',
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Your feedback',
                      hintText: 'Describe your issue or suggestion...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(AppSpacing.md),
              // Toggle for including diagnostic logs
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: _includeLogs
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.textHint.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Include diagnostic logs',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            'Helps us troubleshoot issues faster',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _includeLogs,
                      onChanged: (value) =>
                          setState(() => _includeLogs = value),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              // View report link (only when logs enabled)
              if (_includeLogs) ...[
                const Gap(AppSpacing.sm),
                GestureDetector(
                  onTap: _shareDiagnostics,
                  child: Text.rich(
                    TextSpan(
                      text: 'Preview: ',
                      style: TextStyle(fontSize: 13, color: AppColors.textHint),
                      children: [
                        TextSpan(
                          text: 'View diagnostic report',
                          style: TextStyle(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Gap(AppSpacing.lg),
              AppButton(
                label: 'Send Feedback',
                onPressed: _isSending ? null : _send,
                isLoading: _isSending,
                icon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === COMPONENTS ===

class _DiagnosticReportSheet extends StatelessWidget {
  const _DiagnosticReportSheet({required this.report});

  final String report;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Diagnostic Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () {
                          unawaited(
                            Clipboard.setData(ClipboardData(text: report)),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Copy',
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        onPressed: () {
                          unawaited(
                            SharePlus.instance.share(
                              ShareParams(
                                text: report,
                                subject: 'Prosepal Diagnostic Report',
                              ),
                            ),
                          );
                        },
                        tooltip: 'Share',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            // Report content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  report,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            // Privacy notice
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'No personal messages, passwords, or payment details included.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
