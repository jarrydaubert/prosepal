import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/errors/auth_errors.dart';
import '../../core/providers/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

/// Consistent button height for all auth buttons
const double _kAuthButtonHeight = 50;

/// Consistent border radius for all auth buttons
final BorderRadius _kAuthButtonRadius = BorderRadius.circular(
  AppSpacing.radiusMedium,
);

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
      backgroundColor: Colors.white,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.06),
              Colors.white,
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // App Logo with glassmorphism container
                DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 140,
                                height: 140,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 700.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: AppSpacing.xl + 8),
                // Title with refined typography
                Text(
                      'Welcome to Prosepal',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                      textAlign: TextAlign.center,
                    )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 600.ms)
                    .slideY(
                      begin: 0.2,
                      duration: 600.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: AppSpacing.sm + 4),
                // Tagline with improved styling
                Text(
                      'The right words, right now',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 600.ms)
                    .slideY(
                      begin: 0.2,
                      duration: 600.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const Spacer(flex: 2),
                // Error message with dismiss button
                if (_error != null) ...[
                  Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _dismissError,
                              child: Icon(
                                Icons.close_rounded,
                                color: AppColors.error.withValues(alpha: 0.7),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .shake(hz: 3, duration: 400.ms),
                  const SizedBox(height: AppSpacing.lg),
                ],
                // Auth buttons with micro-interactions
                Column(
                      children: [
                        // Apple Sign In (iOS/macOS only, first per Apple guidelines)
                        if (Platform.isIOS || Platform.isMacOS) ...[
                          _AnimatedAuthButton(
                            child: IgnorePointer(
                              ignoring: _isLoading,
                              child: Opacity(
                                opacity: _isLoading ? 0.6 : 1.0,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: _kAuthButtonHeight,
                                  child: SignInWithAppleButton(
                                    text: 'Continue with Apple',
                                    onPressed: _signInWithApple,
                                    borderRadius: _kAuthButtonRadius,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        // Google Sign In
                        _AnimatedAuthButton(
                          child: Opacity(
                            opacity: _isLoading ? 0.6 : 1.0,
                            child: _GoogleSignInButton(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Email Sign In
                        _AnimatedAuthButton(
                          child: Opacity(
                            opacity: _isLoading ? 0.6 : 1.0,
                            child: _EmailSignInButton(
                              onPressed: _isLoading ? null : _signInWithEmail,
                            ),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 650.ms, duration: 600.ms)
                    .slideY(
                      begin: 0.15,
                      duration: 600.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: AppSpacing.xl),
                // Loading or legal
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary.withValues(
                                  alpha: 0.5,
                                ),
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 850.ms, duration: 500.ms),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated wrapper for auth buttons with scale feedback
class _AnimatedAuthButton extends StatefulWidget {
  const _AnimatedAuthButton({required this.child});

  final Widget child;

  @override
  State<_AnimatedAuthButton> createState() => _AnimatedAuthButtonState();
}

class _AnimatedAuthButtonState extends State<_AnimatedAuthButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

/// Google Sign In button matching Apple button style
/// Uses official Google colors and logo per branding guidelines
class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _kAuthButtonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF8F9FA),
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: _kAuthButtonRadius,
            side: const BorderSide(color: Color(0xFFDDDFE1)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Official Google "G" logo from branding assets
            Image.asset(
              'assets/images/icons/google_g.png',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Email Sign In button matching the same style
class _EmailSignInButton extends StatelessWidget {
  const _EmailSignInButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _kAuthButtonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: _kAuthButtonRadius),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 20),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Continue with Email',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
