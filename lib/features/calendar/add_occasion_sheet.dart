import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../shared/components/app_button.dart';
import '../../shared/theme/app_colors.dart';

class AddOccasionSheet extends ConsumerStatefulWidget {
  const AddOccasionSheet({super.key, this.existingOccasion});

  final SavedOccasion? existingOccasion;

  @override
  ConsumerState<AddOccasionSheet> createState() => _AddOccasionSheetState();
}

class _AddOccasionSheetState extends ConsumerState<AddOccasionSheet> {
  late Occasion _selectedOccasion;
  late DateTime _selectedDate;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  Relationship? _selectedRelationship;
  bool _reminderEnabled = true;
  int _reminderDays = 7;
  bool _isSaving = false;

  bool get _isEditing => widget.existingOccasion != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingOccasion;
    _selectedOccasion = existing?.occasion ?? Occasion.birthday;
    _selectedDate =
        existing?.date ?? DateTime.now().add(const Duration(days: 7));
    _nameController = TextEditingController(
      text: existing?.recipientName ?? '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _selectedRelationship = existing?.relationship;
    _reminderEnabled = existing?.reminderEnabled ?? true;
    _reminderDays = existing?.reminderDaysBefore ?? 7;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _isEditing ? 'Edit Occasion' : 'Add Occasion',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Occasion picker
            const _SectionLabel('Occasion'),
            const SizedBox(height: 8),
            _OccasionPicker(
              selected: _selectedOccasion,
              onChanged: (o) => setState(() => _selectedOccasion = o),
            ),
            const SizedBox(height: 20),

            // Date picker
            const _SectionLabel('Date'),
            const SizedBox(height: 8),
            _DatePicker(
              selected: _selectedDate,
              onChanged: (d) => setState(() => _selectedDate = d),
            ),
            const SizedBox(height: 20),

            // Recipient name
            const _SectionLabel('Recipient Name (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Mom, John, Sarah',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Relationship (optional)
            const _SectionLabel('Relationship (optional)'),
            const SizedBox(height: 8),
            _RelationshipPicker(
              selected: _selectedRelationship,
              onChanged: (r) => setState(() => _selectedRelationship = r),
            ),
            const SizedBox(height: 20),

            // Notes
            const _SectionLabel('Notes (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add any notes or reminders...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Reminder toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Remind me before',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _reminderEnabled,
                        onChanged: (v) => setState(() => _reminderEnabled = v),
                        activeTrackColor: AppColors.primary,
                      ),
                    ],
                  ),
                  if (_reminderEnabled) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final days in [3, 7, 14])
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: days != 14 ? 8 : 0,
                              ),
                              child: _ReminderOption(
                                days: days,
                                isSelected: _reminderDays == days,
                                onTap: () =>
                                    setState(() => _reminderDays = days),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            AppButton(
              label: _isEditing ? 'Save Changes' : 'Add to Calendar',
              icon: _isEditing ? Icons.check : Icons.add,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final calendarService = ref.read(calendarServiceProvider);

      SavedOccasion result;

      if (_isEditing) {
        result = widget.existingOccasion!.copyWith(
          occasion: _selectedOccasion,
          date: _selectedDate,
          recipientName: _nameController.text.isEmpty
              ? null
              : _nameController.text,
          relationship: _selectedRelationship,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          reminderEnabled: _reminderEnabled,
          reminderDaysBefore: _reminderDays,
        );
        await calendarService.updateOccasion(result);
      } else {
        result = await calendarService.saveOccasion(
          occasion: _selectedOccasion,
          date: _selectedDate,
          recipientName: _nameController.text.isEmpty
              ? null
              : _nameController.text,
          relationship: _selectedRelationship,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          reminderEnabled: _reminderEnabled,
          reminderDaysBefore: _reminderDays,
        );
      }

      if (mounted) {
        Navigator.pop(context, result);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

// =============================================================================
// Components
// =============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
  );
}

class _OccasionPicker extends StatelessWidget {
  const _OccasionPicker({required this.selected, required this.onChanged});

  final Occasion selected;
  final ValueChanged<Occasion> onChanged;

  @override
  Widget build(BuildContext context) {
    // Show most common occasions first
    final occasions = [
      Occasion.birthday,
      Occasion.anniversary,
      Occasion.wedding,
      Occasion.graduation,
      Occasion.christmas,
      Occasion.mothersDay,
      Occasion.fathersDay,
      Occasion.valentinesDay,
      Occasion.thankYou,
      Occasion.getWell,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: occasions.map((o) {
        final isSelected = o == selected;
        return GestureDetector(
          onTap: () => onChanged(o),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(o.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  o.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({required this.selected, required this.onChanged});

  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dateFormat.format(selected),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _RelationshipPicker extends StatelessWidget {
  const _RelationshipPicker({required this.selected, required this.onChanged});

  final Relationship? selected;
  final ValueChanged<Relationship?> onChanged;

  @override
  Widget build(BuildContext context) {
    final relationships = <Relationship?>[
      null, // None option
      Relationship.parent,
      Relationship.grandparent,
      Relationship.sibling,
      Relationship.child,
      Relationship.romantic,
      Relationship.closeFriend,
      Relationship.colleague,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: relationships.map((r) {
        final isSelected = r == selected;
        final label = r?.label ?? 'None';
        return GestureDetector(
          onTap: () => onChanged(r),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ReminderOption extends StatelessWidget {
  const _ReminderOption({
    required this.days,
    required this.isSelected,
    required this.onTap,
  });

  final int days;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$days days',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    ),
  );
}
