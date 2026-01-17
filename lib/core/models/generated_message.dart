// ignore_for_file: invalid_annotation_target
// Note: invalid_annotation_target is required because freezed annotations
// are applied to abstract classes, which triggers false positives in some
// analyzer versions. This is a known freezed pattern.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'message_length.dart';
import 'occasion.dart';
import 'relationship.dart';
import 'tone.dart';

part 'generated_message.freezed.dart';
part 'generated_message.g.dart';

// =============================================================================
// Enum Parsing Utilities
// =============================================================================

/// Exception thrown when an invalid enum value is encountered during JSON parsing
///
/// Provides context about the enum type and expected values for debugging.
class InvalidEnumValueException extends FormatException {
  InvalidEnumValueException({
    required this.enumType,
    required this.invalidValue,
    required this.validValues,
  }) : super(
         'Invalid $enumType value: "$invalidValue". '
         'Expected one of: ${validValues.join(", ")}',
       );

  /// The enum type that failed to parse (e.g., "Occasion")
  final String enumType;

  /// The invalid value that was received
  final String invalidValue;

  /// List of valid enum value names
  final List<String> validValues;

  @override
  String toString() => 'InvalidEnumValueException: $message';
}

/// Extension for safe enum lookup by name (returns null instead of throwing)
extension EnumByNameOrNull<T extends Enum> on Iterable<T> {
  /// Returns the enum value with the given [name], or null if not found.
  ///
  /// Unlike `byName`, this does not throw on invalid values.
  T? byNameOrNull(String? name) {
    if (name == null) return null;
    for (final value in this) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// Helper to parse an enum value with detailed error messages
///
/// Throws [InvalidEnumValueException] if the value is not found.
T parseEnum<T extends Enum>(List<T> values, String json, String enumTypeName) {
  final result = values.byNameOrNull(json);
  if (result == null) {
    throw InvalidEnumValueException(
      enumType: enumTypeName,
      invalidValue: json,
      validValues: values.map((e) => e.name).toList(),
    );
  }
  return result;
}

// =============================================================================
// Data Models
// =============================================================================

/// Represents a single AI-generated greeting card message
///
/// Immutable data class containing the message text along with the context
/// used to generate it (occasion, relationship, tone).
///
/// ## Example
/// ```dart
/// final message = GeneratedMessage(
///   id: 'msg-123',
///   text: 'Happy Birthday! Wishing you a wonderful day.',
///   occasion: Occasion.birthday,
///   relationship: Relationship.friend,
///   tone: Tone.warm,
///   createdAt: DateTime.now(),
/// );
/// ```
@freezed
abstract class GeneratedMessage with _$GeneratedMessage {
  const GeneratedMessage._();

  const factory GeneratedMessage({
    /// Unique identifier for this message
    required String id,

    /// The generated message text
    required String text,

    /// The occasion this message was generated for
    @OccasionConverter() required Occasion occasion,

    /// The relationship to the recipient
    @RelationshipConverter() required Relationship relationship,

    /// The tone/style of the message
    @ToneConverter() required Tone tone,

    /// When this message was generated
    required DateTime createdAt,

    /// Optional recipient name used in generation
    String? recipientName,

    /// Optional personal details used in generation
    String? personalDetails,
  }) = _GeneratedMessage;

  factory GeneratedMessage.fromJson(Map<String, dynamic> json) =>
      _$GeneratedMessageFromJson(json);
}

/// Container for a generation session's outputs
///
/// Groups multiple generated messages with the shared context (occasion,
/// relationship, tone) that was used to generate them.
@Freezed(toJson: true, fromJson: true)
abstract class GenerationResult with _$GenerationResult {
  const GenerationResult._();

  @JsonSerializable(explicitToJson: true)
  const factory GenerationResult({
    /// List of generated messages from this session
    required List<GeneratedMessage> messages,

    /// The occasion used for generation
    @OccasionConverter() required Occasion occasion,

    /// The relationship used for generation
    @RelationshipConverter() required Relationship relationship,

    /// The tone used for generation
    @ToneConverter() required Tone tone,

    /// The message length used for generation
    @MessageLengthConverter() required MessageLength length,

    /// Optional recipient name used in generation
    String? recipientName,

    /// Optional personal details used in generation
    String? personalDetails,
  }) = _GenerationResult;

  factory GenerationResult.fromJson(Map<String, dynamic> json) =>
      _$GenerationResultFromJson(json);
}

// =============================================================================
// JSON Converters
// =============================================================================

/// JSON converter for Occasion enum with safe parsing
///
/// Throws [InvalidEnumValueException] with context if the value is invalid.
class OccasionConverter implements JsonConverter<Occasion, String> {
  const OccasionConverter();

  @override
  Occasion fromJson(String json) =>
      parseEnum(Occasion.values, json, 'Occasion');

  @override
  String toJson(Occasion object) => object.name;
}

/// JSON converter for Relationship enum with safe parsing
///
/// Throws [InvalidEnumValueException] with context if the value is invalid.
class RelationshipConverter implements JsonConverter<Relationship, String> {
  const RelationshipConverter();

  @override
  Relationship fromJson(String json) =>
      parseEnum(Relationship.values, json, 'Relationship');

  @override
  String toJson(Relationship object) => object.name;
}

/// JSON converter for Tone enum with safe parsing
///
/// Throws [InvalidEnumValueException] with context if the value is invalid.
class ToneConverter implements JsonConverter<Tone, String> {
  const ToneConverter();

  @override
  Tone fromJson(String json) => parseEnum(Tone.values, json, 'Tone');

  @override
  String toJson(Tone object) => object.name;
}

/// JSON converter for MessageLength enum with safe parsing
///
/// Returns [MessageLength.standard] for null values (backward compatibility
/// with history entries created before length field was added).
class MessageLengthConverter implements JsonConverter<MessageLength, String?> {
  const MessageLengthConverter();

  @override
  MessageLength fromJson(String? json) {
    if (json == null) return MessageLength.standard;
    return parseEnum(MessageLength.values, json, 'MessageLength');
  }

  @override
  String toJson(MessageLength object) => object.name;
}
