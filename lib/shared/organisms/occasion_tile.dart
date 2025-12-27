import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/models/occasion.dart';
import '../theme/app_spacing.dart';

/// Colorful occasion tile for the home screen grid
class OccasionTile extends StatelessWidget {
  const OccasionTile({
    super.key,
    required this.occasion,
    required this.onTap,
  });

  final Occasion occasion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          decoration: BoxDecoration(
            color: occasion.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: occasion.color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                occasion.emoji,
                style: TextStyle(fontSize: 32),
              ),
              Gap(AppSpacing.sm),
              Text(
                occasion.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: occasion.color,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
