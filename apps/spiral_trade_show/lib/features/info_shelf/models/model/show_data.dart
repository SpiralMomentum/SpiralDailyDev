import 'package:app_logging/app_logging.dart';
import 'package:html/parser.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ui_components/card/info.dart';

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

  static final _logger = AppLogger(tag: 'ShowData');

  Info toDomainEntity() {
    String parsedDescription;
    try {
      parsedDescription = parse(description).documentElement?.text ?? '';
    } catch (error, stackTrace) {
      _logger.error(
        'HTML 파싱 실패 (title: $title)',
        error: error,
        stackTrace: stackTrace,
      );
      parsedDescription = description;
    }
    return Info(
      title,
      thumbnail,
      place,
      parsedDescription,
      startTime,
      endTime,
    );
  }

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
