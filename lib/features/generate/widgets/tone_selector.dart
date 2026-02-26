import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/tone.dart';
import '../../../shared/theme/app_colors.dart';

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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set the tone',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How do you want the message to feel?',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: Tone.values.length,
            itemBuilder: (context, index) {
              final tone = Tone.values[index];
              final isSelected = selectedTone == tone;

              return _ToneTile(
                    key: ValueKey('tone_${tone.name}'),
                    tone: tone,
                    isSelected: isSelected,
                    onTap: () => onSelected(tone),
                  )
                  .animate(key: ValueKey('tone_anim_$index'))
                  .fadeIn(
                    delay: Duration(milliseconds: index * 40),
                    duration: 250.ms,
                  )
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    delay: Duration(milliseconds: index * 40),
                    duration: 250.ms,
                    curve: Curves.easeOut,
                  );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _ToneTile extends StatelessWidget {
  const _ToneTile({
    super.key,
    required this.tone,
    required this.isSelected,
    required this.onTap,
  });

  final Tone tone;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${tone.label} tone: ${tone.description}, ${isSelected ? 'selected' : 'not selected'}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () {
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: isSelected ? 3 : 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(tone.emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tone.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                tone.description,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              if (isSelected) ...[
                const SizedBox(height: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
