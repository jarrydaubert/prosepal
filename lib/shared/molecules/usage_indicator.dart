import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class UsageIndicator extends StatelessWidget {
  const UsageIndicator({
    super.key,
    required this.remaining,
    required this.isPro,
    this.onUpgrade,
    this.onProTap,
  });

  final int remaining;
  final bool isPro;
  final VoidCallback? onUpgrade;
  final VoidCallback? onProTap;

  @override
  Widget build(BuildContext context) {
    if (isPro) {
      return _ProBadge(onTap: onProTap);
    }

    return _FreeUsageCard(remaining: remaining, onUpgrade: onUpgrade);
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _ProBadge extends StatelessWidget {
  const _ProBadge({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pro subscription active',
      button: onTap != null,
      hint: onTap != null ? 'Double tap to manage subscription' : null,
      child: GestureDetector(
        onTap: () {
          onTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PRO',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FreeUsageCard extends StatelessWidget {
  const _FreeUsageCard({required this.remaining, this.onUpgrade});

  final int remaining;
  final VoidCallback? onUpgrade;

  Color get _statusColor => remaining > 0 ? AppColors.success : AppColors.error;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: remaining > 0
          ? '$remaining free messages remaining'
          : 'Free trial ended',
      button: true,
      hint: 'Double tap to upgrade to Pro',
      child: GestureDetector(
        onTap: () {
          onUpgrade?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _statusColor, width: 3),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _statusColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remaining > 0
                          ? 'Free messages remaining'
                          : 'Free trial ended',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to unlock 500/month',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: _statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
