// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'generated_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GeneratedMessage {

 String get id; String get text;@OccasionConverter() Occasion get occasion;@RelationshipConverter() Relationship get relationship;@ToneConverter() Tone get tone; DateTime get createdAt; String? get recipientName; String? get personalDetails;
/// Create a copy of GeneratedMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeneratedMessageCopyWith<GeneratedMessage> get copyWith => _$GeneratedMessageCopyWithImpl<GeneratedMessage>(this as GeneratedMessage, _$identity);

  /// Serializes this GeneratedMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeneratedMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.occasion, occasion) || other.occasion == occasion)&&(identical(other.relationship, relationship) || other.relationship == relationship)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.personalDetails, personalDetails) || other.personalDetails == personalDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,occasion,relationship,tone,createdAt,recipientName,personalDetails);

@override
String toString() {
  return 'GeneratedMessage(id: $id, text: $text, occasion: $occasion, relationship: $relationship, tone: $tone, createdAt: $createdAt, recipientName: $recipientName, personalDetails: $personalDetails)';
}


}

/// @nodoc
abstract mixin class $GeneratedMessageCopyWith<$Res>  {
  factory $GeneratedMessageCopyWith(GeneratedMessage value, $Res Function(GeneratedMessage) _then) = _$GeneratedMessageCopyWithImpl;
@useResult
$Res call({
 String id, String text,@OccasionConverter() Occasion occasion,@RelationshipConverter() Relationship relationship,@ToneConverter() Tone tone, DateTime createdAt, String? recipientName, String? personalDetails
});




}
/// @nodoc
class _$GeneratedMessageCopyWithImpl<$Res>
    implements $GeneratedMessageCopyWith<$Res> {
  _$GeneratedMessageCopyWithImpl(this._self, this._then);

  final GeneratedMessage _self;
  final $Res Function(GeneratedMessage) _then;

/// Create a copy of GeneratedMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? occasion = null,Object? relationship = null,Object? tone = null,Object? createdAt = null,Object? recipientName = freezed,Object? personalDetails = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,occasion: null == occasion ? _self.occasion : occasion // ignore: cast_nullable_to_non_nullable
as Occasion,relationship: null == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as Relationship,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as Tone,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,personalDetails: freezed == personalDetails ? _self.personalDetails : personalDetails // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GeneratedMessage].
extension GeneratedMessagePatterns on GeneratedMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeneratedMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeneratedMessage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeneratedMessage value)  $default,){
final _that = this;
switch (_that) {
case _GeneratedMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeneratedMessage value)?  $default,){
final _that = this;
switch (_that) {
case _GeneratedMessage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text, @OccasionConverter()  Occasion occasion, @RelationshipConverter()  Relationship relationship, @ToneConverter()  Tone tone,  DateTime createdAt,  String? recipientName,  String? personalDetails)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeneratedMessage() when $default != null:
return $default(_that.id,_that.text,_that.occasion,_that.relationship,_that.tone,_that.createdAt,_that.recipientName,_that.personalDetails);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text, @OccasionConverter()  Occasion occasion, @RelationshipConverter()  Relationship relationship, @ToneConverter()  Tone tone,  DateTime createdAt,  String? recipientName,  String? personalDetails)  $default,) {final _that = this;
switch (_that) {
case _GeneratedMessage():
return $default(_that.id,_that.text,_that.occasion,_that.relationship,_that.tone,_that.createdAt,_that.recipientName,_that.personalDetails);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text, @OccasionConverter()  Occasion occasion, @RelationshipConverter()  Relationship relationship, @ToneConverter()  Tone tone,  DateTime createdAt,  String? recipientName,  String? personalDetails)?  $default,) {final _that = this;
switch (_that) {
case _GeneratedMessage() when $default != null:
return $default(_that.id,_that.text,_that.occasion,_that.relationship,_that.tone,_that.createdAt,_that.recipientName,_that.personalDetails);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GeneratedMessage extends GeneratedMessage {
  const _GeneratedMessage({required this.id, required this.text, @OccasionConverter() required this.occasion, @RelationshipConverter() required this.relationship, @ToneConverter() required this.tone, required this.createdAt, this.recipientName, this.personalDetails}): super._();
  factory _GeneratedMessage.fromJson(Map<String, dynamic> json) => _$GeneratedMessageFromJson(json);

@override final  String id;
@override final  String text;
@override@OccasionConverter() final  Occasion occasion;
@override@RelationshipConverter() final  Relationship relationship;
@override@ToneConverter() final  Tone tone;
@override final  DateTime createdAt;
@override final  String? recipientName;
@override final  String? personalDetails;

/// Create a copy of GeneratedMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeneratedMessageCopyWith<_GeneratedMessage> get copyWith => __$GeneratedMessageCopyWithImpl<_GeneratedMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GeneratedMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeneratedMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.occasion, occasion) || other.occasion == occasion)&&(identical(other.relationship, relationship) || other.relationship == relationship)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.personalDetails, personalDetails) || other.personalDetails == personalDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,occasion,relationship,tone,createdAt,recipientName,personalDetails);

@override
String toString() {
  return 'GeneratedMessage(id: $id, text: $text, occasion: $occasion, relationship: $relationship, tone: $tone, createdAt: $createdAt, recipientName: $recipientName, personalDetails: $personalDetails)';
}


}

/// @nodoc
abstract mixin class _$GeneratedMessageCopyWith<$Res> implements $GeneratedMessageCopyWith<$Res> {
  factory _$GeneratedMessageCopyWith(_GeneratedMessage value, $Res Function(_GeneratedMessage) _then) = __$GeneratedMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String text,@OccasionConverter() Occasion occasion,@RelationshipConverter() Relationship relationship,@ToneConverter() Tone tone, DateTime createdAt, String? recipientName, String? personalDetails
});




}
/// @nodoc
class __$GeneratedMessageCopyWithImpl<$Res>
    implements _$GeneratedMessageCopyWith<$Res> {
  __$GeneratedMessageCopyWithImpl(this._self, this._then);

  final _GeneratedMessage _self;
  final $Res Function(_GeneratedMessage) _then;

/// Create a copy of GeneratedMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? occasion = null,Object? relationship = null,Object? tone = null,Object? createdAt = null,Object? recipientName = freezed,Object? personalDetails = freezed,}) {
  return _then(_GeneratedMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,occasion: null == occasion ? _self.occasion : occasion // ignore: cast_nullable_to_non_nullable
as Occasion,relationship: null == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as Relationship,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as Tone,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,personalDetails: freezed == personalDetails ? _self.personalDetails : personalDetails // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GenerationResult {

 List<GeneratedMessage> get messages;@OccasionConverter() Occasion get occasion;@RelationshipConverter() Relationship get relationship;@ToneConverter() Tone get tone; String? get recipientName; String? get personalDetails;
/// Create a copy of GenerationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenerationResultCopyWith<GenerationResult> get copyWith => _$GenerationResultCopyWithImpl<GenerationResult>(this as GenerationResult, _$identity);

  /// Serializes this GenerationResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenerationResult&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.occasion, occasion) || other.occasion == occasion)&&(identical(other.relationship, relationship) || other.relationship == relationship)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.personalDetails, personalDetails) || other.personalDetails == personalDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(messages),occasion,relationship,tone,recipientName,personalDetails);

@override
String toString() {
  return 'GenerationResult(messages: $messages, occasion: $occasion, relationship: $relationship, tone: $tone, recipientName: $recipientName, personalDetails: $personalDetails)';
}


}

/// @nodoc
abstract mixin class $GenerationResultCopyWith<$Res>  {
  factory $GenerationResultCopyWith(GenerationResult value, $Res Function(GenerationResult) _then) = _$GenerationResultCopyWithImpl;
@useResult
$Res call({
 List<GeneratedMessage> messages,@OccasionConverter() Occasion occasion,@RelationshipConverter() Relationship relationship,@ToneConverter() Tone tone, String? recipientName, String? personalDetails
});




}
/// @nodoc
class _$GenerationResultCopyWithImpl<$Res>
    implements $GenerationResultCopyWith<$Res> {
  _$GenerationResultCopyWithImpl(this._self, this._then);

  final GenerationResult _self;
  final $Res Function(GenerationResult) _then;

/// Create a copy of GenerationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? occasion = null,Object? relationship = null,Object? tone = null,Object? recipientName = freezed,Object? personalDetails = freezed,}) {
  return _then(_self.copyWith(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<GeneratedMessage>,occasion: null == occasion ? _self.occasion : occasion // ignore: cast_nullable_to_non_nullable
as Occasion,relationship: null == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as Relationship,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as Tone,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,personalDetails: freezed == personalDetails ? _self.personalDetails : personalDetails // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GenerationResult].
extension GenerationResultPatterns on GenerationResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GenerationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GenerationResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GenerationResult value)  $default,){
final _that = this;
switch (_that) {
case _GenerationResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GenerationResult value)?  $default,){
final _that = this;
switch (_that) {
case _GenerationResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<GeneratedMessage> messages, @OccasionConverter()  Occasion occasion, @RelationshipConverter()  Relationship relationship, @ToneConverter()  Tone tone,  String? recipientName,  String? personalDetails)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GenerationResult() when $default != null:
return $default(_that.messages,_that.occasion,_that.relationship,_that.tone,_that.recipientName,_that.personalDetails);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<GeneratedMessage> messages, @OccasionConverter()  Occasion occasion, @RelationshipConverter()  Relationship relationship, @ToneConverter()  Tone tone,  String? recipientName,  String? personalDetails)  $default,) {final _that = this;
switch (_that) {
case _GenerationResult():
return $default(_that.messages,_that.occasion,_that.relationship,_that.tone,_that.recipientName,_that.personalDetails);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<GeneratedMessage> messages, @OccasionConverter()  Occasion occasion, @RelationshipConverter()  Relationship relationship, @ToneConverter()  Tone tone,  String? recipientName,  String? personalDetails)?  $default,) {final _that = this;
switch (_that) {
case _GenerationResult() when $default != null:
return $default(_that.messages,_that.occasion,_that.relationship,_that.tone,_that.recipientName,_that.personalDetails);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _GenerationResult extends GenerationResult {
  const _GenerationResult({required final  List<GeneratedMessage> messages, @OccasionConverter() required this.occasion, @RelationshipConverter() required this.relationship, @ToneConverter() required this.tone, this.recipientName, this.personalDetails}): _messages = messages,super._();
  factory _GenerationResult.fromJson(Map<String, dynamic> json) => _$GenerationResultFromJson(json);

 final  List<GeneratedMessage> _messages;
@override List<GeneratedMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

@override@OccasionConverter() final  Occasion occasion;
@override@RelationshipConverter() final  Relationship relationship;
@override@ToneConverter() final  Tone tone;
@override final  String? recipientName;
@override final  String? personalDetails;

/// Create a copy of GenerationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GenerationResultCopyWith<_GenerationResult> get copyWith => __$GenerationResultCopyWithImpl<_GenerationResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GenerationResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GenerationResult&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.occasion, occasion) || other.occasion == occasion)&&(identical(other.relationship, relationship) || other.relationship == relationship)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.personalDetails, personalDetails) || other.personalDetails == personalDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),occasion,relationship,tone,recipientName,personalDetails);

@override
String toString() {
  return 'GenerationResult(messages: $messages, occasion: $occasion, relationship: $relationship, tone: $tone, recipientName: $recipientName, personalDetails: $personalDetails)';
}


}

/// @nodoc
abstract mixin class _$GenerationResultCopyWith<$Res> implements $GenerationResultCopyWith<$Res> {
  factory _$GenerationResultCopyWith(_GenerationResult value, $Res Function(_GenerationResult) _then) = __$GenerationResultCopyWithImpl;
@override @useResult
$Res call({
 List<GeneratedMessage> messages,@OccasionConverter() Occasion occasion,@RelationshipConverter() Relationship relationship,@ToneConverter() Tone tone, String? recipientName, String? personalDetails
});




}
/// @nodoc
class __$GenerationResultCopyWithImpl<$Res>
    implements _$GenerationResultCopyWith<$Res> {
  __$GenerationResultCopyWithImpl(this._self, this._then);

  final _GenerationResult _self;
  final $Res Function(_GenerationResult) _then;

/// Create a copy of GenerationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? occasion = null,Object? relationship = null,Object? tone = null,Object? recipientName = freezed,Object? personalDetails = freezed,}) {
  return _then(_GenerationResult(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<GeneratedMessage>,occasion: null == occasion ? _self.occasion : occasion // ignore: cast_nullable_to_non_nullable
as Occasion,relationship: null == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as Relationship,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as Tone,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,personalDetails: freezed == personalDetails ? _self.personalDetails : personalDetails // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
