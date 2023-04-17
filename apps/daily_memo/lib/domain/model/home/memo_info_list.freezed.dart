// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memo_info_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$MemoInfoList {
  List<MemoInfo> get values => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MemoInfoListCopyWith<MemoInfoList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoInfoListCopyWith<$Res> {
  factory $MemoInfoListCopyWith(
          MemoInfoList value, $Res Function(MemoInfoList) then) =
      _$MemoInfoListCopyWithImpl<$Res, MemoInfoList>;
  @useResult
  $Res call({List<MemoInfo> values});
}

/// @nodoc
class _$MemoInfoListCopyWithImpl<$Res, $Val extends MemoInfoList>
    implements $MemoInfoListCopyWith<$Res> {
  _$MemoInfoListCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? values = null,
  }) {
    return _then(_value.copyWith(
      values: null == values
          ? _value.values
          : values // ignore: cast_nullable_to_non_nullable
              as List<MemoInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_MemoInfoListCopyWith<$Res>
    implements $MemoInfoListCopyWith<$Res> {
  factory _$$_MemoInfoListCopyWith(
          _$_MemoInfoList value, $Res Function(_$_MemoInfoList) then) =
      __$$_MemoInfoListCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<MemoInfo> values});
}

/// @nodoc
class __$$_MemoInfoListCopyWithImpl<$Res>
    extends _$MemoInfoListCopyWithImpl<$Res, _$_MemoInfoList>
    implements _$$_MemoInfoListCopyWith<$Res> {
  __$$_MemoInfoListCopyWithImpl(
      _$_MemoInfoList _value, $Res Function(_$_MemoInfoList) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? values = null,
  }) {
    return _then(_$_MemoInfoList(
      values: null == values
          ? _value._values
          : values // ignore: cast_nullable_to_non_nullable
              as List<MemoInfo>,
    ));
  }
}

/// @nodoc

class _$_MemoInfoList extends _MemoInfoList {
  const _$_MemoInfoList({required final List<MemoInfo> values})
      : _values = values,
        super._();

  final List<MemoInfo> _values;
  @override
  List<MemoInfo> get values {
    if (_values is EqualUnmodifiableListView) return _values;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_values);
  }

  @override
  String toString() {
    return 'MemoInfoList(values: $values)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_MemoInfoList &&
            const DeepCollectionEquality().equals(other._values, _values));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_values));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_MemoInfoListCopyWith<_$_MemoInfoList> get copyWith =>
      __$$_MemoInfoListCopyWithImpl<_$_MemoInfoList>(this, _$identity);
}

abstract class _MemoInfoList extends MemoInfoList {
  const factory _MemoInfoList({required final List<MemoInfo> values}) =
      _$_MemoInfoList;
  const _MemoInfoList._() : super._();

  @override
  List<MemoInfo> get values;
  @override
  @JsonKey(ignore: true)
  _$$_MemoInfoListCopyWith<_$_MemoInfoList> get copyWith =>
      throw _privateConstructorUsedError;
}
