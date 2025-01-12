// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyResponse _$MyResponseFromJson(Map<String, dynamic> json) => MyResponse(
      json['CODE'] as String,
      json['MESSAGE'] as String,
    );

Map<String, dynamic> _$MyResponseToJson(MyResponse instance) =>
    <String, dynamic>{
      'CODE': instance.responseCode,
      'MESSAGE': instance.message,
    };
