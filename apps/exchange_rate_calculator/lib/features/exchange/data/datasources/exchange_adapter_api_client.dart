import 'package:exchange_rate_calculator/features/exchange/data/datasources/exchange_remote_data_source.dart';
import 'package:exchange_rate_calculator/features/exchange/data/exceptions/external_exception.dart';
import 'package:exchange_rate_calculator/features/exchange/data/models/github_exchange_response.dart';
import 'package:exchange_rate_calculator/features/exchange/data/models/korea_exim_exchange_info_entity.dart';
import 'package:exchange_rate_calculator/features/exchange/domain/repositories/exchange_repository.dart';
import 'package:utils/utils.dart';

class ExchangeAdapterApiClient {
  ExchangeAdapterApiClient({
    required ExchangeRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ExchangeRemoteDataSource _remoteDataSource;

  Future<Result<List<KoreaEximExchangeInfoEntity>>> getAllExchangeInfo(
    String apiKey,
    String searchDate,
    String dataType,
  ) async {
    List<KoreaEximExchangeInfoEntity> result = [];
    final responseResult = await _remoteDataSource.fetchGithubExchange();
    if (responseResult is ErrorResult<GithubExchangeResponse>) {
      return ErrorResult(
        _mapExternalFailure(responseResult.failure, StackTrace.current),
      );
    }
    final githubExchangeResponse =
        (responseResult as Success<GithubExchangeResponse>).data;
    if (githubExchangeResponse.krw == null) {
      return Success(result);
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
      return Success(result);
    }
  }
/* TODO
  * a 인터페이스에서 제공하는 데이터 형식과, b 인터페이스에서 제공하는 데이터 형식이 상이
  *
  * */

  Failure _mapExternalFailure(Failure error, StackTrace stackTrace) {
    if (error is NetworkExternalException) {
      return NetworkFailure(
        message: error.message ?? '환율 정보를 불러오지 못했습니다.',
        cause: error.cause ?? error,
        stackTrace: stackTrace,
      );
    }
    return NetworkFailure(
      message: '환율 정보를 불러오지 못했습니다.',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
