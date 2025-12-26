import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/providers/providers.dart';
import '../../shared/atoms/app_button.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedPlanIndex = 2; // Default to yearly
  List<Package> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final offerings = await subscriptionService.getOfferings();
      
      if (offerings?.current != null) {
        setState(() {
          _packages = offerings!.current!.availablePackages;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  children: [
                    // Header
                    Text(
                      '✨',
                      style: TextStyle(fontSize: 48),
                    ).animate().scale(
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        ),
                    Gap(AppSpacing.lg),
                    Text(
                      'Unlock Prosepal Pro',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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

                    // Plans - from RevenueCat or fallback
                    if (_isLoading)
                      CircularProgressIndicator()
                    else if (_packages.isNotEmpty)
                      ..._packages.asMap().entries.map((entry) {
                        final package = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.md),
                          child: _PackageCard(
                            package: package,
                            isSelected: _selectedPlanIndex == entry.key,
                            onTap: () => setState(() => _selectedPlanIndex = entry.key),
                          ),
                        );
                      })
                    else
                      // Fallback to static plans if RevenueCat not configured
                      ...List.generate(3, (index) {
                        final plan = _plans[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.md),
                          child: _PlanCard(
                            plan: plan,
                            isSelected: _selectedPlanIndex == index,
                            onTap: () => setState(() => _selectedPlanIndex = index),
                          ),
                        );
                      }),

                    Gap(AppSpacing.lg),

                    // CTA
                    AppGradientButton(
                      label: 'Start Free Trial',
                      icon: Icons.rocket_launch,
                      onPressed: _subscribe,
                    ),

                    Gap(AppSpacing.md),

                    // Terms
                    Text(
                      _packages.isNotEmpty
                          ? 'Cancel anytime. Payment charged after trial.'
                          : 'Cancel anytime. ${_plans[_selectedPlanIndex].trialText}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    Gap(AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            // TODO: Open privacy policy
                          },
                          child: Text('Privacy'),
                        ),
                        Text('•', style: TextStyle(color: AppColors.textHint)),
                        TextButton(
                          onPressed: () {
                            // TODO: Open terms
                          },
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

  Future<void> _subscribe() async {
    if (_packages.isNotEmpty && _selectedPlanIndex < _packages.length) {
      // Use RevenueCat purchase
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final success = await subscriptionService.purchasePackage(
        _packages[_selectedPlanIndex],
      );
      
      if (success) {
        ref.read(isProProvider.notifier).state = true;
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome to Pro! 🎉'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // Demo mode fallback
      ref.read(isProProvider.notifier).state = true;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pro activated! (Demo mode)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _restorePurchases() async {
    final subscriptionService = ref.read(subscriptionServiceProvider);
    final restored = await subscriptionService.restorePurchases();
    
    if (restored) {
      ref.read(isProProvider.notifier).state = true;
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchases restored! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No purchases to restore'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.success,
            ),
          ),
          Gap(AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Plan {
  const _Plan({
    required this.name,
    required this.price,
    required this.period,
    required this.trialText,
    this.badge,
    this.savings,
  });

  final String name;
  final String price;
  final String period;
  final String trialText;
  final String? badge;
  final String? savings;
}

const _plans = [
  _Plan(
    name: 'Weekly',
    price: '\$2.99',
    period: '/week',
    trialText: '3-day free trial, then \$2.99/week.',
  ),
  _Plan(
    name: 'Monthly',
    price: '\$4.99',
    period: '/month',
    trialText: '7-day free trial, then \$4.99/month.',
  ),
  _Plan(
    name: 'Yearly',
    price: '\$29.99',
    period: '/year',
    trialText: '7-day free trial, then \$29.99/year.',
    badge: 'BEST VALUE',
    savings: 'Save 50%',
  ),
];

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  final _Plan plan;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Radio indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.textOnPrimary,
                          )
                        : null,
                  ),
                  Gap(AppSpacing.lg),

                  // Plan details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (plan.savings != null)
                          Text(
                            plan.savings!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            plan.price,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            plan.period,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Badge
        if (plan.badge != null)
          Positioned(
            top: -10,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                plan.badge!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Card for RevenueCat packages
class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  final Package package;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final isYearly = package.packageType == PackageType.annual;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Radio indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.textOnPrimary,
                          )
                        : null,
                  ),
                  Gap(AppSpacing.lg),

                  // Package details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title.replaceAll(' (Prosepal)', ''),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (isYearly)
                          Text(
                            'Save 50%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                  ),

                  // Price
                  Text(
                    product.priceString,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Best Value badge for yearly
        if (isYearly)
          Positioned(
            top: -10,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                'BEST VALUE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
