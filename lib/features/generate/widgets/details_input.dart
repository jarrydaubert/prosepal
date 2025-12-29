import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/models/message_length.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';

class DetailsInput extends StatefulWidget {
  const DetailsInput({
    super.key,
    required this.recipientName,
    required this.personalDetails,
    required this.selectedLength,
    required this.onRecipientNameChanged,
    required this.onPersonalDetailsChanged,
    required this.onLengthChanged,
  });

  final String recipientName;
  final String personalDetails;
  final MessageLength selectedLength;
  final void Function(String) onRecipientNameChanged;
  final void Function(String) onPersonalDetailsChanged;
  final void Function(MessageLength) onLengthChanged;

  @override
  State<DetailsInput> createState() => _DetailsInputState();
}

class _DetailsInputState extends State<DetailsInput> {
  late final TextEditingController _nameController;
  late final TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipientName);
    _detailsController = TextEditingController(text: widget.personalDetails);
  }

  @override
  void didUpdateWidget(DetailsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if external state changes (e.g., form reset)
    if (oldWidget.recipientName != widget.recipientName &&
        _nameController.text != widget.recipientName) {
      _nameController.text = widget.recipientName;
      // Place cursor at end after external update
      _nameController.selection = TextSelection.collapsed(
        offset: _nameController.text.length,
      );
    }
    if (oldWidget.personalDetails != widget.personalDetails &&
        _detailsController.text != widget.personalDetails) {
      _detailsController.text = widget.personalDetails;
      _detailsController.selection = TextSelection.collapsed(
        offset: _detailsController.text.length,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add personal touches',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Gap(AppSpacing.sm),
          Text(
            'Optional details to make your message more personal',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          Gap(AppSpacing.xl),

          // Recipient name
          Text(
            "Recipient's name",
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Gap(AppSpacing.sm),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'e.g., Sarah, Mom, John',
              prefixIcon: Icon(Icons.person_outline),
              labelText: "Recipient's name", // For accessibility
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: widget.onRecipientNameChanged,
          ),
          Gap(AppSpacing.xl),

          // Personal details
          Text(
            'Personal details or context',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Gap(AppSpacing.sm),
          TextField(
            controller: _detailsController,
            decoration: InputDecoration(
              hintText:
                  'e.g., She loves gardening, Just got promoted, We met in college',
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  bottom: 48,
                ), // Align to top for multiline
                child: Icon(Icons.notes_outlined),
              ),
              alignLabelWithHint: true,
              labelText: 'Personal details', // For accessibility
            ),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: widget.onPersonalDetailsChanged,
          ),
          Gap(AppSpacing.xl),

          // Message length
          Text('Message length', style: Theme.of(context).textTheme.titleSmall),
          Gap(AppSpacing.sm),
          Semantics(
            label: 'Message length selector',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: MessageLength.values.map((length) {
                final isSelected = widget.selectedLength == length;
                return Semantics(
                  label: '${length.label}: ${length.description}',
                  selected: isSelected,
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Padding(
                            padding: EdgeInsets.only(right: AppSpacing.xs),
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        Text(length.emoji),
                        Gap(AppSpacing.xs),
                        Text(
                          length.label,
                          style: isSelected
                              ? TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => widget.onLengthChanged(length),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      width: isSelected ? 1.5 : 1,
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          Gap(AppSpacing.sm),
          Text(
            widget.selectedLength.description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          Gap(AppSpacing.lg),

          // Tip card
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
                Gap(AppSpacing.sm),
                Expanded(
                  child: Text(
                    'The more details you provide, the more personalized your message will be!',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
