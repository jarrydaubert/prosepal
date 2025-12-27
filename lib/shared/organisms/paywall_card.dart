import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../atoms/app_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Subscription option card for paywall
class PaywallCard extends StatelessWidget {
  const PaywallCard({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    required this.onTap,
    this.isPopular = false,
    this.isBestValue = false,
    this.savings,
    this.trialDays,
  });

  final String title;
  final String price;
  final String period;
  final VoidCallback onTap;
  final bool isPopular;
  final bool isBestValue;
  final String? savings;
  final int? trialDays;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppCard(
          onTap: onTap,
          borderColor: isPopular || isBestValue ? AppColors.primary : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (trialDays != null)
                          Text(
                            '$trialDays-day free trial',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.success),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        period,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (savings != null) ...[
                Gap(AppSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    savings!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isPopular || isBestValue)
          Positioned(
            top: -10,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                isBestValue ? 'BEST VALUE' : 'POPULAR',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
