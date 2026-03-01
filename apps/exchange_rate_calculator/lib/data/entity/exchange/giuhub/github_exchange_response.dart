import 'package:exchange_rate_calculator/data/entity/exchange/giuhub/github_exchange_info_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'github_exchange_response.g.dart';
part 'github_exchange_response.freezed.dart';

@freezed
@JsonSerializable()
class GithubExchangeResponse with _$GithubExchangeResponse{
  factory GithubExchangeResponse({
    final String? date,
    final GithubExchangeInfoEntity? krw,
  })=_GithubExchangeResponse;

  factory GithubExchangeResponse.fromJson(Map<String, dynamic> json) =>
      _$GithubExchangeResponseFromJson(json);
}