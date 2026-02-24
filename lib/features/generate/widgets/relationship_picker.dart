import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/relationship.dart';
import '../../../shared/theme/app_colors.dart';

class RelationshipPicker extends StatelessWidget {
  const RelationshipPicker({
    super.key,
    required this.selectedRelationship,
    required this.onSelected,
  });

  final Relationship? selectedRelationship;
  final void Function(Relationship) onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Who is it for?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your relationship with the recipient',
          style: TextStyle(fontSize: 15, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        ...Relationship.values.asMap().entries.map((entry) {
          final index = entry.key;
          final relationship = entry.value;
          final isSelected = selectedRelationship == relationship;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child:
                _RelationshipTile(
                      key: ValueKey('relationship_${relationship.name}'),
                      relationship: relationship,
                      isSelected: isSelected,
                      onTap: () => onSelected(relationship),
                    )
                    .animate(key: ValueKey('rel_anim_$index'))
                    .fadeIn(
                      delay: Duration(milliseconds: index * 40),
                      duration: 250.ms,
                    )
                    .slideX(
                      begin: 0.08,
                      end: 0,
                      delay: Duration(milliseconds: index * 40),
                      duration: 250.ms,
                      curve: Curves.easeOut,
                    ),
          );
        }),
      ],
    ),
  );
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _RelationshipTile extends StatelessWidget {
  const _RelationshipTile({
    super.key,
    required this.relationship,
    required this.isSelected,
    required this.onTap,
  });

  final Relationship relationship;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${relationship.label}, ${isSelected ? 'selected' : 'not selected'}',
    button: true,
    selected: isSelected,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
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
                child: Text(
                  relationship.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                relationship.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textOnLight,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    ),
  );
}
