import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/log_service.dart';
import '../../shared/components/app_button.dart';
import '../../shared/theme/app_colors.dart';
import 'add_occasion_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final occasionsAsync = ref.watch(upcomingOccasionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Upcoming Occasions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: occasionsAsync.when(
        data: _buildContent,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading occasions: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOccasion,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Occasion',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildContent(List<SavedOccasion> occasions) {
    if (occasions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: occasions.length,
      itemBuilder: (context, index) {
        final occasion = occasions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _OccasionCard(
            occasion: occasion,
            onTap: () => _onOccasionTap(occasion),
            onEdit: () => _showEditOccasion(occasion),
            onDelete: () => _deleteOccasion(occasion),
            onExport: () => _exportToCalendar(occasion),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: const Center(
              child: Text('📅', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No upcoming occasions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save occasions to get reminders\nbefore the big day',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Add Your First Occasion',
            icon: Icons.add,
            onPressed: _showAddOccasion,
          ),
        ],
      ),
    ),
  );

  void _showAddOccasion() {
    showModalBottomSheet<SavedOccasion?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddOccasionSheet(),
    ).then((result) {
      if (result != null) {
        ref.invalidate(upcomingOccasionsProvider);
        _scheduleReminder(result);
      }
    });
  }

  void _showEditOccasion(SavedOccasion occasion) {
    showModalBottomSheet<SavedOccasion?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddOccasionSheet(existingOccasion: occasion),
    ).then((result) {
      if (result != null) {
        ref.invalidate(upcomingOccasionsProvider);
        _scheduleReminder(result);
      }
    });
  }

  void _onOccasionTap(SavedOccasion occasion) {
    // Pre-fill generation form and navigate
    ref.read(selectedOccasionProvider.notifier).state = occasion.occasion;
    if (occasion.relationship != null) {
      ref.read(selectedRelationshipProvider.notifier).state =
          occasion.relationship;
    }
    if (occasion.recipientName != null) {
      ref.read(recipientNameProvider.notifier).state = occasion.recipientName!;
    }

    // Mark as generated
    ref.read(calendarServiceProvider).markAsGenerated(occasion.id);

    context.go('/generate');
    Log.info('Occasion tapped for generation', {
      'occasion': occasion.occasion.name,
    });
  }

  Future<void> _deleteOccasion(SavedOccasion occasion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Occasion?'),
        content: Text(
          'Remove ${occasion.occasion.label}'
          '${occasion.recipientName != null ? ' for ${occasion.recipientName}' : ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(calendarServiceProvider).deleteOccasion(occasion.id);
      await ref.read(notificationServiceProvider).cancelReminder(occasion.id);
      ref.invalidate(upcomingOccasionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Occasion deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportToCalendar(SavedOccasion occasion) async {
    final success = await ref
        .read(calendarServiceProvider)
        .exportToNativeCalendar(occasion);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Added to calendar' : 'Could not add to calendar',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _scheduleReminder(SavedOccasion occasion) async {
    if (!occasion.reminderEnabled) return;

    final notificationService = ref.read(notificationServiceProvider);

    // Check if we have permission
    if (!notificationService.notificationsEnabled) {
      if (!notificationService.hasAskedPermission) {
        // First time - ask for permission
        final granted = await notificationService.requestPermission();
        if (!granted) return;
      } else {
        return; // Already asked and denied
      }
    }

    await notificationService.scheduleReminder(occasion);
  }
}

// =============================================================================
// Occasion Card Component
// =============================================================================

class _OccasionCard extends StatelessWidget {
  const _OccasionCard({
    required this.occasion,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
  });

  final SavedOccasion occasion;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d');
    final isUrgent = occasion.daysUntil <= 7 && occasion.daysUntil >= 0;

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUrgent ? AppColors.warning : AppColors.primary,
            width: isUrgent ? 3 : 2,
          ),
          boxShadow: [
            if (isUrgent)
              BoxShadow(
                color: AppColors.warning.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUrgent
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : AppColors.primaryLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  // Emoji
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUrgent ? AppColors.warning : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        occasion.occasion.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          occasion.occasion.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnLight,
                          ),
                        ),
                        if (occasion.recipientName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'for ${occasion.recipientName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Days until badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isUrgent ? AppColors.warning : AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      occasion.daysUntilDisplay,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(occasion.date),
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      if (occasion.reminderEnabled) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.notifications_active,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${occasion.reminderDaysBefore}d reminder',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Notes
                  if (occasion.notes != null && occasion.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      occasion.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Action buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionChip(
                        icon: Icons.auto_awesome,
                        label: 'Generate',
                        onTap: onTap,
                        isPrimary: true,
                      ),
                      _ActionChip(
                        icon: Icons.event,
                        label: 'Export',
                        onTap: onExport,
                      ),
                      _ActionChip(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onTap: onEdit,
                      ),
                      _ActionChip(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        onTap: onDelete,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : isPrimary
        ? AppColors.primary
        : Colors.grey[600]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}
