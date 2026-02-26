import 'occasion.dart';
import 'relationship.dart';
import 'tone.dart';

class GeneratedMessage {
  const GeneratedMessage({
    required this.id,
    required this.text,
    required this.occasion,
    required this.relationship,
    required this.tone,
    required this.createdAt,
    this.recipientName,
    this.personalDetails,
  });

  final String id;
  final String text;
  final Occasion occasion;
  final Relationship relationship;
  final Tone tone;
  final DateTime createdAt;
  final String? recipientName;
  final String? personalDetails;

  GeneratedMessage copyWith({
    String? id,
    String? text,
    Occasion? occasion,
    Relationship? relationship,
    Tone? tone,
    DateTime? createdAt,
    String? recipientName,
    String? personalDetails,
  }) {
    return GeneratedMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      occasion: occasion ?? this.occasion,
      relationship: relationship ?? this.relationship,
      tone: tone ?? this.tone,
      createdAt: createdAt ?? this.createdAt,
      recipientName: recipientName ?? this.recipientName,
      personalDetails: personalDetails ?? this.personalDetails,
    );
  }
}

class GenerationResult {
  const GenerationResult({
    required this.messages,
    required this.occasion,
    required this.relationship,
    required this.tone,
    this.recipientName,
    this.personalDetails,
  });

  final List<GeneratedMessage> messages;
  final Occasion occasion;
  final Relationship relationship;
  final Tone tone;
  final String? recipientName;
  final String? personalDetails;
}
