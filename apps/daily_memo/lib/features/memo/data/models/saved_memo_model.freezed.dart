// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_memo_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

SavedMemoModel _$SavedMemoModelFromJson(Map<String, dynamic> json) {
  return _SavedMemoModel.fromJson(json);
}

/// @nodoc
mixin _$SavedMemoModel {
  int get memoId => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get author => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  String? get madeDateTime => throw _privateConstructorUsedError;
  String? get modifiedDateTime => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SavedMemoModelCopyWith<SavedMemoModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SavedMemoModelCopyWith<$Res> {
  factory $SavedMemoModelCopyWith(
          SavedMemoModel value, $Res Function(SavedMemoModel) then) =
      _$SavedMemoModelCopyWithImpl<$Res, SavedMemoModel>;
  @useResult
  $Res call(
      {int memoId,
      String? title,
      String? author,
      String? content,
      String? madeDateTime,
      String? modifiedDateTime});
}

/// @nodoc
class _$SavedMemoModelCopyWithImpl<$Res, $Val extends SavedMemoModel>
    implements $SavedMemoModelCopyWith<$Res> {
  _$SavedMemoModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memoId = null,
    Object? title = freezed,
    Object? author = freezed,
    Object? content = freezed,
    Object? madeDateTime = freezed,
    Object? modifiedDateTime = freezed,
  }) {
    return _then(_value.copyWith(
      memoId: null == memoId
          ? _value.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as int,
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
abstract class _$$_SavedMemoModelCopyWith<$Res>
    implements $SavedMemoModelCopyWith<$Res> {
  factory _$$_SavedMemoModelCopyWith(
          _$_SavedMemoModel value, $Res Function(_$_SavedMemoModel) then) =
      __$$_SavedMemoModelCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int memoId,
      String? title,
      String? author,
      String? content,
      String? madeDateTime,
      String? modifiedDateTime});
}

/// @nodoc
class __$$_SavedMemoModelCopyWithImpl<$Res>
    extends _$SavedMemoModelCopyWithImpl<$Res, _$_SavedMemoModel>
    implements _$$_SavedMemoModelCopyWith<$Res> {
  __$$_SavedMemoModelCopyWithImpl(
      _$_SavedMemoModel _value, $Res Function(_$_SavedMemoModel) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memoId = null,
    Object? title = freezed,
    Object? author = freezed,
    Object? content = freezed,
    Object? madeDateTime = freezed,
    Object? modifiedDateTime = freezed,
  }) {
    return _then(_$_SavedMemoModel(
      memoId: null == memoId
          ? _value.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as int,
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
class _$_SavedMemoModel implements _SavedMemoModel {
  _$_SavedMemoModel(
      {required this.memoId,
      this.title,
      this.author,
      this.content,
      this.madeDateTime,
      this.modifiedDateTime});

  factory _$_SavedMemoModel.fromJson(Map<String, dynamic> json) =>
      _$$_SavedMemoModelFromJson(json);

  @override
  final int memoId;
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
    return 'SavedMemoModel(memoId: $memoId, title: $title, author: $author, content: $content, madeDateTime: $madeDateTime, modifiedDateTime: $modifiedDateTime)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SavedMemoModel &&
            (identical(other.memoId, memoId) || other.memoId == memoId) &&
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
  int get hashCode => Object.hash(runtimeType, memoId, title, author, content,
      madeDateTime, modifiedDateTime);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SavedMemoModelCopyWith<_$_SavedMemoModel> get copyWith =>
      __$$_SavedMemoModelCopyWithImpl<_$_SavedMemoModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_SavedMemoModelToJson(
      this,
    );
  }
}

abstract class _SavedMemoModel implements SavedMemoModel {
  factory _SavedMemoModel(
      {required final int memoId,
      final String? title,
      final String? author,
      final String? content,
      final String? madeDateTime,
      final String? modifiedDateTime}) = _$_SavedMemoModel;

  factory _SavedMemoModel.fromJson(Map<String, dynamic> json) =
      _$_SavedMemoModel.fromJson;

  @override
  int get memoId;
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
  _$$_SavedMemoModelCopyWith<_$_SavedMemoModel> get copyWith =>
      throw _privateConstructorUsedError;
}
