import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/auth_errors.dart';
import '../../core/providers/providers.dart';
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
      final response = await AuthService.instance.signInWithApple();
      // Link RevenueCat to user for purchase restoration across devices
      if (response.user != null) {
        await ref
            .read(subscriptionServiceProvider)
            .identifyUser(response.user!.id);
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (AuthErrorHandler.isCancellation(e)) {
        // User cancelled, don't show error
      } else {
        setState(() => _error = AuthErrorHandler.getMessage(e));
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
      await AuthService.instance.signInWithGoogle();
      // OAuth redirects, so we don't navigate here
    } catch (e) {
      if (!AuthErrorHandler.isCancellation(e)) {
        setState(() => _error = AuthErrorHandler.getMessage(e));
      }
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
              // App Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_error != null) ...[
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
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
              // Sign in with Email (primary option)
              _AuthButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                icon: Icons.email_outlined,
                label: 'Continue with Email',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              SizedBox(height: AppSpacing.md),
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
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.g_mobiledata, size: 24),
                ),
                label: 'Continue with Google',
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                borderColor: AppColors.textSecondary,
              ),
              SizedBox(height: AppSpacing.xl),
              if (_isLoading)
                CircularProgressIndicator(color: AppColors.primary)
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'By continuing, you agree to our ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pushNamed('terms'),
                      child: Text(
                        'Terms',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      ' and ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pushNamed('privacy'),
                      child: Text(
                        'Privacy Policy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
