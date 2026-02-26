import 'occasion.dart';
import 'relationship.dart';
import 'tone.dart';

/// Represents a single AI-generated message
class GeneratedMessage {

  /// Create from JSON
  factory GeneratedMessage.fromJson(Map<String, dynamic> json) {
    return GeneratedMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      occasion: Occasion.values.byName(json['occasion'] as String),
      relationship: Relationship.values.byName(json['relationship'] as String),
      tone: Tone.values.byName(json['tone'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      recipientName: json['recipientName'] as String?,
      personalDetails: json['personalDetails'] as String?,
    );
  }
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

  /// Create a copy with optional field overrides
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

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'occasion': occasion.name,
      'relationship': relationship.name,
      'tone': tone.name,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'recipientName': recipientName,
      'personalDetails': personalDetails,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeneratedMessage &&
        other.id == id &&
        other.text == text &&
        other.occasion == occasion &&
        other.relationship == relationship &&
        other.tone == tone &&
        other.createdAt == createdAt &&
        other.recipientName == recipientName &&
        other.personalDetails == personalDetails;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      text,
      occasion,
      relationship,
      tone,
      createdAt,
      recipientName,
      personalDetails,
    );
  }

  @override
  String toString() {
    return 'GeneratedMessage(id: $id, occasion: ${occasion.name}, '
        'relationship: ${relationship.name}, tone: ${tone.name})';
  }
}

/// Container for a generation session's outputs
class GenerationResult {

  /// Create from JSON
  factory GenerationResult.fromJson(Map<String, dynamic> json) {
    return GenerationResult(
      messages: (json['messages'] as List)
          .map((m) => GeneratedMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      occasion: Occasion.values.byName(json['occasion'] as String),
      relationship: Relationship.values.byName(json['relationship'] as String),
      tone: Tone.values.byName(json['tone'] as String),
      recipientName: json['recipientName'] as String?,
      personalDetails: json['personalDetails'] as String?,
    );
  }
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

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'messages': messages.map((m) => m.toJson()).toList(),
      'occasion': occasion.name,
      'relationship': relationship.name,
      'tone': tone.name,
      'recipientName': recipientName,
      'personalDetails': personalDetails,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GenerationResult) return false;
    if (messages.length != other.messages.length) return false;
    for (var i = 0; i < messages.length; i++) {
      if (messages[i] != other.messages[i]) return false;
    }
    return other.occasion == occasion &&
        other.relationship == relationship &&
        other.tone == tone &&
        other.recipientName == recipientName &&
        other.personalDetails == personalDetails;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(messages),
      occasion,
      relationship,
      tone,
      recipientName,
      personalDetails,
    );
  }

  @override
  String toString() {
    return 'GenerationResult(${messages.length} messages, '
        'occasion: ${occasion.name}, relationship: ${relationship.name}, '
        'tone: ${tone.name})';
  }
}
