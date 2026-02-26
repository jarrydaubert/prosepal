// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GeneratedMessage _$GeneratedMessageFromJson(Map<String, dynamic> json) =>
    _GeneratedMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      occasion: const OccasionConverter().fromJson(json['occasion'] as String),
      relationship: const RelationshipConverter().fromJson(
        json['relationship'] as String,
      ),
      tone: const ToneConverter().fromJson(json['tone'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      recipientName: json['recipientName'] as String?,
      personalDetails: json['personalDetails'] as String?,
    );

Map<String, dynamic> _$GeneratedMessageToJson(
  _GeneratedMessage instance,
) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'occasion': const OccasionConverter().toJson(instance.occasion),
  'relationship': const RelationshipConverter().toJson(instance.relationship),
  'tone': const ToneConverter().toJson(instance.tone),
  'createdAt': instance.createdAt.toIso8601String(),
  'recipientName': instance.recipientName,
  'personalDetails': instance.personalDetails,
};

_GenerationResult _$GenerationResultFromJson(Map<String, dynamic> json) =>
    _GenerationResult(
      messages: (json['messages'] as List<dynamic>)
          .map((e) => GeneratedMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      occasion: const OccasionConverter().fromJson(json['occasion'] as String),
      relationship: const RelationshipConverter().fromJson(
        json['relationship'] as String,
      ),
      tone: const ToneConverter().fromJson(json['tone'] as String),
      recipientName: json['recipientName'] as String?,
      personalDetails: json['personalDetails'] as String?,
    );

Map<String, dynamic> _$GenerationResultToJson(
  _GenerationResult instance,
) => <String, dynamic>{
  'messages': instance.messages.map((e) => e.toJson()).toList(),
  'occasion': const OccasionConverter().toJson(instance.occasion),
  'relationship': const RelationshipConverter().toJson(instance.relationship),
  'tone': const ToneConverter().toJson(instance.tone),
  'recipientName': instance.recipientName,
  'personalDetails': instance.personalDetails,
};
