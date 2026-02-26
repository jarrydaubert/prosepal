import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    } catch (e) {
      if (!AuthErrorHandler.isCancellation(e)) {
        setState(() => _error = AuthErrorHandler.getMessage(e));
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              Colors.white,
              Colors.white,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
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
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
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
                // Error message
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
                      ],
                    ),
                  ).animate().fadeIn().shake(),
                  SizedBox(height: AppSpacing.lg),
                ],
                // Auth buttons
                Column(
                      children: [
                        // Apple Sign In (iOS/macOS only, first per Apple guidelines)
                        if (Platform.isIOS || Platform.isMacOS) ...[
                          _AuthButton(
                            onPressed: _isLoading ? null : _signInWithApple,
                            icon: Icons.apple,
                            label: 'Continue with Apple',
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          SizedBox(height: AppSpacing.md),
                        ],
                        // Google Sign In
                        _AuthButton(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: null,
                          customIcon: _GoogleLogo(),
                          label: 'Continue with Google',
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          borderColor: AppColors.textHint,
                        ),
                        SizedBox(height: AppSpacing.md),
                        // Email Sign In
                        _AuthButton(
                          onPressed: _isLoading ? null : _signInWithEmail,
                          icon: Icons.email_outlined,
                          label: 'Continue with Email',
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
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
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 1.seconds)
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
          elevation: borderColor != null ? 0 : 2,
          shadowColor: backgroundColor.withValues(alpha: 0.5),
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

/// Google 'G' logo with official brand colors
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.22;

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = strokeWidth;
    paint.strokeCap = StrokeCap.butt;

    // Blue arc
    paint.color = blue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -0.4,
      1.2,
      false,
      paint,
    );

    // Green arc
    paint.color = green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      0.8,
      1.0,
      false,
      paint,
    );

    // Yellow arc
    paint.color = yellow;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      1.8,
      0.9,
      false,
      paint,
    );

    // Red arc
    paint.color = red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      2.7,
      1.0,
      false,
      paint,
    );

    // Blue horizontal bar
    paint.style = PaintingStyle.fill;
    paint.color = blue;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.4, w * 0.45, strokeWidth),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
