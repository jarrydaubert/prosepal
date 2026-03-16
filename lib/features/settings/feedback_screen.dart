import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/providers.dart';
import '../../core/services/diagnostic_service.dart';
import '../../core/services/feedback_service.dart';
import '../../shared/components/components.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/utils/keyboard_utils.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  bool _includeLogs = false;
  bool _includeSensitiveLogs = false;

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    dismissKeyboard(context);

    final message = _controller.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }

    setState(() => _isSending = true);

    String? diagnosticReport;

    try {
      if (_includeLogs) {
        final isRcConfigured = ref
            .read(subscriptionServiceProvider)
            .isConfigured;
        diagnosticReport = await DiagnosticService.generateReport(
          isRevenueCatConfigured: isRcConfigured,
          includeSensitiveLogs: _includeSensitiveLogs,
        );
      }

      await ref
          .read(feedbackServiceProvider)
          .submitFeedback(
            message: message,
            diagnosticReport: diagnosticReport,
            includeSensitiveLogs: _includeSensitiveLogs,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback sent. Thanks for the report.')),
      );
      Navigator.pop(context);
    } on FeedbackAuthRequiredException {
      await _showManualFallback(
        message,
        diagnosticReport: diagnosticReport,
        reason:
            'Direct in-app delivery currently requires you to be signed in.',
      );
    } on FeedbackSubmissionException catch (e) {
      await _showManualFallback(
        message,
        diagnosticReport: diagnosticReport,
        reason: e.message,
      );
    } on Exception {
      await _showManualFallback(
        message,
        diagnosticReport: diagnosticReport,
        reason: 'Unable to submit feedback right now.',
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _manualFallbackText(String message, {String? diagnosticReport}) {
    final buffer = StringBuffer()
      ..writeln('To: support@prosepal.app')
      ..writeln('Subject: Prosepal Feedback')
      ..writeln()
      ..writeln(message.trim());
    if (diagnosticReport != null && diagnosticReport.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(diagnosticReport);
    }
    return buffer.toString().trimRight();
  }

  Future<void> _showManualFallback(
    String message, {
    String? diagnosticReport,
    String? reason,
  }) async {
    if (!mounted) return;

    final fullMessage = _manualFallbackText(
      message,
      diagnosticReport: diagnosticReport,
    );

    final action = await showModalBottomSheet<_ManualFallbackAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Send manually',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Gap(10),
              Text(
                reason ?? 'You can still copy or share your feedback manually.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const Gap(18),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, _ManualFallbackAction.copy),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy feedback'),
              ),
              const Gap(10),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, _ManualFallbackAction.share),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share feedback'),
              ),
              const Gap(10),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, _ManualFallbackAction.cancel),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null || action == _ManualFallbackAction.cancel) {
      return;
    }

    if (action == _ManualFallbackAction.copy) {
      await Clipboard.setData(ClipboardData(text: fullMessage));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied. Paste into any message app.')),
      );
      return;
    }

    if (action == _ManualFallbackAction.share) {
      await SharePlus.instance.share(
        ShareParams(text: fullMessage, subject: 'Prosepal Feedback'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Share sheet opened.')));
    }
  }

  Future<void> _shareDiagnostics() async {
    final isRcConfigured = ref.read(subscriptionServiceProvider).isConfigured;
    final report = await DiagnosticService.generateReport(
      isRevenueCatConfigured: isRcConfigured,
      includeSensitiveLogs: _includeSensitiveLogs,
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
      builder: (context) => _DiagnosticReportSheet(
        report: report,
        includeSensitiveLogs: _includeSensitiveLogs,
      ),
    );
  }

  Future<void> _toggleSensitiveLogs(bool enabled) async {
    if (!enabled) {
      setState(() => _includeSensitiveLogs = false);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Include Full Technical Details?'),
        content: const Text(
          'This may include message/prompt context and identifiers. '
          'Only enable when support asks. Passwords and tokens remain redacted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if ((confirm ?? false) && mounted) {
      setState(() => _includeSensitiveLogs = true);
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => dismissKeyboard(context),
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Send Feedback',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: AppBackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Questions, bugs, or feature requests? We'd love to hear from you.",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const Gap(AppSpacing.lg),
            Semantics(
              label: 'Feedback message input',
              hint: 'Enter your feedback, bug report, or feature request',
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 4,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                textAlignVertical: TextAlignVertical.top,
                scrollPadding: const EdgeInsets.only(bottom: 140),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
                onEditingComplete: () => dismissKeyboard(context),
                onTapOutside: (_) => dismissKeyboard(context),
                decoration: InputDecoration(
                  hintText: 'Describe your issue or suggestion...',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    height: 1.4,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  filled: true,
                  fillColor: AppColors.surface,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Include diagnostic logs',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Gap(2),
                        Text(
                          'Optional: app/version diagnostics for troubleshooting',
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
                    onChanged: (value) {
                      dismissKeyboard(context);
                      setState(() {
                        _includeLogs = value;
                        if (!value) _includeSensitiveLogs = false;
                      });
                    },
                    activeTrackColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            if (_includeLogs) ...[
              const Gap(AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: _includeSensitiveLogs
                        ? AppColors.error.withValues(alpha: 0.25)
                        : AppColors.textHint.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Include full technical details (advanced)',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _includeSensitiveLogs,
                      onChanged: (value) {
                        dismissKeyboard(context);
                        _toggleSensitiveLogs(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
            // View report link (only when logs enabled)
            if (_includeLogs) ...[
              const Gap(AppSpacing.sm),
              GestureDetector(
                onTap: _shareDiagnostics,
                child: const Text.rich(
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

enum _ManualFallbackAction { copy, share, cancel }

// === COMPONENTS ===

class _DiagnosticReportSheet extends StatelessWidget {
  const _DiagnosticReportSheet({
    required this.report,
    required this.includeSensitiveLogs,
  });

  final String report;
  final bool includeSensitiveLogs;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.7,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    expand: false,
    builder: (context, scrollController) => Column(
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
              const Text(
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
                      unawaited(Clipboard.setData(ClipboardData(text: report)));
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
              style: const TextStyle(
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
              const Icon(
                Icons.shield_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  includeSensitiveLogs
                      ? 'Includes expanded technical details. Share only with trusted support.'
                      : 'No personal messages, passwords, or payment details included.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
