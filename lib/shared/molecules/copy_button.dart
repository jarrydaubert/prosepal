import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

/// Copy button with icon morph feedback.
///
/// Features:
/// - Icon morphs from copy to checkmark
/// - Resets after delay
class CopyButton extends StatefulWidget {
  const CopyButton({
    super.key,
    required this.textToCopy,
    this.onCopied,
    this.size = 24,
    this.color,
  });

  final String textToCopy;
  final VoidCallback? onCopied;
  final double size;
  final Color? color;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));

    setState(() => _copied = true);
    widget.onCopied?.call();

    // Reset after delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ?? AppColors.textSecondary;

    return IconButton(
      onPressed: _copied ? null : _handleCopy,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: _copied
            ? Icon(
                Icons.check_rounded,
                key: const ValueKey('check'),
                color: AppColors.success,
                size: widget.size,
              ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 200.ms,
                  curve: Curves.easeOutBack,
                )
            : Icon(
                Icons.copy_rounded,
                key: const ValueKey('copy'),
                color: iconColor,
                size: widget.size,
              ),
      ),
      tooltip: _copied ? 'Copied!' : 'Copy message',
    );
  }
}

/// Larger copy button variant with label
class CopyButtonWithLabel extends StatefulWidget {
  const CopyButtonWithLabel({
    super.key,
    required this.textToCopy,
    this.onCopied,
    this.label = 'Copy',
    this.copiedLabel = 'Copied!',
  });

  final String textToCopy;
  final VoidCallback? onCopied;
  final String label;
  final String copiedLabel;

  @override
  State<CopyButtonWithLabel> createState() => _CopyButtonWithLabelState();
}

class _CopyButtonWithLabelState extends State<CopyButtonWithLabel> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));

    setState(() => _copied = true);
    widget.onCopied?.call();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _copied ? null : _handleCopy,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _copied
            ? const Icon(
                Icons.check_rounded,
                key: ValueKey('check'),
                color: AppColors.success,
              )
            : const Icon(Icons.copy_rounded, key: ValueKey('copy')),
      ),
      label: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          _copied ? widget.copiedLabel : widget.label,
          key: ValueKey(_copied),
          style: TextStyle(color: _copied ? AppColors.success : null),
        ),
      ),
    );
  }
}
