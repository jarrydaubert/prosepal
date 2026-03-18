import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
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
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
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
      ..writeln('To: ${AppConfig.supportEmail}')
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderMedium),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () =>
                    Navigator.pop(context, _ManualFallbackAction.copy),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy feedback'),
              ),
              const Gap(10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderMedium),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () =>
                    Navigator.pop(context, _ManualFallbackAction.share),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share feedback'),
              ),
              const Gap(10),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
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

  Future<void> _toggleTechnicalTrace() async {
    if (!_includeSensitiveLogs) {
      await _toggleSensitiveLogs(true);
      return;
    }
    setState(() => _includeSensitiveLogs = false);
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surface, AppColors.bgDeep],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                border: Border.all(color: AppColors.borderMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: const Text(
                      'Support inbox',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  const Text(
                    'Tell us what you were doing, what went wrong, and whether it keeps happening.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    'Short reports are fine. Add app details only when they will help us reproduce the problem.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.lg),
            AppSurfaceCard(
              borderColor: _focusNode.hasFocus
                  ? AppColors.primary
                  : AppColors.borderOnLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What happened?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnLight,
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  const Text(
                    'Include what you expected, what happened instead, and how often you can reproduce it.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textOnLightSecondary,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Semantics(
                    label: 'Feedback message input',
                    hint: 'Enter your feedback, bug report, or feature request',
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 5,
                      maxLines: 7,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      textAlignVertical: TextAlignVertical.top,
                      scrollPadding: const EdgeInsets.only(bottom: 140),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: AppColors.textOnLight,
                      ),
                      onEditingComplete: () => dismissKeyboard(context),
                      onTapOutside: (_) => dismissKeyboard(context),
                      decoration: InputDecoration(
                        hintText:
                            'Example: I generated a birthday message, tapped share, and the sheet flashed then disappeared. It has happened twice today.',
                        hintStyle: const TextStyle(
                          color: AppColors.textOnLightHint,
                          height: 1.4,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(
                          14,
                          14,
                          14,
                          14,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceLightMuted,
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMedium,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.borderOnLight,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMedium,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.borderOnLight,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMedium,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.md),
            AppSurfaceCard(
              borderColor: _includeLogs
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.borderOnLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add app details',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textOnLight,
                              ),
                            ),
                            const Gap(AppSpacing.xs),
                            Text(
                              _includeLogs
                                  ? 'We will attach a support package with app version, device, account state, subscription state, AI runtime, and redacted recent logs.'
                                  : 'Off by default. Turn this on when the issue is technical or hard to reproduce.',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.textOnLightSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        key: const Key('feedback.include_app_details_switch'),
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
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: _includeLogs
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Gap(AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            const _FeedbackModeChip(
                              label: 'Support summary',
                              color: AppColors.info,
                            ),
                            if (_includeSensitiveLogs)
                              const _FeedbackModeChip(
                                label: 'Technical trace',
                                color: AppColors.warning,
                              ),
                          ],
                        ),
                        const Gap(AppSpacing.sm),
                        Text(
                          _includeSensitiveLogs
                              ? 'Technical trace adds deeper logs, identifiers, and message-context diagnostics. Use it only when support asks for a deeper investigation.'
                              : 'The support summary avoids your message and prompt content while still giving us the app context needed to investigate.',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textOnLightSecondary,
                          ),
                        ),
                        const Gap(AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _shareDiagnostics,
                              icon: const Icon(Icons.visibility_rounded),
                              label: const Text('Preview report'),
                            ),
                            TextButton.icon(
                              key: const Key(
                                'feedback.toggle_technical_trace_button',
                              ),
                              onPressed: _toggleTechnicalTrace,
                              icon: Icon(
                                _includeSensitiveLogs
                                    ? Icons.remove_circle_outline_rounded
                                    : Icons.data_object_rounded,
                              ),
                              label: Text(
                                _includeSensitiveLogs
                                    ? 'Remove technical trace'
                                    : 'Add technical trace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.lg),
            AppButton(
              label: 'Send to support',
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

class _FeedbackModeChip extends StatelessWidget {
  const _FeedbackModeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

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
