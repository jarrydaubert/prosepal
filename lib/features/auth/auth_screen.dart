import 'dart:io' show Platform;

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
const double _kAuthButtonHeight = 50.0;

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
    Future.delayed(Duration(seconds: 6), () {
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
      // Google OAuth opens browser - auth state listener handles navigation
      await authService.signInWithGoogle();
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
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // App Logo with shadow
              Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: Offset(0.8, 0.8),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
              SizedBox(height: AppSpacing.xl),
              // Title
              Text(
                    'Welcome to Prosepal',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(begin: 0.3, duration: 500.ms),
              SizedBox(height: AppSpacing.sm),
              // Tagline
              Text(
                    'The right words, right now',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.3, duration: 500.ms),
              const Spacer(flex: 2),
              // Error message with dismiss button
              if (_error != null) ...[
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
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
                      GestureDetector(
                        onTap: _dismissError,
                        child: Icon(
                          Icons.close,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().shake(),
                SizedBox(height: AppSpacing.lg),
              ],
              // Auth buttons - Using official branded buttons with consistent sizing
              Column(
                    children: [
                      // Apple Sign In (iOS/macOS only, first per Apple guidelines)
                      // Uses official SignInWithAppleButton from sign_in_with_apple package
                      if (Platform.isIOS || Platform.isMacOS) ...[
                        SizedBox(
                          width: double.infinity,
                          height: _kAuthButtonHeight,
                          child: SignInWithAppleButton(
                            text: 'Continue with Apple',
                            onPressed: _isLoading ? () {} : _signInWithApple,
                            style: SignInWithAppleButtonStyle.black,
                            borderRadius: _kAuthButtonRadius,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                      ],
                      // Google Sign In - Custom button matching Apple style
                      // (Google branding: white bg, Google logo, dark text)
                      _GoogleSignInButton(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                      ),
                      SizedBox(height: AppSpacing.md),
                      // Email Sign In - Custom button matching the same style
                      _EmailSignInButton(
                        onPressed: _isLoading ? null : _signInWithEmail,
                      ),
                    ],
                  )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 500.ms)
                  .slideY(begin: 0.2, duration: 500.ms),
              SizedBox(height: AppSpacing.xl),
              // Loading or legal
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
                          fontWeight: FontWeight.w600,
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
              SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
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
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: _kAuthButtonRadius,
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Official Google "G" logo colors
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
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
        child: Row(
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

/// Custom painter for Google "G" logo with official colors
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Google logo colors
    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;

    final center = Offset(w / 2, h / 2);
    final radius = w * 0.4;

    // Blue arc (right side)
    paint.color = blue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.4,
      1.2,
      false,
      paint,
    );

    // Green arc (bottom right)
    paint.color = green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.8,
      1.0,
      false,
      paint,
    );

    // Yellow arc (bottom left)
    paint.color = yellow;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.8,
      0.9,
      false,
      paint,
    );

    // Red arc (top)
    paint.color = red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.7,
      1.0,
      false,
      paint,
    );

    // Blue horizontal bar
    paint.color = blue;
    paint.style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.42, w * 0.45, h * 0.16),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
