import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/errors/auth_errors.dart';
import '../../core/providers/providers.dart';
import '../../core/services/log_service.dart';
import '../../shared/components/app_logo.dart';
import '../../shared/theme/app_colors.dart';
import '../paywall/paywall_sheet.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.redirectTo,
    this.isProRestore = false,
    this.autoRestore = false,
  });

  /// Optional route to navigate to after successful auth (e.g., 'paywall')
  final String? redirectTo;

  /// True if user has Pro from App Store but needs to sign in to claim it
  final bool isProRestore;

  /// True to auto-restore purchases after auth (for returning users)
  /// If restore finds Pro, navigates to home. Otherwise, navigates to paywall.
  final bool autoRestore;

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

  Future<void> _navigateAfterAuth() async {
    if (!mounted) return;

    // Auto-restore for returning users (device has used app before)
    // Try to restore purchases first, then navigate based on Pro status
    if (widget.autoRestore) {
      Log.info('Auth success: auto-restoring purchases for returning user');
      try {
        // Identify with RevenueCat first
        final authService = ref.read(authServiceProvider);
        if (authService.currentUser?.id != null) {
          await ref
              .read(subscriptionServiceProvider)
              .identifyUser(authService.currentUser!.id);
        }

        // Restore purchases from App Store
        final customerInfo = await Purchases.restorePurchases();
        final hasPro = customerInfo.entitlements.active.containsKey('pro');
        Log.info('Auto-restore completed', {'hasPro': hasPro});

        if (!mounted) return;

        if (hasPro) {
          // User has Pro - go to home, they can generate
          ref.invalidate(customerInfoProvider);
          Log.info('Auth success: Pro restored, navigating to home');
          context.go('/home');
          return;
        } else {
          // No Pro found - go home and show paywall sheet
          Log.info('Auth success: No Pro found, showing paywall sheet');
          context.go('/home');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) showPaywall(context, source: 'auth');
          });
          return;
        }
      } catch (e) {
        Log.warning('Auto-restore failed, showing paywall sheet', {
          'error': '$e',
        });
        if (!mounted) return;
        // On error, go home and show paywall sheet
        context.go('/home');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showPaywall(context, source: 'auth');
        });
        return;
      }
    }

    // If we have a redirect destination, handle it
    if (widget.redirectTo != null) {
      Log.info('Auth success: handling redirect', {
        'redirect': widget.redirectTo,
      });
      if (widget.redirectTo == 'paywall') {
        // Paywall is now a bottom sheet - go home and show it
        context.go('/home');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showPaywall(context, source: 'auth');
        });
      } else {
        // Other redirects (e.g., home) - navigate normally
        context.replace('/${widget.redirectTo}');
      }
      return;
    }

    // No redirect specified - check if we were pushed onto an existing stack
    // (e.g., from settings restore purchases). If so, just pop back.
    if (context.canPop()) {
      Log.info('Auth success: popping back to previous screen');
      context.pop();
      return;
    }

    // Fresh login flow - go straight to home
    // Biometric setup is offered after purchase, not after sign-in
    // (feels contradictory to prompt for security right after authenticating)
    Log.info('Auth success: navigating to home');
    context.go('/home');
  }

  Future<void> _signInWithApple() async {
    if (_isLoading) return; // Prevent double-tap race condition
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      // Timeout prevents stuck spinner if OAuth window killed externally
      final response = await authService.signInWithApple().timeout(
        const Duration(minutes: 2),
        onTimeout: () =>
            throw Exception('Sign in timed out. Please try again.'),
      );
      if (response.user != null) {
        // Sync usage from server (restores usage after reinstall)
        // Non-critical - don't block auth success if sync fails
        try {
          await ref.read(usageServiceProvider).syncFromServer();
        } catch (e) {
          Log.warning('Usage sync failed after auth', {'error': '$e'});
        }
      }
      await _navigateAfterAuth();
    } catch (e) {
      if (!AuthErrorHandler.isCancellation(e)) {
        _showError(AuthErrorHandler.getMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return; // Prevent double-tap race condition
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      // Timeout prevents stuck spinner if OAuth window killed externally
      final response = await authService.signInWithGoogle().timeout(
        const Duration(minutes: 2),
        onTimeout: () =>
            throw Exception('Sign in timed out. Please try again.'),
      );
      if (response.user != null) {
        // Sync usage from server (restores usage after reinstall)
        // Non-critical - don't block auth success if sync fails
        try {
          await ref.read(usageServiceProvider).syncFromServer();
        } catch (e) {
          Log.warning('Usage sync failed after auth', {'error': '$e'});
        }
      }
      await _navigateAfterAuth();
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 380;

    // Responsive sizing
    final logoSize = size.width * 0.38; // ~38% of screen width
    final titleSize = isSmallScreen ? 24.0 : 28.0;
    final subtitleSize = isSmallScreen ? 15.0 : 16.0;

    // Can dismiss UNLESS in payment flow (redirectTo='paywall')
    // Payment flow requires auth - no escape
    final isPaywallRedirect = widget.redirectTo == 'paywall';
    final canDismiss =
        !isPaywallRedirect && (widget.redirectTo != null || context.canPop());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Close button (top-right) when user can dismiss
            if (canDismiss)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () {
                    Log.info('Auth dismissed', {'redirect': widget.redirectTo});
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: const Icon(Icons.close, size: 28),
                  color: AppColors.textSecondary,
                  tooltip: 'Close',
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // App Logo with bold border container
                  Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 4,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: AppLogo(size: logoSize - 20),
                        ),
                      )
                      .animate(key: const ValueKey('logo'))
                      .fadeIn(duration: 400.ms)
                      .scale(delay: 100.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                        'Welcome to Prosepal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleSize,
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
                          fontSize: subtitleSize,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      )
                      .animate(key: const ValueKey('tagline'))
                      .fadeIn(delay: 500.ms),

                  // Subscription sign-in prompt (when coming from paywall)
                  if (isPaywallRedirect) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_circle_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Create an account to purchase a subscription',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                  ],

                  // Pro restore banner
                  if (widget.isProRestore) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.success,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pro subscription found!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                Text(
                                  'Sign in to restore your Pro access',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                  ],

                  const Spacer(flex: 2),

                  // Error message
                  if (_error != null) ...[
                    _ErrorBanner(message: _error!, onDismiss: _dismissError),
                    const SizedBox(height: 20),
                  ],

                  // Auth buttons
                  Column(
                        children: [
                          // Apple Sign In (iOS/macOS only, first per Apple guidelines)
                          // IMPORTANT: Use official SignInWithAppleButton styling
                          // Custom text/styling violates Apple HIG and causes rejection
                          if (Platform.isIOS || Platform.isMacOS) ...[
                            _AuthButton(
                              onPressed: _isLoading ? null : _signInWithApple,
                              isLoading: _isLoading,
                              child: SizedBox(
                                height: 56,
                                child: SignInWithAppleButton(
                                  onPressed: _signInWithApple,
                                  // Use default styling per Apple Human Interface Guidelines
                                  style: SignInWithAppleButtonStyle.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Google Sign In (branding: 24px icon per Google guidelines)
                          _AuthButton(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            isLoading: _isLoading,
                            style: _AuthButtonStyle.outlined,
                            icon: Image.asset(
                              'assets/images/icons/google_g.png',
                              width: 24,
                              height: 24,
                            ),
                            label: 'Sign in with Google',
                          ),
                          const SizedBox(height: 12),

                          // Email Sign In
                          _AuthButton(
                            onPressed: _isLoading ? null : _signInWithEmail,
                            isLoading: _isLoading,
                            style: _AuthButtonStyle.outlined,
                            icon: const Icon(Icons.email_outlined, size: 24),
                            label: 'Sign in with Email',
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
          ],
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

    Color backgroundColor;
    Color textColor;
    Border? border;

    if (isPrimary) {
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
    } else {
      // Google and Email: consistent white bg with subtle border
      backgroundColor = Colors.white;
      textColor = const Color(0xFF1F1F1F);
      border = Border.all(color: Colors.grey.shade300, width: 1.5);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: border,
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
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: textColor,
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
  const _ErrorBanner({required this.message, required this.onDismiss});

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
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
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
  const _LegalText({required this.onTermsTap, required this.onPrivacyTap});

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(
          'By continuing, you agree to our ',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
        Text(
          ' and ',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
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
