// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_exchange_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$GithubExchangeResponse {
  String? get date => throw _privateConstructorUsedError;
  GithubExchangeInfoEntity? get krw => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GithubExchangeResponseCopyWith<GithubExchangeResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GithubExchangeResponseCopyWith<$Res> {
  factory $GithubExchangeResponseCopyWith(GithubExchangeResponse value,
          $Res Function(GithubExchangeResponse) then) =
      _$GithubExchangeResponseCopyWithImpl<$Res, GithubExchangeResponse>;
  @useResult
  $Res call({String? date, GithubExchangeInfoEntity? krw});

  $GithubExchangeInfoEntityCopyWith<$Res>? get krw;
}

/// @nodoc
class _$GithubExchangeResponseCopyWithImpl<$Res,
        $Val extends GithubExchangeResponse>
    implements $GithubExchangeResponseCopyWith<$Res> {
  _$GithubExchangeResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = freezed,
    Object? krw = freezed,
  }) {
    return _then(_value.copyWith(
      date: freezed == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String?,
      krw: freezed == krw
          ? _value.krw
          : krw // ignore: cast_nullable_to_non_nullable
              as GithubExchangeInfoEntity?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $GithubExchangeInfoEntityCopyWith<$Res>? get krw {
    if (_value.krw == null) {
      return null;
    }

    return $GithubExchangeInfoEntityCopyWith<$Res>(_value.krw!, (value) {
      return _then(_value.copyWith(krw: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_GithubExchangeResponseCopyWith<$Res>
    implements $GithubExchangeResponseCopyWith<$Res> {
  factory _$$_GithubExchangeResponseCopyWith(_$_GithubExchangeResponse value,
          $Res Function(_$_GithubExchangeResponse) then) =
      __$$_GithubExchangeResponseCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? date, GithubExchangeInfoEntity? krw});

  @override
  $GithubExchangeInfoEntityCopyWith<$Res>? get krw;
}

/// @nodoc
class __$$_GithubExchangeResponseCopyWithImpl<$Res>
    extends _$GithubExchangeResponseCopyWithImpl<$Res,
        _$_GithubExchangeResponse>
    implements _$$_GithubExchangeResponseCopyWith<$Res> {
  __$$_GithubExchangeResponseCopyWithImpl(_$_GithubExchangeResponse _value,
      $Res Function(_$_GithubExchangeResponse) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = freezed,
    Object? krw = freezed,
  }) {
    return _then(_$_GithubExchangeResponse(
      date: freezed == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String?,
      krw: freezed == krw
          ? _value.krw
          : krw // ignore: cast_nullable_to_non_nullable
              as GithubExchangeInfoEntity?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_GithubExchangeResponse implements _GithubExchangeResponse {
  _$_GithubExchangeResponse({this.date, this.krw});

  factory _$_GithubExchangeResponse.fromJson(Map<String, dynamic> json) =>
      _$$_GithubExchangeResponseFromJson(json);

  @override
  final String? date;
  @override
  final GithubExchangeInfoEntity? krw;

  @override
  String toString() {
    return 'GithubExchangeResponse(date: $date, krw: $krw)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_GithubExchangeResponse &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.krw, krw) || other.krw == krw));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, date, krw);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_GithubExchangeResponseCopyWith<_$_GithubExchangeResponse> get copyWith =>
      __$$_GithubExchangeResponseCopyWithImpl<_$_GithubExchangeResponse>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_GithubExchangeResponseToJson(
      this,
    );
  }
}

abstract class _GithubExchangeResponse implements GithubExchangeResponse {
  factory _GithubExchangeResponse(
      {final String? date,
      final GithubExchangeInfoEntity? krw}) = _$_GithubExchangeResponse;

  factory _GithubExchangeResponse.fromJson(Map<String, dynamic> json) =
      _$_GithubExchangeResponse.fromJson;

  @override
  String? get date;
  @override
  GithubExchangeInfoEntity? get krw;
  @override
  @JsonKey(ignore: true)
  _$$_GithubExchangeResponseCopyWith<_$_GithubExchangeResponse> get copyWith =>
      throw _privateConstructorUsedError;
}
