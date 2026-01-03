import 'package:json_annotation/json_annotation.dart';

import 'my_response.dart';
import 'show_data.dart';

part 'trade_show_info.g.dart';

@JsonSerializable(explicitToJson: true)
class TradeShowInfo {
  @JsonKey(name: 'list_total_count')
  final int totalCount;
  @JsonKey(name: 'RESULT')
  final MyResponse myResponse;
  @JsonKey(name: 'row')
  final List<ShowData> showDataList;

  TradeShowInfo(this.totalCount, this.myResponse, this.showDataList);

  factory TradeShowInfo.fromJson(Map<String, dynamic> json) => _$TradeShowInfoFromJson(json);
  Map<String,dynamic> toJson() => _$TradeShowInfoToJson(this);
}
