// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_memo_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

AddMemoModel _$AddMemoModelFromJson(Map<String, dynamic> json) {
  return _AddMemoModel.fromJson(json);
}

/// @nodoc
mixin _$AddMemoModel {
  String? get title => throw _privateConstructorUsedError;
  String? get author => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  String? get madeDateTime => throw _privateConstructorUsedError;
  String? get modifiedDateTime => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AddMemoModelCopyWith<AddMemoModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddMemoModelCopyWith<$Res> {
  factory $AddMemoModelCopyWith(
          AddMemoModel value, $Res Function(AddMemoModel) then) =
      _$AddMemoModelCopyWithImpl<$Res, AddMemoModel>;
  @useResult
  $Res call(
      {String? title,
      String? author,
      String? content,
      String? madeDateTime,
      String? modifiedDateTime});
}

/// @nodoc
class _$AddMemoModelCopyWithImpl<$Res, $Val extends AddMemoModel>
    implements $AddMemoModelCopyWith<$Res> {
  _$AddMemoModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? author = freezed,
    Object? content = freezed,
    Object? madeDateTime = freezed,
    Object? modifiedDateTime = freezed,
  }) {
    return _then(_value.copyWith(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      madeDateTime: freezed == madeDateTime
          ? _value.madeDateTime
          : madeDateTime // ignore: cast_nullable_to_non_nullable
              as String?,
      modifiedDateTime: freezed == modifiedDateTime
          ? _value.modifiedDateTime
          : modifiedDateTime // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_AddMemoModelCopyWith<$Res>
    implements $AddMemoModelCopyWith<$Res> {
  factory _$$_AddMemoModelCopyWith(
          _$_AddMemoModel value, $Res Function(_$_AddMemoModel) then) =
      __$$_AddMemoModelCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? title,
      String? author,
      String? content,
      String? madeDateTime,
      String? modifiedDateTime});
}

/// @nodoc
class __$$_AddMemoModelCopyWithImpl<$Res>
    extends _$AddMemoModelCopyWithImpl<$Res, _$_AddMemoModel>
    implements _$$_AddMemoModelCopyWith<$Res> {
  __$$_AddMemoModelCopyWithImpl(
      _$_AddMemoModel _value, $Res Function(_$_AddMemoModel) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? author = freezed,
    Object? content = freezed,
    Object? madeDateTime = freezed,
    Object? modifiedDateTime = freezed,
  }) {
    return _then(_$_AddMemoModel(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      madeDateTime: freezed == madeDateTime
          ? _value.madeDateTime
          : madeDateTime // ignore: cast_nullable_to_non_nullable
              as String?,
      modifiedDateTime: freezed == modifiedDateTime
          ? _value.modifiedDateTime
          : modifiedDateTime // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_AddMemoModel implements _AddMemoModel {
  _$_AddMemoModel(
      {this.title,
      this.author,
      this.content,
      this.madeDateTime,
      this.modifiedDateTime});

  factory _$_AddMemoModel.fromJson(Map<String, dynamic> json) =>
      _$$_AddMemoModelFromJson(json);

  @override
  final String? title;
  @override
  final String? author;
  @override
  final String? content;
  @override
  final String? madeDateTime;
  @override
  final String? modifiedDateTime;

  @override
  String toString() {
    return 'AddMemoModel(title: $title, author: $author, content: $content, madeDateTime: $madeDateTime, modifiedDateTime: $modifiedDateTime)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_AddMemoModel &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.madeDateTime, madeDateTime) ||
                other.madeDateTime == madeDateTime) &&
            (identical(other.modifiedDateTime, modifiedDateTime) ||
                other.modifiedDateTime == modifiedDateTime));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, title, author, content, madeDateTime, modifiedDateTime);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_AddMemoModelCopyWith<_$_AddMemoModel> get copyWith =>
      __$$_AddMemoModelCopyWithImpl<_$_AddMemoModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_AddMemoModelToJson(
      this,
    );
  }
}

abstract class _AddMemoModel implements AddMemoModel {
  factory _AddMemoModel(
      {final String? title,
      final String? author,
      final String? content,
      final String? madeDateTime,
      final String? modifiedDateTime}) = _$_AddMemoModel;

  factory _AddMemoModel.fromJson(Map<String, dynamic> json) =
      _$_AddMemoModel.fromJson;

  @override
  String? get title;
  @override
  String? get author;
  @override
  String? get content;
  @override
  String? get madeDateTime;
  @override
  String? get modifiedDateTime;
  @override
  @JsonKey(ignore: true)
  _$$_AddMemoModelCopyWith<_$_AddMemoModel> get copyWith =>
      throw _privateConstructorUsedError;
}
