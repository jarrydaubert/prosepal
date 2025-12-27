import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Shows remaining generations or Pro status
class UsageIndicator extends StatelessWidget {
  const UsageIndicator({
    super.key,
    required this.remaining,
    required this.isPro,
    this.onUpgrade,
  });

  final int remaining;
  final bool isPro;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    if (isPro) {
      return _ProBadge();
    }

    return _FreeUsageCard(
      remaining: remaining,
      onUpgrade: onUpgrade,
    );
  }
}

class _ProBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: AppColors.textPrimary),
          Gap(AppSpacing.xs),
          Text(
            'PRO',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _FreeUsageCard extends StatelessWidget {
  const _FreeUsageCard({
    required this.remaining,
    this.onUpgrade,
  });

  final int remaining;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onUpgrade,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: remaining > 0
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.error.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$remaining',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: remaining > 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    remaining > 0
                        ? 'Free messages remaining'
                        : 'Free trial ended',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Upgrade for unlimited',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
