import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';

class DetailsInput extends StatefulWidget {
  const DetailsInput({
    super.key,
    required this.recipientName,
    required this.personalDetails,
    required this.onRecipientNameChanged,
    required this.onPersonalDetailsChanged,
  });

  final String recipientName;
  final String personalDetails;
  final void Function(String) onRecipientNameChanged;
  final void Function(String) onPersonalDetailsChanged;

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
    }
    if (oldWidget.personalDetails != widget.personalDetails &&
        _detailsController.text != widget.personalDetails) {
      _detailsController.text = widget.personalDetails;
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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
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
                padding: EdgeInsets.only(bottom: 48), // Align to top for multiline
                child: Icon(Icons.notes_outlined),
              ),
              alignLabelWithHint: true,
              labelText: 'Personal details', // For accessibility
            ),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: widget.onPersonalDetailsChanged,
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
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.info),
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
