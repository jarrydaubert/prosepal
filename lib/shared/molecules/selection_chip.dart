import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Selectable chip with emoji and label (for relationships, tones, etc.)
class SelectionChip extends StatelessWidget {
  const SelectionChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.emoji,
    this.icon,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? emoji;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveColor.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: isSelected ? effectiveColor : AppColors.surfaceVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 18)),
                const Gap(AppSpacing.sm),
              ] else if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? effectiveColor : AppColors.textSecondary,
                ),
                const Gap(AppSpacing.sm),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? effectiveColor : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid of selection chips
class SelectionChipGroup<T> extends StatelessWidget {
  const SelectionChipGroup({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
    this.emojiBuilder,
    this.colorBuilder,
  });

  final List<T> items;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;
  final String Function(T)? emojiBuilder;
  final Color Function(T)? colorBuilder;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        return SelectionChip(
          label: labelBuilder(item),
          emoji: emojiBuilder?.call(item),
          color: colorBuilder?.call(item),
          isSelected: item == selected,
          onTap: () => onSelected(item),
        );
      }).toList(),
    );
  }
}
