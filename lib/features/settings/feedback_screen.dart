import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/providers.dart';
import '../../core/services/error_log_service.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Collect device info for bug reports
  Future<String> _getDeviceInfo() async {
    final buffer = StringBuffer();
    buffer.writeln('--- Device Info ---');
    buffer.writeln('Platform: ${Platform.operatingSystem}');
    buffer.writeln('OS Version: ${Platform.operatingSystemVersion}');
    buffer.writeln('Dart: ${Platform.version.split(' ').first}');
    buffer.writeln('Locale: ${Platform.localeName}');

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      buffer.writeln(
        'App: Prosepal v${packageInfo.version} (${packageInfo.buildNumber})',
      );
    } catch (_) {
      buffer.writeln('App: Prosepal');
    }

    return buffer.toString();
  }

  Future<void> _send() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a message')));
      return;
    }

    setState(() => _isSending = true);

    final email = ref.read(authServiceProvider).email ?? 'Unknown';
    final deviceInfo = await _getDeviceInfo();
    final errorLog = ErrorLogService.instance.getFormattedLog();

    final subject = Uri.encodeComponent('Prosepal Feedback');
    final body = Uri.encodeComponent(
      '$message\n\n$deviceInfo\nUser: $email\n\n$errorLog',
    );

    final uri = Uri.parse(
      'mailto:support@prosepal.app?subject=$subject&body=$body',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open email app')));
      }
    }

    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Send Feedback')),
        body: Padding(
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Questions, bugs, or feature requests? We\'d love to hear from you.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Gap(AppSpacing.lg),
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
              Gap(AppSpacing.sm),
              Text(
                'Device info will be attached to help us debug issues.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
              ),
              Gap(AppSpacing.lg),
              AppButton(
                label: 'Send',
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
