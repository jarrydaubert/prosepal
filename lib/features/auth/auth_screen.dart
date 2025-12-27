import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthService.instance.signInWithApple();
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'Apple sign in failed. Please try again.');
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
      await AuthService.instance.signInWithGoogle();
      // OAuth redirects, so we don't navigate here
    } catch (e) {
      setState(() => _error = 'Google sign in failed. Please try again.');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signInWithEmail() {
    context.push('/auth/email');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(),
              // Logo/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                'Welcome to Prosepal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'The right words, right now',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_error != null) ...[
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
              ],
              // Sign in with Apple
              _AuthButton(
                onPressed: _isLoading ? null : _signInWithApple,
                icon: Icons.apple,
                label: 'Continue with Apple',
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              SizedBox(height: AppSpacing.md),
              // Sign in with Google
              _AuthButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: null,
                customIcon: Image.network(
                  'https://www.google.com/favicon.ico',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => Icon(Icons.g_mobiledata, size: 24),
                ),
                label: 'Continue with Google',
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                borderColor: AppColors.textHint,
              ),
              SizedBox(height: AppSpacing.md),
              // Sign in with Email
              _AuthButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                icon: Icons.email_outlined,
                label: 'Continue with Email',
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.textPrimary,
              ),
              SizedBox(height: AppSpacing.xl),
              if (_isLoading)
                CircularProgressIndicator(color: AppColors.primary)
              else
                Text(
                  'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.onPressed,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    this.customIcon,
    this.borderColor,
  });

  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? customIcon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (customIcon != null)
              customIcon!
            else if (icon != null)
              Icon(icon, size: 24),
            SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
