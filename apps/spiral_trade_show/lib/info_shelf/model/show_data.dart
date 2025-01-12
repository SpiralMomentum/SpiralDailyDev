import 'package:html/parser.dart';
import 'package:info_shelf/info_shelf.dart';
import 'package:json_annotation/json_annotation.dart';

part 'show_data.g.dart';

@JsonSerializable()
class ShowData implements Info {
  @JsonKey(name: "DP_NAME")
  @override
  final String title;

  @JsonKey(name: "DP_MAIN_IMG")
  @override
  final String thumbnail;

  @JsonKey(name: "DP_PLACE")
  @override
  final String place;

  @JsonKey(name: 'DP_INFO')
  @override
  final String description;

  @JsonKey(name: 'DP_START')
  @override
  final DateTime startTime;

  @JsonKey(name: 'DP_END')
  @override
  final DateTime endTime;

  ShowData(
    this.title,
    this.thumbnail,
    this.place,
    this.description,
    this.startTime,
    this.endTime,
  );

  factory ShowData.fromJson(Map<String, dynamic> json) =>
      _$ShowDataFromJson(json);

  Map<String, dynamic> toJson() => _$ShowDataToJson(this);

  Info toDomainEntity() => Info(
        title,
        thumbnail,
        place,
        parse(description).documentElement?.text ?? '',
        startTime,
        endTime,
      );

  factory ShowData.dummy() {
    return ShowData(
      "test1",
      "https://picsum.photos/200/300",
      "서울",
      'test',
      DateTime.now(),
      DateTime.now(),
    );
  }
}
