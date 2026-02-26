import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/biometric_service.dart';
import '../../shared/theme/app_colors.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final _biometricService = BiometricService.instance;
  String _biometricName = 'Face ID';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricType();
  }

  Future<void> _loadBiometricType() async {
    final name = await _biometricService.biometricTypeName;
    if (mounted) setState(() => _biometricName = name);
  }

  Future<void> _enableBiometrics() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    final result = await _biometricService.authenticate(
      reason: 'Authenticate to enable $_biometricName',
    );

    if (result.success) {
      await _biometricService.setEnabled(true);
      if (mounted) context.go('/home');
    } else if (result.error != BiometricError.cancelled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Could not enable $_biometricName'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _skipBiometrics() {
    HapticFeedback.lightImpact();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isFaceId = _biometricName == 'Face ID';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon with bold border
              Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 4),
                    ),
                    child: Icon(
                      isFaceId ? Icons.face : Icons.fingerprint,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  )
                  .animate(key: const ValueKey('biometric_icon'))
                  .fadeIn(duration: 400.ms)
                  .scale(delay: 100.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 40),

              // Title
              Text(
                    'Enable $_biometricName?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                  .animate(key: const ValueKey('title'))
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Quickly and securely unlock Prosepal\nwith $_biometricName.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 500.ms),

              const Spacer(flex: 2),

              // Benefits
              _BenefitRow(
                icon: Icons.lock_outline,
                text: 'Keep your messages private',
              ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),

              const SizedBox(height: 16),

              _BenefitRow(
                icon: Icons.flash_on,
                text:
                    'Unlock instantly with ${isFaceId ? "a glance" : "your fingerprint"}',
              ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1, end: 0),

              const Spacer(),

              // Enable button
              _PrimaryButton(
                label: 'Enable $_biometricName',
                isLoading: _isLoading,
                onPressed: _enableBiometrics,
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 16),

              // Skip button
              TextButton(
                onPressed: _isLoading ? null : _skipBiometrics,
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

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
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
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
        if (!widget.isLoading) widget.onPressed();
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
