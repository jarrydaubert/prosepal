import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/models/relationship.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';

class RelationshipPicker extends StatelessWidget {
  const RelationshipPicker({
    super.key,
    required this.selectedRelationship,
    required this.onSelected,
  });

  final Relationship? selectedRelationship;
  final void Function(Relationship) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who is it for?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Gap(AppSpacing.sm),
          Text(
            'Select your relationship with the recipient',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          Gap(AppSpacing.xl),
          ...Relationship.values.asMap().entries.map((entry) {
            final index = entry.key;
            final relationship = entry.value;
            final isSelected = selectedRelationship == relationship;

            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child:
                  _RelationshipTile(
                        relationship: relationship,
                        isSelected: isSelected,
                        onTap: () => onSelected(relationship),
                      )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: index * 50),
                        duration: 200.ms,
                      )
                      .slideX(
                        begin: 0.1,
                        end: 0,
                        delay: Duration(milliseconds: index * 50),
                        duration: 200.ms,
                        curve: Curves.easeOut,
                      ),
            );
          }),
        ],
      ),
    );
  }
}

class _RelationshipTile extends StatelessWidget {
  const _RelationshipTile({
    required this.relationship,
    required this.isSelected,
    required this.onTap,
  });

  final Relationship relationship;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
              Text(relationship.emoji, style: TextStyle(fontSize: 28)),
              Gap(AppSpacing.lg),
              Expanded(
                child: Text(
                  relationship.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
