// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_show_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeShowInfo _$TradeShowInfoFromJson(Map<String, dynamic> json) =>
    TradeShowInfo(
      (json['list_total_count'] as num).toInt(),
      MyResponse.fromJson(json['RESULT'] as Map<String, dynamic>),
      (json['row'] as List<dynamic>)
          .map((e) => ShowData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TradeShowInfoToJson(TradeShowInfo instance) =>
    <String, dynamic>{
      'list_total_count': instance.totalCount,
      'RESULT': instance.myResponse.toJson(),
      'row': instance.showDataList.map((e) => e.toJson()).toList(),
    };
