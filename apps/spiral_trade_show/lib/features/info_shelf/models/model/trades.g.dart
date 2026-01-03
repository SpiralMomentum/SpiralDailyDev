// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trades.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trades _$TradesFromJson(Map<String, dynamic> json) => Trades(
      TradeShowInfo.fromJson(
          json['ListExhibitionOfSeoulMOAInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TradesToJson(Trades instance) => <String, dynamic>{
      'ListExhibitionOfSeoulMOAInfo': instance.tradeShowInfo.toJson(),
    };
