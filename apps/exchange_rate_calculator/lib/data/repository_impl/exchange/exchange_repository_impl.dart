import 'package:dio/dio.dart';
import 'package:exchange_rate_calculator/data/core/api_client/exchange/exchange_adapter_api_client.dart';
import 'package:exchange_rate_calculator/data/core/api_client/exchange/github/github_exchange_api_client.dart';
import 'package:exchange_rate_calculator/data/core/api_client/exchange/korea_exim/korea_exim_exchange_api_client.dart';
import 'package:exchange_rate_calculator/data/entity/exchange/korea_exim/korea_exim_exchange_info_entity.dart';
import 'package:exchange_rate_calculator/domain/model/exchange/exchange_info_model.dart';
import 'package:exchange_rate_calculator/domain/repository/exchange/exchange_repository.dart';
import 'package:exchange_rate_calculator/security/api/api_key.dart';

class ExchangeRepositoryImpl implements ExchangeRepository {
  ExchangeRepositoryImpl._init();

  static final ExchangeRepositoryImpl _instance =
      ExchangeRepositoryImpl._init();

  factory ExchangeRepositoryImpl() {
    return _instance;
  }

  List<KoreaEximExchangeInfoEntity?> _allExchangeInfo = [];

  @override
  Future<void> loadAllExchangeInfo() async {
    final Dio dio = Dio();

    // 기존 환율을 가져오는 동작
    final KoreaEximExchangeApiClient apiClient =
        KoreaEximExchangeApiClient(dio);

    // 어댑터를 이용해 가져오는 동작
    final ExchangeAdapterApiClient adapterApiClient = ExchangeAdapterApiClient(
      githubExchangeApiClient: GithubExchangeApiClient(dio),
    );

    // _allExchangeInfo = await apiClient.getAllExchangeInfo(
    _allExchangeInfo = await adapterApiClient.getAllExchangeInfo(
      ApiKey.KOREA_EXIM_EXCHANGE_API.key,
      "20180102",
      "AP01",
    );
  }

  @override
  ExchangeInfoModel getExchangeInfo(ExchangeCountry exchangeCountry) {
    final List<KoreaEximExchangeInfoEntity?> matchedExchangeInfos = _allExchangeInfo
        .where((element) => _isMatchWithCountry(element, exchangeCountry))
        .toList();

    if (_isNotValidInfo(matchedExchangeInfos)) {
      return _getDefaultExchangeInfo;
    } else {
      try {
        return ExchangeInfoModel(
          countryName: exchangeCountry.name,
          exchangeRate: _getExchangeRate(matchedExchangeInfos.first!),
          currentCoinName: exchangeCountry.currentCoinName,
        );
      } catch (e) {
        return _getDefaultExchangeInfo;
      }
    }
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
  List<String> getEnableCountry() =>
      ExchangeCountry.values.map((e) => e.name).toList();

  ExchangeInfoModel get _getDefaultExchangeInfo => ExchangeInfoModel(
        countryName: '',
        exchangeRate: 0.0,
        currentCoinName: '',
      );
}
