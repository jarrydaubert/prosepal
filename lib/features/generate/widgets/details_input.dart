import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/message_length.dart';
import '../../../shared/theme/app_colors.dart';

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
    if (oldWidget.recipientName != widget.recipientName &&
        _nameController.text != widget.recipientName) {
      _nameController.text = widget.recipientName;
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add personal touches',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Optional details to make your message more personal',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Recipient name
            const Text(
              "Recipient's name",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _StyledTextField(
              controller: _nameController,
              hintText: 'e.g., Sarah, Mom, John',
              icon: Icons.person_outline,
              onChanged: widget.onRecipientNameChanged,
            ),
            const SizedBox(height: 24),

            // Personal details
            const Text(
              'Personal details or context',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _StyledTextField(
              controller: _detailsController,
              hintText: 'e.g., She loves gardening, Just got promoted',
              icon: Icons.notes_outlined,
              maxLines: 4,
              maxLength: 300,
              onChanged: widget.onPersonalDetailsChanged,
            ),
            const SizedBox(height: 24),

            // Message length
            const Text(
              'Message length',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _LengthSelector(
              selectedLength: widget.selectedLength,
              onChanged: widget.onLengthChanged,
            ),
            const SizedBox(height: 8),
            Text(
              widget.selectedLength.description,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Tip card
            _TipCard(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.onChanged,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final void Function(String) onChanged;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        textCapitalization: maxLines > 1
            ? TextCapitalization.sentences
            : TextCapitalization.words,
        textInputAction:
            maxLines > 1 ? TextInputAction.done : TextInputAction.next,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: maxLines > 1 ? 60 : 0),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          counterStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ),
    );
  }
}

class _LengthSelector extends StatelessWidget {
  const _LengthSelector({
    required this.selectedLength,
    required this.onChanged,
  });

  final MessageLength selectedLength;
  final void Function(MessageLength) onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Message length selector',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: MessageLength.values.map((length) {
          final isSelected = selectedLength == length;
          return Semantics(
            label: '${length.label}: ${length.description}',
            selected: isSelected,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onChanged(length);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                    width: isSelected ? 2 : 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    Text(length.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      length.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.info,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'The more details you provide, the more personalized your message will be!',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
