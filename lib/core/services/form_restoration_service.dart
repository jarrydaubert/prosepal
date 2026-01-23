import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'log_service.dart';

/// Service for persisting and restoring form state across app restarts.
///
/// Handles the case where the OS kills the app in the background and the user
/// returns expecting their form data to still be there.
///
/// ## Usage
/// ```dart
/// // Save state when form changes
/// formRestorationService.saveGenerateFormState(
///   occasion: selectedOccasion,
///   relationship: selectedRelationship,
///   // ...
/// );
///
/// // Restore state on screen init
/// final state = await formRestorationService.restoreGenerateFormState();
/// if (state != null) {
///   // Apply restored state to providers
/// }
///
/// // Clear state when form is submitted or cancelled
/// formRestorationService.clearGenerateFormState();
/// ```
class FormRestorationService {
  FormRestorationService(this._prefs);

  final SharedPreferences _prefs;

  // Keys for generate form state
  static const _keyGenerateForm = 'form_restoration_generate';

  /// Save the current state of the generate form.
  ///
  /// Call this when any form field changes. Debouncing is recommended
  /// for frequently-changing fields like text inputs.
  Future<void> saveGenerateFormState({
    required Occasion? occasion,
    required Relationship? relationship,
    required Tone? tone,
    required MessageLength messageLength,
    required String recipientName,
    required String personalDetails,
    required int currentStep,
  }) async {
    if (occasion == null) {
      // No point saving if no occasion selected
      return;
    }

    final state = {
      'occasionIndex': Occasion.values.indexOf(occasion),
      'relationshipIndex': relationship != null
          ? Relationship.values.indexOf(relationship)
          : -1,
      'toneIndex': tone != null ? Tone.values.indexOf(tone) : -1,
      'messageLengthIndex': MessageLength.values.indexOf(messageLength),
      'recipientName': recipientName,
      'personalDetails': personalDetails,
      'currentStep': currentStep,
      'savedAt': DateTime.now().toIso8601String(),
    };

    await _prefs.setString(_keyGenerateForm, jsonEncode(state));
    Log.info('Generate form state saved', {'step': currentStep});
  }

  /// Restore the generate form state if available.
  ///
  /// Returns null if:
  /// - No saved state exists
  /// - Saved state is older than [maxAge]
  /// - Saved state is corrupted
  Future<GenerateFormState?> restoreGenerateFormState({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final json = _prefs.getString(_keyGenerateForm);
    if (json == null) return null;

    try {
      final state = jsonDecode(json) as Map<String, dynamic>;

      // Check age
      final savedAt = DateTime.tryParse(state['savedAt'] as String? ?? '');
      if (savedAt == null || DateTime.now().difference(savedAt) > maxAge) {
        Log.info('Generate form state expired, clearing');
        await clearGenerateFormState();
        return null;
      }

      // Restore enums from indices
      final occasionIndex = state['occasionIndex'] as int? ?? -1;
      final relationshipIndex = state['relationshipIndex'] as int? ?? -1;
      final toneIndex = state['toneIndex'] as int? ?? -1;
      final messageLengthIndex = state['messageLengthIndex'] as int? ?? 1;

      final occasion =
          occasionIndex >= 0 && occasionIndex < Occasion.values.length
          ? Occasion.values[occasionIndex]
          : null;

      if (occasion == null) {
        // No valid occasion - can't restore
        await clearGenerateFormState();
        return null;
      }

      final relationship =
          relationshipIndex >= 0 &&
              relationshipIndex < Relationship.values.length
          ? Relationship.values[relationshipIndex]
          : null;

      final tone = toneIndex >= 0 && toneIndex < Tone.values.length
          ? Tone.values[toneIndex]
          : null;

      final messageLength =
          messageLengthIndex >= 0 &&
              messageLengthIndex < MessageLength.values.length
          ? MessageLength.values[messageLengthIndex]
          : MessageLength.standard;

      Log.info('Generate form state restored', {
        'occasion': occasion.label,
        'step': state['currentStep'],
      });

      return GenerateFormState(
        occasion: occasion,
        relationship: relationship,
        tone: tone,
        messageLength: messageLength,
        recipientName: state['recipientName'] as String? ?? '',
        personalDetails: state['personalDetails'] as String? ?? '',
        currentStep: state['currentStep'] as int? ?? 0,
      );
    } on Exception catch (e) {
      Log.warning('Failed to restore generate form state', {'error': '$e'});
      await clearGenerateFormState();
      return null;
    }
  }

  /// Clear the saved generate form state.
  ///
  /// Call this when:
  /// - Form is successfully submitted
  /// - User explicitly cancels/navigates away
  /// - User goes back to home screen
  Future<void> clearGenerateFormState() async {
    await _prefs.remove(_keyGenerateForm);
    Log.info('Generate form state cleared');
  }

  /// Check if there's a saved generate form state.
  bool hasGenerateFormState() => _prefs.containsKey(_keyGenerateForm);
}

/// Restored state from the generate form.
class GenerateFormState {
  const GenerateFormState({
    required this.occasion,
    required this.relationship,
    required this.tone,
    required this.messageLength,
    required this.recipientName,
    required this.personalDetails,
    required this.currentStep,
  });

  final Occasion occasion;
  final Relationship? relationship;
  final Tone? tone;
  final MessageLength messageLength;
  final String recipientName;
  final String personalDetails;
  final int currentStep;
}
