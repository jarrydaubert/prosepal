import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/log_service.dart';
import '../../shared/theme/app_colors.dart';

/// Dialog shown after copying a message to prompt saving the occasion to calendar
class SaveToCalendarDialog extends ConsumerStatefulWidget {
  const SaveToCalendarDialog({super.key, required this.result});

  final GenerationResult result;

  @override
  ConsumerState<SaveToCalendarDialog> createState() =>
      _SaveToCalendarDialogState();
}

class _SaveToCalendarDialogState extends ConsumerState<SaveToCalendarDialog> {
  late DateTime _selectedDate;
  bool _reminderEnabled = true;
  bool _isSaving = false;

  // Key for tracking if user has dismissed this dialog before
  static const _dismissedKey = 'calendar_dialog_dismissed_count';

  @override
  void initState() {
    super.initState();
    // Default to 7 days from now (a reasonable upcoming date)
    _selectedDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: Center(
                child: Text(
                  widget.result.occasion.emoji,
                  style: textTheme.headlineLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Save to Calendar?',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              "Get reminded before ${widget.result.recipientName ?? 'this occasion'}'s ${widget.result.occasion.label.toLowerCase()}",
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Date picker
            _DatePickerTile(
              selected: _selectedDate,
              onChanged: (d) => setState(() => _selectedDate = d),
            ),
            const SizedBox(height: 12),

            // Reminder toggle
            _ReminderToggle(
              enabled: _reminderEnabled,
              onChanged: (v) => setState(() => _reminderEnabled = v),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSaving ? null : _dismiss,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Not Now',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : Text(
                            'Save',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final calendarService = ref.read(calendarServiceProvider);
      final notificationService = ref.read(notificationServiceProvider);

      // Save to calendar
      final saved = await calendarService.saveOccasion(
        occasion: widget.result.occasion,
        date: _selectedDate,
        recipientName: widget.result.recipientName,
        relationship: widget.result.relationship,
        reminderEnabled: _reminderEnabled,
      );

      // Schedule reminder if enabled
      if (_reminderEnabled) {
        // Check/request notification permission
        if (!notificationService.notificationsEnabled) {
          if (!notificationService.hasAskedPermission) {
            await notificationService.requestPermission();
          }
        }

        if (notificationService.notificationsEnabled) {
          await notificationService.scheduleReminder(saved);
        }
      }

      Log.info('Occasion saved from results', {
        'occasion': widget.result.occasion.name,
        'date': _selectedDate.toIso8601String(),
        'reminder': _reminderEnabled,
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _dismiss() async {
    // Track dismissal count (to potentially stop showing after X dismissals)
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_dismissedKey) ?? 0;
    await prefs.setInt(_dismissedKey, count + 1);

    if (mounted) {
      Navigator.pop(context, false);
    }
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.selected, required this.onChanged});

  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('EEE, MMM d, y');

    return GestureDetector(
      onTap: () async {
        final theme = Theme.of(context);
        final picked = await showDatePicker(
          context: context,
          initialDate: selected,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          builder: (context, child) => Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: AppColors.primary,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderMedium),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    dateFormat.format(selected),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _ReminderToggle extends StatelessWidget {
  const _ReminderToggle({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? AppColors.primary : AppColors.borderMedium,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active,
            color: enabled ? AppColors.primary : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Remind me 7 days before',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
