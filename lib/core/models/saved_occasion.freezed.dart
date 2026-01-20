// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_occasion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavedOccasion {

 String get id; Occasion get occasion; DateTime get date; String? get recipientName; Relationship? get relationship; String? get notes; bool get reminderEnabled; int get reminderDaysBefore; DateTime get createdAt; DateTime? get lastGeneratedAt;
/// Create a copy of SavedOccasion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedOccasionCopyWith<SavedOccasion> get copyWith => _$SavedOccasionCopyWithImpl<SavedOccasion>(this as SavedOccasion, _$identity);

  /// Serializes this SavedOccasion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedOccasion&&(identical(other.id, id) || other.id == id)&&(identical(other.occasion, occasion) || other.occasion == occasion)&&(identical(other.date, date) || other.date == date)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.relationship, relationship) || other.relationship == relationship)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.reminderEnabled, reminderEnabled) || other.reminderEnabled == reminderEnabled)&&(identical(other.reminderDaysBefore, reminderDaysBefore) || other.reminderDaysBefore == reminderDaysBefore)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastGeneratedAt, lastGeneratedAt) || other.lastGeneratedAt == lastGeneratedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,occasion,date,recipientName,relationship,notes,reminderEnabled,reminderDaysBefore,createdAt,lastGeneratedAt);

@override
String toString() {
  return 'SavedOccasion(id: $id, occasion: $occasion, date: $date, recipientName: $recipientName, relationship: $relationship, notes: $notes, reminderEnabled: $reminderEnabled, reminderDaysBefore: $reminderDaysBefore, createdAt: $createdAt, lastGeneratedAt: $lastGeneratedAt)';
}


}

