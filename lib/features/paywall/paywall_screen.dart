import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';
import '../../shared/atoms/app_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

/// Paywall screen that uses RevenueCat's native UI when available,
/// with a custom fallback for demo/testing.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-show RevenueCat paywall on load
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showRevenueCatPaywall(),
    );
  }

  Future<void> _showRevenueCatPaywall() async {
    setState(() => _isLoading = true);

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final success = await subscriptionService.showPaywall();

      if (!mounted) return;

      if (success) {
        // User purchased - update state and show success
        ref.read(isProProvider.notifier).state = true;
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                Gap(AppSpacing.sm),
                Text('Welcome to Pro!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // User dismissed paywall - just go back
        context.pop();
      }
    } catch (e) {
      // RevenueCat UI failed to load - show fallback
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final restored = await subscriptionService.restorePurchases();

      if (restored && mounted) {
        ref.read(isProProvider.notifier).state = true;
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                Gap(AppSpacing.sm),
                Text('Purchases restored!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No purchases to restore'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to restore purchases'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while RevenueCat UI is being presented
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const Gap(AppSpacing.lg),
              Text(
                'Loading subscription options...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback UI when RevenueCat native paywall isn't available
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: Semantics(
                label: 'Close',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                  tooltip: 'Close',
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  children: [
                    // Header
                    const Text('✨', style: TextStyle(fontSize: 48))
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut),
                    const Gap(AppSpacing.lg),
                    Text(
                      'Unlock Prosepal Pro',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(AppSpacing.sm),
                    Text(
                      'Write the perfect message, every time',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(AppSpacing.xxl),

                    // Features
                    ..._features.asMap().entries.map((entry) {
                      return _FeatureRow(
                            icon: entry.value.icon,
                            text: entry.value.text,
                          )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: entry.key * 100),
                          )
                          .slideX(
                            begin: 0.2,
                            end: 0,
                            delay: Duration(milliseconds: entry.key * 100),
                          );
                    }),

                    const Gap(AppSpacing.xxl),

                    // Error message
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            color: AppColors.warning,
                            size: 32,
                          ),
                          const Gap(AppSpacing.md),
                          Text(
                            'Unable to Load',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const Gap(AppSpacing.sm),
                          Text(
                            'Please check your internet connection and try again.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const Gap(AppSpacing.xl),

                    // Retry button
                    AppButton(
                      label: 'Try Again',
                      icon: Icons.refresh,
                      onPressed: _showRevenueCatPaywall,
                    ),

                    const Gap(AppSpacing.lg),

                    // Restore & Legal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => context.pushNamed('privacy'),
                          child: const Text('Privacy'),
                        ),
                        const Text(
                          '•',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                        TextButton(
                          onPressed: () => context.pushNamed('terms'),
                          child: const Text('Terms'),
                        ),
                        const Text(
                          '•',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                        TextButton(
                          onPressed: _restorePurchases,
                          child: const Text('Restore'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature(this.icon, this.text);
  final IconData icon;
  final String text;
}

const _features = [
  _Feature(Icons.all_inclusive, 'Unlimited message generations'),
  _Feature(Icons.auto_awesome, 'All occasions & tones'),
  _Feature(Icons.history, 'Message history (coming soon)'),
  _Feature(Icons.devices, 'Sync across devices (coming soon)'),
  _Feature(Icons.block, 'No ads, ever'),
];

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.success),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
