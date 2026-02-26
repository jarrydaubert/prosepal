import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/models/tone.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';

class ToneSelector extends StatelessWidget {
  const ToneSelector({
    super.key,
    required this.selectedTone,
    required this.onSelected,
  });

  final Tone? selectedTone;
  final void Function(Tone) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set the tone',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Gap(AppSpacing.sm),
          Text(
            'How do you want the message to feel?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          Gap(AppSpacing.xl),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.2,
            ),
            itemCount: Tone.values.length,
            itemBuilder: (context, index) {
              final tone = Tone.values[index];
              final isSelected = selectedTone == tone;

              return _ToneTile(
                    tone: tone,
                    isSelected: isSelected,
                    onTap: () => onSelected(tone),
                  )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: index * 50),
                    duration: 200.ms,
                  )
                  .scale(
                    begin: Offset(0.9, 0.9),
                    end: Offset(1, 1),
                    delay: Duration(milliseconds: index * 50),
                    duration: 200.ms,
                    curve: Curves.easeOut,
                  );
            },
          ),
        ],
      ),
    );
  }
}

class _ToneTile extends StatelessWidget {
  const _ToneTile({
    required this.tone,
    required this.isSelected,
    required this.onTap,
  });

  final Tone tone;
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tone.emoji, style: TextStyle(fontSize: 32)),
              Gap(AppSpacing.sm),
              Text(
                tone.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : null,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(AppSpacing.xs),
              Text(
                tone.description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
