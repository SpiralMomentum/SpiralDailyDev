import 'package:json_annotation/json_annotation.dart';
import 'package:spiral_trade_show/info_shelf/model/trade_show_info.dart';

part 'trades.g.dart';

@JsonSerializable(explicitToJson: true)
class Trades {
  @JsonKey(name: 'ListExhibitionOfSeoulMOAInfo')
  final TradeShowInfo tradeShowInfo;

  Trades(this.tradeShowInfo);

  factory Trades.fromJson(Map<String, dynamic> json) => _$TradesFromJson(json);
  Map<String, dynamic> toJson() => _$TradesToJson(this);
}