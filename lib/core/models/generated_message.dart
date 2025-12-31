import 'package:freezed_annotation/freezed_annotation.dart';

import 'occasion.dart';
import 'relationship.dart';
import 'tone.dart';

part 'generated_message.freezed.dart';
part 'generated_message.g.dart';

/// Extension for safe enum lookup by name (returns null instead of throwing)
extension EnumByNameOrNull<T extends Enum> on Iterable<T> {
  T? byNameOrNull(String? name) {
    if (name == null) return null;
    for (final value in this) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// Represents a single AI-generated message
@freezed
abstract class GeneratedMessage with _$GeneratedMessage {
  const GeneratedMessage._();

  const factory GeneratedMessage({
    required String id,
    required String text,
    @OccasionConverter() required Occasion occasion,
    @RelationshipConverter() required Relationship relationship,
    @ToneConverter() required Tone tone,
    required DateTime createdAt,
    String? recipientName,
    String? personalDetails,
  }) = _GeneratedMessage;

  factory GeneratedMessage.fromJson(Map<String, dynamic> json) =>
      _$GeneratedMessageFromJson(json);
}

/// Container for a generation session's outputs
@Freezed(toJson: true, fromJson: true)
abstract class GenerationResult with _$GenerationResult {
  const GenerationResult._();

  @JsonSerializable(explicitToJson: true)
  const factory GenerationResult({
    required List<GeneratedMessage> messages,
    @OccasionConverter() required Occasion occasion,
    @RelationshipConverter() required Relationship relationship,
    @ToneConverter() required Tone tone,
    String? recipientName,
    String? personalDetails,
  }) = _GenerationResult;

  factory GenerationResult.fromJson(Map<String, dynamic> json) =>
      _$GenerationResultFromJson(json);
}

/// JSON converter for Occasion enum with safe parsing
class OccasionConverter implements JsonConverter<Occasion, String> {
  const OccasionConverter();

  @override
  Occasion fromJson(String json) {
    final result = Occasion.values.byNameOrNull(json);
    if (result == null) {
      throw FormatException('Invalid Occasion value: $json');
    }
    return result;
  }

  @override
  String toJson(Occasion object) => object.name;
}

/// JSON converter for Relationship enum with safe parsing
class RelationshipConverter implements JsonConverter<Relationship, String> {
  const RelationshipConverter();

  @override
  Relationship fromJson(String json) {
    final result = Relationship.values.byNameOrNull(json);
    if (result == null) {
      throw FormatException('Invalid Relationship value: $json');
    }
    return result;
  }

  @override
  String toJson(Relationship object) => object.name;
}

/// JSON converter for Tone enum with safe parsing
class ToneConverter implements JsonConverter<Tone, String> {
  const ToneConverter();

  @override
  Tone fromJson(String json) {
    final result = Tone.values.byNameOrNull(json);
    if (result == null) {
      throw FormatException('Invalid Tone value: $json');
    }
    return result;
  }

  @override
  String toJson(Tone object) => object.name;
}
