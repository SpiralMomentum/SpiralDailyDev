import 'package:json_annotation/json_annotation.dart';

part 'my_response.g.dart';

@JsonSerializable()
class MyResponse {
  @JsonKey(name: 'CODE')
  final String responseCode;

  @JsonKey(name: 'MESSAGE')
  final String message;

  MyResponse(this.responseCode, this.message);

  factory MyResponse.fromJson(Map<String, dynamic> json) => _$MyResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MyResponseToJson(this);
}