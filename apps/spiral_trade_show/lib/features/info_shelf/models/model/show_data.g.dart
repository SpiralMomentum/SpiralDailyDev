// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'show_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShowData _$ShowDataFromJson(Map<String, dynamic> json) => ShowData(
      json['DP_NAME'] as String,
      json['DP_MAIN_IMG'] as String,
      json['DP_PLACE'] as String,
      json['DP_INFO'] as String,
      DateTime.parse(json['DP_START'] as String),
      DateTime.parse(json['DP_END'] as String),
    );

Map<String, dynamic> _$ShowDataToJson(ShowData instance) => <String, dynamic>{
      'DP_NAME': instance.title,
      'DP_MAIN_IMG': instance.thumbnail,
      'DP_PLACE': instance.place,
      'DP_INFO': instance.description,
      'DP_START': instance.startTime.toIso8601String(),
      'DP_END': instance.endTime.toIso8601String(),
    };
