import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/log_service.dart';
import '../../shared/components/app_back_button.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_emoji.dart';
import '../../shared/components/app_surface_card.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/app_spacing.dart';
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
    final showFloatingAddButton = occasionsAsync.maybeWhen(
      data: (occasions) => occasions.isNotEmpty,
      orElse: () => false,
    );

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
        leading: AppBackButton(onPressed: () => context.go('/home')),
      ),
      body: occasionsAsync.when(
        data: _buildContent,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildErrorState(e),
      ),
      floatingActionButton: showFloatingAddButton
          ? FloatingActionButton.extended(
              onPressed: _showAddOccasion,
              backgroundColor: AppColors.primary,
              icon: const Icon(
                AppIcons.add,
                color: AppColors.textOnPrimary,
                size: AppSpacing.iconSizeSmall,
              ),
              label: const Text(
                'Add Occasion',
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
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
              child: AppEmoji(emoji: '📅', size: AppSpacing.iconSizeXL),
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
          const Text(
            'Save occasions to get reminders\nbefore the big day',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Add Your First Occasion',
            icon: AppIcons.add,
            onPressed: _showAddOccasion,
          ),
        ],
      ),
    ),
  );

  Widget _buildErrorState(Object error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: AppSurfaceCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: AppColors.primary,
                size: AppSpacing.iconSizeLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Could not load occasions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnLight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textOnLightSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Try Again',
              icon: AppIcons.refresh,
              onPressed: () => ref.invalidate(upcomingOccasionsProvider),
            ),
          ],
        ),
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
      child: AppSurfaceCard(
        padding: EdgeInsets.zero,
        borderColor: isUrgent ? AppColors.warning : AppColors.primary,
        borderWidth: isUrgent
            ? AppSurfaceTokens.strongBorderWidth
            : AppSurfaceTokens.emphasizedBorderWidth,
        boxShadow: isUrgent
            ? [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isUrgent
                      ? [
                          AppColors.warning.withValues(alpha: 0.16),
                          AppColors.primaryLight,
                        ]
                      : [AppColors.primaryLight, AppColors.surfaceLight],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useCompactHeader = constraints.maxWidth < 280;
                  final badge = Container(
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
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isUrgent
                                ? AppColors.warning
                                : AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: AppEmoji(
                            emoji: occasion.occasion.emoji,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (useCompactHeader) ...[
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
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textOnLightSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 10),
                              badge,
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          occasion.occasion.label,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textOnLight,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (occasion.recipientName != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'for ${occasion.recipientName}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors
                                                  .textOnLightSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  badge,
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            AppIcons.date,
                            size: AppSpacing.iconSizeXS,
                            color: AppColors.textOnLightSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFormat.format(occasion.date),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textOnLight,
                            ),
                          ),
                        ],
                      ),
                      if (occasion.reminderEnabled)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              AppIcons.reminder,
                              size: AppSpacing.iconSizeXS,
                              color: AppColors.textOnLightSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${occasion.reminderDaysBefore}d reminder',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textOnLightSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Notes
                  if (occasion.notes != null && occasion.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      occasion.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textOnLightSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Action buttons
                  LayoutBuilder(
                    builder: (context, constraints) => Column(
                      children: [
                        _ActionChip(
                          icon: AppIcons.regenerate,
                          label: 'Write a message',
                          onTap: onTap,
                          isPrimary: true,
                          fullWidth: true,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (constraints.maxWidth >= 340)
                          Row(
                            children: [
                              Expanded(
                                child: _ActionChip(
                                  icon: AppIcons.export,
                                  label: 'Export',
                                  onTap: onExport,
                                  compact: true,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _ActionChip(
                                  icon: AppIcons.edit,
                                  label: 'Edit',
                                  onTap: onEdit,
                                  compact: true,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _ActionChip(
                                  icon: AppIcons.delete,
                                  label: 'Delete',
                                  onTap: onDelete,
                                  isDestructive: true,
                                  compact: true,
                                ),
                              ),
                            ],
                          )
                        else
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              _ActionChip(
                                icon: AppIcons.export,
                                label: 'Export',
                                onTap: onExport,
                              ),
                              _ActionChip(
                                icon: AppIcons.edit,
                                label: 'Edit',
                                onTap: onEdit,
                              ),
                              _ActionChip(
                                icon: AppIcons.delete,
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
    this.compact = false,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDestructive;
  final bool compact;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : isPrimary
        ? AppColors.primary
        : AppColors.textOnLightSecondary;
    final showIcon = !compact || isPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minHeight: fullWidth ? 44 : 32,
          minWidth: fullWidth ? double.infinity : 0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: fullWidth
              ? AppSpacing.md
              : compact
              ? AppSpacing.sm
              : AppSpacing.md,
          vertical: fullWidth
              ? AppSpacing.sm
              : compact
              ? AppSpacing.xs
              : AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                )
              : null,
          color: isPrimary ? null : AppColors.surfaceLightMuted,
          borderRadius: BorderRadius.circular(
            compact ? AppSpacing.radiusMedium : AppSpacing.radiusSmall,
          ),
          border: Border.all(
            color: isPrimary
                ? AppColors.primaryDark
                : color.withValues(alpha: 0.45),
            width: isPrimary ? 1.5 : 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: fullWidth || compact
              ? MainAxisSize.max
              : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showIcon) ...[
              Icon(
                icon,
                size: compact ? AppSpacing.iconSizeXS : AppSpacing.iconSizeXS,
                color: isPrimary ? AppColors.textOnPrimary : color,
              ),
              SizedBox(width: compact ? AppSpacing.xs : AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fullWidth
                      ? 14
                      : compact
                      ? 10.5
                      : 12,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? AppColors.textOnPrimary : color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
