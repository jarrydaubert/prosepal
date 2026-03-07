import 'package:flutter/material.dart';

import '../../../core/models/message_length.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/keyboard_utils.dart';

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
  late final FocusNode _nameFocusNode;
  late final FocusNode _detailsFocusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipientName);
    _detailsController = TextEditingController(text: widget.personalDetails);
    _nameFocusNode = FocusNode();
    _detailsFocusNode = FocusNode();
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
    _nameFocusNode.dispose();
    _detailsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => dismissKeyboard(context),
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
          const Text(
            'Optional details to make your message more personal',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
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
            focusNode: _nameFocusNode,
            hintText: 'e.g., Sarah, Mom, John',
            icon: Icons.person_outline,
            keyboardType: TextInputType.text,
            maxLength: 50,
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
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
            focusNode: _detailsFocusNode,
            hintText:
                'Add as much detail as possible for a more personalized message...',
            icon: Icons.notes_outlined,
            keyboardType: TextInputType.text,
            maxLines: 4,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
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
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _StyledTextField extends StatefulWidget {
  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.keyboardType,
    required this.onChanged,
    this.focusNode,
    this.maxLines = 1,
    this.maxLength,
    this.autofillHints,
    this.textCapitalization,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final void Function(String) onChanged;
  final FocusNode? focusNode;
  final int maxLines;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final TextCapitalization? textCapitalization;

  @override
  State<_StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<_StyledTextField> {
  bool _isFocused = false;
  late final FocusNode _effectiveFocusNode;
  late final bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    _effectiveFocusNode.addListener(_onFocusChanged);
    _isFocused = _effectiveFocusNode.hasFocus;
  }

  void _onFocusChanged() {
    final focused = _effectiveFocusNode.hasFocus;
    if (focused != _isFocused && mounted) {
      setState(() => _isFocused = focused);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) {
      _effectiveFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMultiLine = widget.maxLines > 1;
    final effectiveKeyboardType = isMultiLine
        ? TextInputType.multiline
        : widget.keyboardType;
    final minHeight = isMultiLine ? 132.0 : 52.0;
    final fieldTopInset = isMultiLine ? 14.0 : 10.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      clipBehavior: Clip.antiAlias,
      constraints: BoxConstraints(
        minHeight: minHeight,
        maxHeight: isMultiLine ? double.infinity : minHeight,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused ? AppColors.primary : AppColors.borderOnLight,
          width: 2,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _effectiveFocusNode,
        keyboardType: effectiveKeyboardType,
        autofillHints: widget.autofillHints,
        minLines: isMultiLine ? widget.maxLines : 1,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        style: TextStyle(
          fontSize: isMultiLine ? 15 : 16,
          fontWeight: FontWeight.w500,
          height: isMultiLine ? 1.4 : null,
          color: AppColors.textOnLight,
        ),
        cursorColor: AppColors.primary,
        textAlignVertical: isMultiLine
            ? TextAlignVertical.top
            : TextAlignVertical.center,
        textCapitalization:
            widget.textCapitalization ??
            (isMultiLine
                ? TextCapitalization.sentences
                : TextCapitalization.words),
        textInputAction: TextInputAction.done,
        scrollPadding: const EdgeInsets.only(bottom: 140),
        onChanged: widget.onChanged,
        onSubmitted: (_) => dismissKeyboard(context),
        onEditingComplete: () => dismissKeyboard(context),
        onTapOutside: (_) => dismissKeyboard(context),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: AppColors.textOnLightHint,
            fontSize: isMultiLine ? 14 : 16,
            height: isMultiLine ? 1.4 : null,
          ),
          counterText: isMultiLine ? null : '',
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          alignLabelWithHint: isMultiLine,
          prefixIcon: isMultiLine
              ? null
              : Icon(widget.icon, color: AppColors.primary, size: 20),
          prefixIconConstraints: isMultiLine
              ? null
              : const BoxConstraints(minWidth: 44, minHeight: 44),
          contentPadding: isMultiLine
              ? EdgeInsets.fromLTRB(14, fieldTopInset, 14, fieldTopInset)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          counterStyle: const TextStyle(
            color: AppColors.textOnLightHint,
            fontSize: 12,
          ),
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
  Widget build(BuildContext context) => Semantics(
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
              onChanged(length);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLight
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderOnLight,
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
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  Text(
                    length.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textOnLight,
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
