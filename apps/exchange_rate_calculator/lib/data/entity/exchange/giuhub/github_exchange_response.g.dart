// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_exchange_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GithubExchangeResponse _$GithubExchangeResponseFromJson(
        Map<String, dynamic> json) =>
    GithubExchangeResponse(
      date: json['date'] as String?,
      krw: json['krw'] == null
          ? null
          : GithubExchangeInfoEntity.fromJson(
              json['krw'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GithubExchangeResponseToJson(
        GithubExchangeResponse instance) =>
    <String, dynamic>{
      'date': instance.date,
      'krw': instance.krw,
    };

_$_GithubExchangeResponse _$$_GithubExchangeResponseFromJson(
        Map<String, dynamic> json) =>
    _$_GithubExchangeResponse(
      date: json['date'] as String?,
      krw: json['krw'] == null
          ? null
          : GithubExchangeInfoEntity.fromJson(
              json['krw'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_GithubExchangeResponseToJson(
        _$_GithubExchangeResponse instance) =>
    <String, dynamic>{
      'date': instance.date,
      'krw': instance.krw,
    };
