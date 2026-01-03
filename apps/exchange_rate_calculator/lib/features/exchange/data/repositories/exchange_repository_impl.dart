import 'package:exchange_rate_calculator/features/exchange/data/datasources/exchange_adapter_api_client.dart';
import 'package:exchange_rate_calculator/features/exchange/data/models/korea_exim_exchange_info_entity.dart';
import 'package:exchange_rate_calculator/features/exchange/domain/entities/exchange_info.dart';
import 'package:exchange_rate_calculator/features/exchange/domain/repositories/exchange_repository.dart';
import 'package:exchange_rate_calculator/security/api/api_key.dart';
import 'package:utils/utils.dart';

class ExchangeRepositoryImpl implements ExchangeRepository {
  ExchangeRepositoryImpl({required ExchangeAdapterApiClient adapter})
      : _adapter = adapter;

  final ExchangeAdapterApiClient _adapter;
  List<KoreaEximExchangeInfoEntity?> _allExchangeInfo = [];

  @override
  Future<Result<void>> loadAllExchangeInfo() async {
    final result = await _adapter.getAllExchangeInfo(
      ApiKey.KOREA_EXIM_EXCHANGE_API.key,
      "20180102",
      "AP01",
    );
    if (result is ErrorResult<List<KoreaEximExchangeInfoEntity>>) {
      return ErrorResult(result.failure);
    }
    _allExchangeInfo = (result as Success<List<KoreaEximExchangeInfoEntity>>)
        .data
        .cast<KoreaEximExchangeInfoEntity?>();
    return const Success(null);
  }

  @override
  Result<ExchangeInfo> getExchangeInfo(ExchangeCountry exchangeCountry) {
    final matchedExchangeInfos = _allExchangeInfo
        .where((element) => _isMatchWithCountry(element, exchangeCountry))
        .toList();

    if (_isNotValidInfo(matchedExchangeInfos)) {
      return ErrorResult<ExchangeInfo>(
        const ParsingFailure(message: '환율 정보를 불러오지 못했습니다.'),
      );
    }

    return guard(
      action: () {
        return ExchangeInfo(
          countryName: exchangeCountry.name,
          exchangeRate: _getExchangeRate(matchedExchangeInfos.first!),
          currentCoinName: exchangeCountry.currentCoinName,
        );
      },
      onError: _mapFailure,
    );
  }

  bool _isMatchWithCountry(KoreaEximExchangeInfoEntity? exchangeInfo,
      ExchangeCountry exchangeCountry) {
    return (exchangeInfo?.curUnit?.contains(exchangeCountry.currentCoinName) ??
        false);
  }

  bool _isNotValidInfo(List<KoreaEximExchangeInfoEntity?> exchangeInfos) {
    return exchangeInfos.isEmpty ||
        exchangeInfos.first == null ||
        exchangeInfos.first?.dealBasR == null;
  }

  double _getExchangeRate(KoreaEximExchangeInfoEntity exchangeInfo) {
    try {
      String exchangeRateString = exchangeInfo.dealBasR!.trim();
      exchangeRateString = exchangeRateString.replaceAll(",", "");
      return double.parse(exchangeRateString);
    } catch (e) {
      throw Exception();
    }
  }

  @override
  Result<List<String>> getEnableCountry() {
    return Success<List<String>>(
      ExchangeCountry.values.map((e) => e.name).toList(),
    );
  }

  Failure _mapFailure(Object error, StackTrace stackTrace) {
    return NetworkFailure(
      message: '환율 정보를 불러오지 못했습니다.',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
