// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_occasion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedOccasion _$SavedOccasionFromJson(Map<String, dynamic> json) =>
    _SavedOccasion(
      id: json['id'] as String,
      occasion: $enumDecode(_$OccasionEnumMap, json['occasion']),
      date: DateTime.parse(json['date'] as String),
      recipientName: json['recipientName'] as String?,
      relationship: $enumDecodeNullable(
        _$RelationshipEnumMap,
        json['relationship'],
      ),
      notes: json['notes'] as String?,
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      reminderDaysBefore: (json['reminderDaysBefore'] as num?)?.toInt() ?? 7,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastGeneratedAt: json['lastGeneratedAt'] == null
          ? null
          : DateTime.parse(json['lastGeneratedAt'] as String),
    );

Map<String, dynamic> _$SavedOccasionToJson(_SavedOccasion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'occasion': _$OccasionEnumMap[instance.occasion]!,
      'date': instance.date.toIso8601String(),
      'recipientName': instance.recipientName,
      'relationship': _$RelationshipEnumMap[instance.relationship],
      'notes': instance.notes,
      'reminderEnabled': instance.reminderEnabled,
      'reminderDaysBefore': instance.reminderDaysBefore,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastGeneratedAt': instance.lastGeneratedAt?.toIso8601String(),
    };

const _$OccasionEnumMap = {
  Occasion.birthday: 'birthday',
  Occasion.thankYou: 'thankYou',
  Occasion.sympathy: 'sympathy',
  Occasion.wedding: 'wedding',
  Occasion.christmas: 'christmas',
  Occasion.getWell: 'getWell',
  Occasion.congrats: 'congrats',
  Occasion.mothersDay: 'mothersDay',
  Occasion.fathersDay: 'fathersDay',
  Occasion.baby: 'baby',
  Occasion.graduation: 'graduation',
  Occasion.anniversary: 'anniversary',
  Occasion.valentinesDay: 'valentinesDay',
  Occasion.thinkingOfYou: 'thinkingOfYou',
  Occasion.newYear: 'newYear',
  Occasion.engagement: 'engagement',
  Occasion.kidsBirthday: 'kidsBirthday',
  Occasion.justBecause: 'justBecause',
  Occasion.housewarming: 'housewarming',
  Occasion.retirement: 'retirement',
  Occasion.newJob: 'newJob',
  Occasion.encouragement: 'encouragement',
  Occasion.easter: 'easter',
  Occasion.thanksgiving: 'thanksgiving',
  Occasion.halloween: 'halloween',
  Occasion.apology: 'apology',
  Occasion.farewell: 'farewell',
  Occasion.goodLuck: 'goodLuck',
  Occasion.promotion: 'promotion',
  Occasion.thankYouTeacher: 'thankYouTeacher',
  Occasion.thankYouHealthcare: 'thankYouHealthcare',
  Occasion.thankYouService: 'thankYouService',
  Occasion.hanukkah: 'hanukkah',
  Occasion.diwali: 'diwali',
  Occasion.eid: 'eid',
  Occasion.lunarNewYear: 'lunarNewYear',
  Occasion.kwanzaa: 'kwanzaa',
  Occasion.petBirthday: 'petBirthday',
  Occasion.newPet: 'newPet',
  Occasion.petSympathy: 'petSympathy',
};

const _$RelationshipEnumMap = {
  Relationship.closeFriend: 'closeFriend',
  Relationship.family: 'family',
  Relationship.parent: 'parent',
  Relationship.child: 'child',
  Relationship.sibling: 'sibling',
  Relationship.grandparent: 'grandparent',
  Relationship.grandchild: 'grandchild',
  Relationship.romantic: 'romantic',
  Relationship.colleague: 'colleague',
  Relationship.boss: 'boss',
  Relationship.mentor: 'mentor',
  Relationship.teacher: 'teacher',
  Relationship.neighbor: 'neighbor',
  Relationship.acquaintance: 'acquaintance',
};
