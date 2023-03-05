import 'package:exchange_rate_calculator/domain/model/exchange/exchange_info_model.dart';

abstract class ExchangeRepository {
  Future<void> loadAllExchangeInfo();
  ExchangeInfoModel getExchangeInfo(ExchangeCountry exchangeCountry);
  List<String> getEnableCountry();
}

enum ExchangeCountry {
  USA,
  JAPAN,
  KOREA,
  UK,
}

extension ExchangeCountryEnumExtension on ExchangeCountry {
  String get name {
    switch (this) {
      case ExchangeCountry.KOREA:
        return "한국";
      case ExchangeCountry.USA:
        return "미국";
      case ExchangeCountry.JAPAN:
        return "일본";
      case ExchangeCountry.UK:
        return "영국";
      default:
        return "한국";
    }
  }

  String get currentCoinName {
    switch (this) {
      case ExchangeCountry.KOREA:
        return "KRW";
      case ExchangeCountry.USA:
        return "USD";
      case ExchangeCountry.JAPAN:
        return "JPY";
      case ExchangeCountry.UK:
        return "GBP";
      default:
        return "";
    }
  }
}
