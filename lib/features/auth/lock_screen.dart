import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/biometric_service.dart';
import '../../core/services/log_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _biometricType = 'Biometrics';
  bool _isAuthenticating = false;
  String? _errorMessage;
  int _failedAttempts = 0;

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    Log.info('Lock screen shown');
    _loadBiometricType();
    // Auto-trigger authentication on load
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _loadBiometricType() async {
    final type = await BiometricService.instance.biometricTypeName;
    if (mounted) setState(() => _biometricType = type);
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final result = await BiometricService.instance.authenticate(
      reason: 'Unlock Prosepal',
    );

    if (!mounted) return;

    setState(() => _isAuthenticating = false);

    if (result.success) {
      context.go('/home');
    } else {
      _failedAttempts++;

      // Show error message if there's one
      if (result.message != null) {
        setState(() => _errorMessage = result.message);

        // Auto-dismiss error after 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted && _errorMessage == result.message) {
            setState(() => _errorMessage = null);
          }
        });
      }

      // Handle specific error cases
      if (result.error == BiometricError.permanentlyLockedOut) {
        _showLockedOutDialog();
      }
    }
  }

  void _showLockedOutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Biometrics Locked'),
        content: const Text(
          'Too many failed attempts. Please unlock your device with your '
          'passcode first, then try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    final errorContainer = Semantics(
      liveRegion: true,
      label: 'Error: $_errorMessage',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );

    // Skip shake animation if user prefers reduced motion
    if (_reduceMotion) {
      return errorContainer.animate().fadeIn();
    }
    return errorContainer.animate().fadeIn().shake();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // App logo with shadow
              Semantics(
                label: 'Prosepal logo',
                image: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Prosepal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Tap to unlock',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 200.ms),

              const Spacer(),

              // Error message
              if (_errorMessage != null) ...[
                _buildErrorMessage(),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Unlock button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                    ),
                  ),
                  icon: _isAuthenticating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _biometricType == 'Face ID'
                              ? Icons.face
                              : Icons.fingerprint,
                        ),
                  label: Text(
                    _isAuthenticating
                        ? 'Authenticating...'
                        : 'Unlock with $_biometricType',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),

              // Retry hint after failed attempts
              if (_failedAttempts >= 2 && !_isAuthenticating) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Having trouble? Make sure $_biometricType is set up in your device settings.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(),
              ],

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
