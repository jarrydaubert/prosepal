import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/errors/auth_errors.dart';
import '../../core/providers/providers.dart';
import '../../shared/theme/app_colors.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _error;

  void _showError(String message) {
    setState(() => _error = message);
    // Auto-dismiss after 6 seconds (longer for readability)
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _error == message) {
        setState(() => _error = null);
      }
    });
  }

  void _dismissError() {
    setState(() => _error = null);
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signInWithApple();
      if (response.user != null) {
        await ref
            .read(subscriptionServiceProvider)
            .identifyUser(response.user!.id);
        // Sync usage from server (restores usage after reinstall)
        await ref.read(usageServiceProvider).syncFromServer();
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (!AuthErrorHandler.isCancellation(e)) {
        _showError(AuthErrorHandler.getMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signInWithGoogle();
      if (response.user != null) {
        await ref
            .read(subscriptionServiceProvider)
            .identifyUser(response.user!.id);
        // Sync usage from server (restores usage after reinstall)
        await ref.read(usageServiceProvider).syncFromServer();
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (!AuthErrorHandler.isCancellation(e)) {
        _showError(AuthErrorHandler.getMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signInWithEmail() {
    context.push('/auth/email');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App Logo with bold border container
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: AppColors.primary, width: 4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 140,
                    height: 140,
                  ),
                ),
              )
                  .animate(key: const ValueKey('logo'))
                  .fadeIn(duration: 400.ms)
                  .scale(delay: 100.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 40),

              // Title
              const Text(
                'Welcome to Prosepal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              )
                  .animate(key: const ValueKey('title'))
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              // Tagline
              Text(
                'The right words, right now',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ).animate(key: const ValueKey('tagline')).fadeIn(delay: 500.ms),

              const Spacer(flex: 2),

              // Error message
              if (_error != null) ...[
                _ErrorBanner(
                  message: _error!,
                  onDismiss: _dismissError,
                ),
                const SizedBox(height: 20),
              ],

              // Auth buttons
              Column(
                children: [
                  // Apple Sign In (iOS/macOS only, first per Apple guidelines)
                  if (Platform.isIOS || Platform.isMacOS) ...[
                    _AuthButton(
                      onPressed: _isLoading ? null : _signInWithApple,
                      isLoading: _isLoading,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: SignInWithAppleButton(
                          text: 'Continue with Apple',
                          onPressed: _signInWithApple,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Google Sign In
                  _AuthButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    isLoading: _isLoading,
                    style: _AuthButtonStyle.outlined,
                    icon: Image.asset(
                      'assets/images/icons/google_g.png',
                      width: 20,
                      height: 20,
                    ),
                    label: 'Continue with Google',
                  ),
                  const SizedBox(height: 12),

                  // Email Sign In
                  _AuthButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    isLoading: _isLoading,
                    icon: const Icon(Icons.email_outlined, size: 20),
                    label: 'Continue with Email',
                  ),
                ],
              )
                  .animate(key: const ValueKey('buttons'))
                  .fadeIn(delay: 600.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // Loading indicator or legal text
              if (_isLoading)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                )
              else
                _LegalText(
                  onTermsTap: () => context.pushNamed('terms'),
                  onPrivacyTap: () => context.pushNamed('privacy'),
                ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// REUSABLE COMPONENTS
// =============================================================================

enum _AuthButtonStyle { primary, outlined }

/// Unified auth button with scale animation and haptic feedback
class _AuthButton extends StatefulWidget {
  const _AuthButton({
    required this.onPressed,
    required this.isLoading,
    this.style = _AuthButtonStyle.primary,
    this.icon,
    this.label,
    this.child,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final _AuthButtonStyle style;
  final Widget? icon;
  final String? label;
  final Widget? child;

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // If child is provided, use it directly (for Apple button)
    if (widget.child != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: Opacity(
            opacity: widget.isLoading ? 0.6 : 1.0,
            child: IgnorePointer(
              ignoring: widget.isLoading,
              child: widget.child,
            ),
          ),
        ),
      );
    }

    final isPrimary = widget.style == _AuthButtonStyle.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Opacity(
          opacity: widget.isLoading ? 0.6 : 1.0,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isPrimary
                  ? null
                  : Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 12),
                ],
                Text(
                  widget.label ?? '',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Error banner with dismiss button
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded, color: AppColors.error, size: 20),
          ),
        ],
      ),
    )
        .animate(key: ValueKey(message))
        .fadeIn(duration: 300.ms)
        .shake(hz: 3, duration: 400.ms);
  }
}

/// Legal text with tappable links
class _LegalText extends StatelessWidget {
  const _LegalText({
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(
          'By continuing, you agree to our ',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        GestureDetector(
          onTap: onTermsTap,
          child: const Text(
            'Terms',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(' and ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        GestureDetector(
          onTap: onPrivacyTap,
          child: const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
