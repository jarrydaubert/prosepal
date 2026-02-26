import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/models/occasion.dart';
import '../../../shared/theme/app_spacing.dart';

class OccasionGrid extends StatelessWidget {
  const OccasionGrid({
    super.key,
    required this.onOccasionSelected,
  });

  final void Function(Occasion) onOccasionSelected;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.4,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final occasion = Occasion.values[index];
          return OccasionTile(
            occasion: occasion,
            onTap: () => onOccasionSelected(occasion),
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: index * 50),
                duration: 300.ms,
              )
              .scale(
                begin: Offset(0.9, 0.9),
                end: Offset(1, 1),
                delay: Duration(milliseconds: index * 50),
                duration: 300.ms,
                curve: Curves.easeOut,
              );
        },
        childCount: Occasion.values.length,
      ),
    );
  }
}

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
