import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

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

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(email: email, password: password);
      // Navigation handled by auth state listener
    } catch (e) {
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
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Continue with Email'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                if (_emailSent) ...[
                  _buildSuccessState(context),
                ] else ...[
                  _buildEmailInput(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      children: [
        Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 48,
                color: AppColors.success,
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Check your email',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We sent a magic link to',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
        if (_sentToEmail != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _sentToEmail!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tap the link in your email to sign in instantly.\nNo password needed!',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: AppSpacing.xxl),
        if (_resendCooldown > 0)
          Text(
            'Resend available in ${_resendCooldown}s',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
          ).animate().fadeIn()
        else
          TextButton.icon(
            onPressed: _resetToEmailInput,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Resend magic link'),
          ).animate().fadeIn(),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: _resetToEmailInput,
          child: const Text(
            'Use a different email',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  "Didn't get the email? Check your spam folder.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.info),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Widget _buildEmailInput(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _usePassword ? Icons.lock_outline : Icons.email_outlined,
            size: 36,
            color: AppColors.primary,
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _usePassword ? 'Sign in with password' : 'Passwordless sign in',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _usePassword
              ? 'Enter your email and password to sign in.'
              : "Enter your email and we'll send you\na magic link to sign in instantly.",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: AppSpacing.xl),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: _usePassword
                    ? TextInputAction.next
                    : TextInputAction.done,
                validator: _validateEmail,
                onFieldSubmitted: (_) => _usePassword ? null : _sendMagicLink(),
                decoration: InputDecoration(
                  labelText: 'Email address',
                  hintText: 'you@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              if (_usePassword) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _signInWithPassword(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                      borderSide: BorderSide(color: Colors.grey.shade300),
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_usePassword ? _signInWithPassword : _sendMagicLink),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _usePassword ? 'Sign In' : 'Send Magic Link',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: () => setState(() {
            _usePassword = !_usePassword;
            _passwordController.clear();
          }),
          child: Text(
            _usePassword ? 'Use magic link instead' : 'Sign in with password',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        if (!_usePassword) ...[
          const SizedBox(height: AppSpacing.md),
          _buildBenefitItem(
            context,
            Icons.lock_outline,
            'Secure & private',
            'No password to remember or steal',
            400,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBenefitItem(
            context,
            Icons.flash_on,
            'Quick & easy',
            'One tap in your email to sign in',
            500,
          ),
        ],
      ],
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    int delayMs,
  ) {
    return Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs))
        .slideX(begin: 0.1, duration: 300.ms);
  }
}
