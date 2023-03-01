import 'package:exchange_rate_calculator/data/core/api_client/exchange/github/github_exchange_api_client.dart';
import 'package:exchange_rate_calculator/data/core/api_client/exchange/korea_exim/korea_exim_exchange_api_client.dart';
import 'package:exchange_rate_calculator/data/entity/exchange/giuhub/github_exchange_response.dart';
import 'package:exchange_rate_calculator/data/entity/exchange/korea_exim/korea_exim_exchange_info_entity.dart';
import 'package:exchange_rate_calculator/domain/repository/exchange/exchange_repository.dart';

class ExchangeAdapterApiClient implements KoreaEximExchangeApiClient {
  late final GithubExchangeApiClient _githubExchangeApiClient;

  ExchangeAdapterApiClient(
      {required GithubExchangeApiClient githubExchangeApiClient}) {
    _githubExchangeApiClient = githubExchangeApiClient;
  }

  @override
  Future<List<KoreaEximExchangeInfoEntity>> getAllExchangeInfo(
    String apiKey,
    String searchDate,
    String dataType,
  ) async {
    List<KoreaEximExchangeInfoEntity> result = [];
    final GithubExchangeResponse githubExchangeResponse =
        await _githubExchangeApiClient.getAllExchangeInfo();
    if (githubExchangeResponse.krw == null) {
      return result;
    } else {
      // TODO
      for (ExchangeCountry exchangeCountry in ExchangeCountry.values) {
        switch (exchangeCountry) {
          case ExchangeCountry.KOREA:
            {
              result.add(
                KoreaEximExchangeInfoEntity(
                  curNm: "한국 원",
                  curUnit: "KRW",
                  dealBasR: "1.0",
                ),
              );
              break;
            }
          case ExchangeCountry.USA:
            {
              final double? dealBasR = githubExchangeResponse.krw?.usd;
              if (dealBasR != null) {
                result.add(
                  KoreaEximExchangeInfoEntity(
                    curNm: exchangeCountry.name,
                    curUnit: exchangeCountry.currentCoinName,
                    dealBasR: (1 / dealBasR).toString(),
                  ),
                );
              }
              break;
            }
          case ExchangeCountry.UK:
            {
              final double? dealBasR = githubExchangeResponse.krw?.gbp;
              if (dealBasR != null) {
                result.add(
                  KoreaEximExchangeInfoEntity(
                    curNm: exchangeCountry.name,
                    curUnit: exchangeCountry.currentCoinName,
                    dealBasR: (1 / dealBasR).toString(),
                  ),
                );
              }
              break;
            }
          case ExchangeCountry.JAPAN:
            {
              final double? dealBasR = githubExchangeResponse.krw?.jpy;
              if (dealBasR != null) {
                result.add(
                  KoreaEximExchangeInfoEntity(
                    curNm: exchangeCountry.name,
                    curUnit: exchangeCountry.currentCoinName,
                    dealBasR: (1 / dealBasR).toString(),
                  ),
                );
              }
              break;
            }
        }
      }
      return result;
    }
  }
/* TODO
  * a 인터페이스에서 제공하는 데이터 형식과, b 인터페이스에서 제공하는 데이터 형식이 상이
  *
  * */
}
