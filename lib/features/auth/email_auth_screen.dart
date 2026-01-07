import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/providers.dart';
import '../../shared/theme/app_colors.dart';

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _emailSent = false;
  bool _usePassword = false;
  String? _sentToEmail;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _resetToEmailInput() {
    setState(() {
      _emailSent = false;
      _sentToEmail = null;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      if (message.contains('rate') || message.contains('too many')) {
        return 'Too many attempts. Please wait a moment.';
      }
      if (message.contains('invalid') && message.contains('email')) {
        return 'Please enter a valid email address.';
      }
      if (message.contains('invalid') && message.contains('credentials')) {
        return 'Invalid email or password. Please try again.';
      }
      if (message.contains('user not found') ||
          message.contains('no user found')) {
        return 'No account found with this email.';
      }
      if (message.contains('network') || message.contains('connection')) {
        return 'Connection error. Check your internet.';
      }

      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _sendMagicLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final authService = ref.read(authServiceProvider);
      await authService.signInWithMagicLink(email);

      setState(() {
        _emailSent = true;
        _sentToEmail = email;
      });
      _startResendCooldown();
    } catch (e) {
      _showError(_getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final throttle = ref.read(authThrottleServiceProvider);

    // Check rate limiting before attempting sign-in
    final throttleCheck = throttle.checkThrottle(email);
    if (!throttleCheck.allowed) {
      _showError('Too many attempts. Please wait ${throttleCheck.waitSeconds} seconds.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final password = _passwordController.text;
      final authService = ref.read(authServiceProvider);
      final response =
          await authService.signInWithEmail(email: email, password: password);

      // Success - reset throttle
      throttle.recordSuccess(email);

      // Identify with RevenueCat and sync usage (same as Apple/Google)
      if (response.user != null) {
        await ref
            .read(subscriptionServiceProvider)
            .identifyUser(response.user!.id);
        await ref.read(usageServiceProvider).syncFromServer();
      }

      // Navigate after successful auth
      if (mounted) {
        context.go('/home');
      }
    } on AuthException catch (e) {
      // Record failure for rate limiting (only for auth failures)
      throttle.recordFailure(email);
      _showError(_getErrorMessage(e));
    } catch (e) {
      // Non-auth errors don't count toward throttle
      _showError(_getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Continue with Email'),
          backgroundColor: AppColors.background,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: _emailSent
                ? _EmailSentView(
                    email: _sentToEmail!,
                    resendCooldown: _resendCooldown,
                    onResend: _resetToEmailInput,
                    onChangeEmail: _resetToEmailInput,
                  )
                : _EmailInputView(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    formKey: _formKey,
                    isLoading: _isLoading,
                    usePassword: _usePassword,
                    onSubmit: _usePassword
                        ? _signInWithPassword
                        : _sendMagicLink,
                    onToggleMode: () => setState(() {
                      _usePassword = !_usePassword;
                      _passwordController.clear();
                    }),
                    validateEmail: _validateEmail,
                  ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// EMAIL SENT SUCCESS VIEW
// =============================================================================

class _EmailSentView extends StatelessWidget {
  const _EmailSentView({
    required this.email,
    required this.resendCooldown,
    required this.onResend,
    required this.onChangeEmail,
  });

  final String email;
  final int resendCooldown;
  final VoidCallback onResend;
  final VoidCallback onChangeEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),

        // Success icon with bold border
        Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success, width: 4),
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 56,
                color: AppColors.success,
              ),
            )
            .animate(key: const ValueKey('success_icon'))
            .fadeIn(duration: 400.ms)
            .scale(delay: 100.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 40),

        // Title
        const Text(
              'Check your email',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
            .animate(key: const ValueKey('success_title'))
            .fadeIn(delay: 300.ms)
            .slideY(begin: 0.2, end: 0),

        const SizedBox(height: 12),

        // Subtitle
        Text(
          'We sent a magic link to',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 8),

        // Email address
        Text(
          email,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ).animate().fadeIn(delay: 500.ms),

        const SizedBox(height: 16),

        Text(
          'Tap the link in your email to sign in instantly.\nNo password needed!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ).animate().fadeIn(delay: 600.ms),

        const SizedBox(height: 40),

        // Resend button
        if (resendCooldown > 0)
          Text(
            'Resend available in ${resendCooldown}s',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          )
        else
          TextButton.icon(
            onPressed: onResend,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Resend magic link'),
          ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: onChangeEmail,
          child: Text(
            'Use a different email',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),

        const SizedBox(height: 40),

        // Info box with bold border
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.info, width: 2),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Didn't get the email? Check your spam folder.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }
}

// =============================================================================
// EMAIL INPUT VIEW
// =============================================================================

class _EmailInputView extends StatelessWidget {
  const _EmailInputView({
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.isLoading,
    required this.usePassword,
    required this.onSubmit,
    required this.onToggleMode,
    required this.validateEmail,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final bool usePassword;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;
  final String? Function(String?) validateEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Icon with bold border
        Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 4),
              ),
              child: Icon(
                usePassword ? Icons.lock_outline : Icons.email_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            )
            .animate(key: ValueKey('icon_$usePassword'))
            .fadeIn(duration: 400.ms)
            .scale(delay: 100.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 32),

        // Title
        Text(
              usePassword ? 'Sign in with password' : 'Passwordless sign in',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
            .animate(key: ValueKey('title_$usePassword'))
            .fadeIn(delay: 300.ms)
            .slideY(begin: 0.2, end: 0),

        const SizedBox(height: 12),

        // Subtitle
        Text(
          usePassword
              ? 'Enter your email and password to sign in.'
              : "Enter your email and we'll send you\na magic link to sign in instantly.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 32),

        // Form
        Form(
          key: formKey,
          child: Column(
            children: [
              _StyledTextField(
                controller: emailController,
                label: 'Email address',
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: usePassword
                    ? TextInputAction.next
                    : TextInputAction.done,
                validator: validateEmail,
                onSubmitted: usePassword ? null : (_) => onSubmit(),
              ),
              if (usePassword) ...[
                const SizedBox(height: 16),
                _StyledTextField(
                  controller: passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  onSubmitted: (_) => onSubmit(),
                ),
              ],
              const SizedBox(height: 24),
              _PrimaryButton(
                label: usePassword ? 'Sign In' : 'Send Magic Link',
                isLoading: isLoading,
                onPressed: onSubmit,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms),

        const SizedBox(height: 20),

        // Toggle mode
        TextButton(
          onPressed: onToggleMode,
          child: Text(
            usePassword ? 'Use magic link instead' : 'Sign in with password',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),

        // Benefits (only for magic link mode)
        if (!usePassword) ...[
          const SizedBox(height: 24),
          const _BenefitItem(
            icon: Icons.lock_outline,
            title: 'Secure & private',
            subtitle: 'No password to remember or steal',
            delay: 600,
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.flash_on,
            title: 'Quick & easy',
            subtitle: 'One tap in your email to sign in',
            delay: 700,
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// REUSABLE COMPONENTS
// =============================================================================

class _StyledTextField extends StatefulWidget {
  const _StyledTextField({
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  @override
  State<_StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<_StyledTextField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    // Only obscure if obscureText is true AND user hasn't toggled visibility
    final shouldObscure = widget.obscureText && _isObscured;

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: shouldObscure,
      autocorrect: false,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: Icon(widget.icon),
        // Show visibility toggle for password fields
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) {
          HapticFeedback.lightImpact();
          widget.onPressed();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        )
        .animate(key: ValueKey('benefit_$title'))
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: 0.1, end: 0);
  }
}
