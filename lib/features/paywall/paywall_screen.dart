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

      if (success && mounted) {
        ref.read(isProProvider.notifier).state = true;
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
      } else if (mounted) {
        // User dismissed paywall or it failed to load - show fallback
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // RevenueCat UI failed - show fallback
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _activateDemoMode() async {
    ref.read(isProProvider.notifier).state = true;
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pro activated! (Demo mode)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          SnackBar(
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
          SnackBar(
            content: Text('No purchases to restore'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
              CircularProgressIndicator(color: AppColors.primary),
              Gap(AppSpacing.lg),
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
                  icon: Icon(Icons.close),
                  onPressed: () => context.pop(),
                  tooltip: 'Close',
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  children: [
                    // Header
                    Text('✨', style: TextStyle(fontSize: 48)).animate().scale(
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
                    Gap(AppSpacing.lg),
                    Text(
                      'Unlock Prosepal Pro',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Gap(AppSpacing.sm),
                    Text(
                      'Write the perfect message, every time',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Gap(AppSpacing.xxl),

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

                    Gap(AppSpacing.xxl),

                    // Info card
                    Container(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 32,
                          ),
                          Gap(AppSpacing.md),
                          Text(
                            'Subscription Setup Required',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          Gap(AppSpacing.sm),
                          Text(
                            'Configure your RevenueCat products in the dashboard to enable in-app purchases.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    Gap(AppSpacing.xl),

                    // Retry RevenueCat button
                    AppButton(
                      label: 'Retry Loading Subscriptions',
                      icon: Icons.refresh,
                      onPressed: _showRevenueCatPaywall,
                    ),

                    Gap(AppSpacing.md),

                    // Demo mode button (for testing)
                    AppButton(
                      label: 'Activate Demo Mode',
                      icon: Icons.science_outlined,
                      style: AppButtonStyle.secondary,
                      onPressed: _activateDemoMode,
                    ),

                    Gap(AppSpacing.lg),

                    // Restore & Legal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => context.pushNamed('privacy'),
                          child: Text('Privacy'),
                        ),
                        Text('•', style: TextStyle(color: AppColors.textHint)),
                        TextButton(
                          onPressed: () => context.pushNamed('terms'),
                          child: Text('Terms'),
                        ),
                        Text('•', style: TextStyle(color: AppColors.textHint)),
                        TextButton(
                          onPressed: _restorePurchases,
                          child: Text('Restore'),
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
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.success),
            ),
            Gap(AppSpacing.md),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