/// @nodoc
abstract mixin class $SavedOccasionCopyWith<$Res>  {
  factory $SavedOccasionCopyWith(SavedOccasion value, $Res Function(SavedOccasion) _then) = _$SavedOccasionCopyWithImpl;
@useResult
$Res call({
 String id, Occasion occasion, DateTime date, String? recipientName, Relationship? relationship, String? notes, bool reminderEnabled, int reminderDaysBefore, DateTime createdAt, DateTime? lastGeneratedAt
});




}
/// @nodoc
class _$SavedOccasionCopyWithImpl<$Res>
    implements $SavedOccasionCopyWith<$Res> {
  _$SavedOccasionCopyWithImpl(this._self, this._then);

  final SavedOccasion _self;
  final $Res Function(SavedOccasion) _then;

/// Create a copy of SavedOccasion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? occasion = null,Object? date = null,Object? recipientName = freezed,Object? relationship = freezed,Object? notes = freezed,Object? reminderEnabled = null,Object? reminderDaysBefore = null,Object? createdAt = null,Object? lastGeneratedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,occasion: null == occasion ? _self.occasion : occasion // ignore: cast_nullable_to_non_nullable
as Occasion,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,relationship: freezed == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as Relationship?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,reminderEnabled: null == reminderEnabled ? _self.reminderEnabled : reminderEnabled // ignore: cast_nullable_to_non_nullable
as bool,reminderDaysBefore: null == reminderDaysBefore ? _self.reminderDaysBefore : reminderDaysBefore // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastGeneratedAt: freezed == lastGeneratedAt ? _self.lastGeneratedAt : lastGeneratedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedOccasion].
extension SavedOccasionPatterns on SavedOccasion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedOccasion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedOccasion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedOccasion value)  $default,){
final _that = this;
switch (_that) {
case _SavedOccasion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedOccasion value)?  $default,){
final _that = this;
switch (_that) {
case _SavedOccasion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Occasion occasion,  DateTime date,  String? recipientName,  Relationship? relationship,  String? notes,  bool reminderEnabled,  int reminderDaysBefore,  DateTime createdAt,  DateTime? lastGeneratedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedOccasion() when $default != null:
return $default(_that.id,_that.occasion,_that.date,_that.recipientName,_that.relationship,_that.notes,_that.reminderEnabled,_that.reminderDaysBefore,_that.createdAt,_that.lastGeneratedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Occasion occasion,  DateTime date,  String? recipientName,  Relationship? relationship,  String? notes,  bool reminderEnabled,  int reminderDaysBefore,  DateTime createdAt,  DateTime? lastGeneratedAt)  $default,) {final _that = this;
switch (_that) {
case _SavedOccasion():
return $default(_that.id,_that.occasion,_that.date,_that.recipientName,_that.relationship,_that.notes,_that.reminderEnabled,_that.reminderDaysBefore,_that.createdAt,_that.lastGeneratedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Occasion occasion,  DateTime date,  String? recipientName,  Relationship? relationship,  String? notes,  bool reminderEnabled,  int reminderDaysBefore,  DateTime createdAt,  DateTime? lastGeneratedAt)?  $default,) {final _that = this;
switch (_that) {
case _SavedOccasion() when $default != null:
return $default(_that.id,_that.occasion,_that.date,_that.recipientName,_that.relationship,_that.notes,_that.reminderEnabled,_that.reminderDaysBefore,_that.createdAt,_that.lastGeneratedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedOccasion extends SavedOccasion {
  const _SavedOccasion({required this.id, required this.occasion, required this.date, this.recipientName, this.relationship, this.notes, this.reminderEnabled = true, this.reminderDaysBefore = 7, required this.createdAt, this.lastGeneratedAt}): super._();
  factory _SavedOccasion.fromJson(Map<String, dynamic> json) => _$SavedOccasionFromJson(json);

@override final  String id;
@override final  Occasion occasion;
@override final  DateTime date;
@override final  String? recipientName;
@override final  Relationship? relationship;
@override final  String? notes;
@override@JsonKey() final  bool reminderEnabled;
@override@JsonKey() final  int reminderDaysBefore;
@override final  DateTime createdAt;
@override final  DateTime? lastGeneratedAt;

/// Create a copy of SavedOccasion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedOccasionCopyWith<_SavedOccasion> get copyWith => __$SavedOccasionCopyWithImpl<_SavedOccasion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedOccasionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedOccasion&&(identical(other.id, id) || other.id == id)&&(identical(other.occasion, occasion) || other.occasion == occasion)&&(identical(other.date, date) || other.date == date)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.relationship, relationship) || other.relationship == relationship)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.reminderEnabled, reminderEnabled) || other.reminderEnabled == reminderEnabled)&&(identical(other.reminderDaysBefore, reminderDaysBefore) || other.reminderDaysBefore == reminderDaysBefore)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastGeneratedAt, lastGeneratedAt) || other.lastGeneratedAt == lastGeneratedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,occasion,date,recipientName,relationship,notes,reminderEnabled,reminderDaysBefore,createdAt,lastGeneratedAt);

@override
String toString() {
  return 'SavedOccasion(id: $id, occasion: $occasion, date: $date, recipientName: $recipientName, relationship: $relationship, notes: $notes, reminderEnabled: $reminderEnabled, reminderDaysBefore: $reminderDaysBefore, createdAt: $createdAt, lastGeneratedAt: $lastGeneratedAt)';
}


}

/// @nodoc
abstract mixin class _$SavedOccasionCopyWith<$Res> implements $SavedOccasionCopyWith<$Res> {
  factory _$SavedOccasionCopyWith(_SavedOccasion value, $Res Function(_SavedOccasion) _then) = __$SavedOccasionCopyWithImpl;
@override @useResult
$Res call({
 String id, Occasion occasion, DateTime date, String? recipientName, Relationship? relationship, String? notes, bool reminderEnabled, int reminderDaysBefore, DateTime createdAt, DateTime? lastGeneratedAt
});




}
/// @nodoc
class __$SavedOccasionCopyWithImpl<$Res>
    implements _$SavedOccasionCopyWith<$Res> {
  __$SavedOccasionCopyWithImpl(this._self, this._then);

  final _SavedOccasion _self;
  final $Res Function(_SavedOccasion) _then;

/// Create a copy of SavedOccasion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? occasion = null,Object? date = null,Object? recipientName = freezed,Object? relationship = freezed,Object? notes = freezed,Object? reminderEnabled = null,Object? reminderDaysBefore = null,Object? createdAt = null,Object? lastGeneratedAt = freezed,}) {
  return _then(_SavedOccasion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,occasion: null == occasion ? _self.occasion : occasion // ignore: cast_nullable_to_non_nullable
as Occasion,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,relationship: freezed == relationship ? _self.relationship : relationship // ignore: cast_nullable_to_non_nullable
as Relationship?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,reminderEnabled: null == reminderEnabled ? _self.reminderEnabled : reminderEnabled // ignore: cast_nullable_to_non_nullable
as bool,reminderDaysBefore: null == reminderDaysBefore ? _self.reminderDaysBefore : reminderDaysBefore // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastGeneratedAt: freezed == lastGeneratedAt ? _self.lastGeneratedAt : lastGeneratedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
