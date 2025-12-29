import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  bool _emailSent = false;
  String? _sentToEmail;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
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
    });
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      // Rate limiting
      if (message.contains('rate') || message.contains('too many')) {
        return 'Too many attempts. Please wait a moment.';
      }
      // Invalid email
      if (message.contains('invalid') && message.contains('email')) {
        return 'Please enter a valid email address.';
      }
      // Network issues
      if (message.contains('network') || message.contains('connection')) {
        return 'Connection error. Check your internet.';
      }

      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Continue with Email'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),
              if (_emailSent) ...[
                // Success state - email sent
                _buildSuccessState(context),
              ] else ...[
                // Email input form
                _buildEmailInput(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      children: [
        // Animated success icon
        Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 48,
                color: AppColors.success,
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: Offset(0.8, 0.8), curve: Curves.easeOutBack),
        SizedBox(height: AppSpacing.xl),
        Text(
          'Check your email',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        SizedBox(height: AppSpacing.sm),
        Text(
          'We sent a magic link to',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
        if (_sentToEmail != null) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            _sentToEmail!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
        ],
        SizedBox(height: AppSpacing.md),
        Text(
          'Tap the link in your email to sign in instantly.\nNo password needed!',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 500.ms),
        SizedBox(height: AppSpacing.xxl),

        // Resend button with cooldown
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
            icon: Icon(Icons.refresh, size: 18),
            label: Text('Resend magic link'),
          ).animate().fadeIn(),

        SizedBox(height: AppSpacing.md),

        // Different email button
        TextButton(
          onPressed: _resetToEmailInput,
          child: Text(
            'Use a different email',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),

        SizedBox(height: AppSpacing.xxl),

        // Help text
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              SizedBox(width: AppSpacing.sm),
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
        // Header icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.email_outlined, size: 36, color: AppColors.primary),
        ).animate().fadeIn().scale(begin: Offset(0.9, 0.9)),
        SizedBox(height: AppSpacing.lg),
        Text(
          'Passwordless sign in',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 100.ms),
        SizedBox(height: AppSpacing.sm),
        Text(
          "Enter your email and we'll send you\na magic link to sign in instantly.",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        SizedBox(height: AppSpacing.xl),

        // Supabase Magic Auth widget
        SupaMagicAuth(
          redirectUrl: 'com.prosepal.prosepal://login-callback',
          onSuccess: (response) {
            // Extract email - response.user is non-null for successful auth
            final email = response.user.email;
            setState(() {
              _emailSent = true;
              _sentToEmail = email;
            });
            _startResendCooldown();
          },
          onError: (error) {
            final message = _getErrorMessage(error);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 20),
                    SizedBox(width: AppSpacing.sm),
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
          },
        ).animate().fadeIn(delay: 300.ms),

        SizedBox(height: AppSpacing.xl),

        // Benefits list
        _buildBenefitItem(
          context,
          Icons.lock_outline,
          'Secure & private',
          'No password to remember or steal',
          400,
        ),
        SizedBox(height: AppSpacing.md),
        _buildBenefitItem(
          context,
          Icons.flash_on,
          'Quick & easy',
          'One tap in your email to sign in',
          500,
        ),
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
            SizedBox(width: AppSpacing.md),
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
