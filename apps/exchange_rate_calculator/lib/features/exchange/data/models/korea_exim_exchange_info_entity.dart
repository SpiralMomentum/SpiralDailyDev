import 'package:freezed_annotation/freezed_annotation.dart';

part 'korea_exim_exchange_info_entity.freezed.dart';
part 'korea_exim_exchange_info_entity.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake)
class KoreaEximExchangeInfoEntity with _$KoreaEximExchangeInfoEntity {
  factory KoreaEximExchangeInfoEntity({
    final String? curUnit,
    final String? ttb,
    final String? tts,
    final String? dealBasR,
    final String? bkpr,
    final String? yyEfeeR,
    final String? tenDdEfeeR,
    final String? kftcBkpr,
    final String? kftcDealBasR,
    final String? curNm,
  }) = _KoreaEximExchangeInfoEntity;

  factory KoreaEximExchangeInfoEntity.fromJson(Map<String, dynamic> json) =>
      _$KoreaEximExchangeInfoEntityFromJson(json);


}
