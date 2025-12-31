import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

/// Copy button with confetti celebration on success.
///
/// Features:
/// - Icon morphs from copy to checkmark
/// - Confetti burst on copy
/// - Haptic feedback
/// - Resets after delay
class CopyButton extends StatefulWidget {
  const CopyButton({
    super.key,
    required this.textToCopy,
    this.onCopied,
    this.size = 24,
    this.color,
    this.showConfetti = true,
  });

  final String textToCopy;
  final VoidCallback? onCopied;
  final double size;
  final Color? color;
  final bool showConfetti;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  late final ConfettiController _confettiController;
  bool _copied = false;

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

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    HapticFeedback.mediumImpact();

    setState(() => _copied = true);

    if (widget.showConfetti) {
      _confettiController.play();
    }

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

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Confetti source
        Positioned(
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 12,
            maxBlastForce: 20,
            minBlastForce: 8,
            emissionFrequency: 0.05,
            gravity: 0.3,
            colors: const [
              AppColors.primary,
              AppColors.primaryLight,
              Color(0xFFFFA726), // Gold
              Color(0xFF66BB6A), // Green
              Color(0xFFB47CFF), // Purple
            ],
          ),
        ),

        // Button
        IconButton(
          onPressed: _copied ? null : _handleCopy,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: _copied
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('check'),
                    color: AppColors.success,
                    size: widget.size,
                  )
                    .animate()
                    .scale(
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
        ),
      ],
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
  late final ConfettiController _confettiController;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    HapticFeedback.mediumImpact();

    setState(() => _copied = true);
    _confettiController.play();
    widget.onCopied?.call();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Confetti
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 20,
          maxBlastForce: 25,
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

        // Button
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: TextButton.icon(
            onPressed: _copied ? null : _handleCopy,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _copied
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('check'),
                      color: AppColors.success,
                    )
                  : const Icon(
                      Icons.copy_rounded,
                      key: ValueKey('copy'),
                    ),
            ),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _copied ? widget.copiedLabel : widget.label,
                key: ValueKey(_copied),
                style: TextStyle(
                  color: _copied ? AppColors.success : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
