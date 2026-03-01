import 'package:exchange_rate_calculator/data/repository_impl/exchange/exchange_repository_impl.dart';
import 'package:exchange_rate_calculator/domain/model/exchange/exchange_info_model.dart';
import 'package:exchange_rate_calculator/domain/repository/exchange/exchange_repository.dart';
import 'package:rxdart/rxdart.dart';

class HomeViewModel {
  final ExchangeRepository _exchangeRepository = ExchangeRepositoryImpl();
  final List<ExchangeCountry> enableCountries = ExchangeCountry.values;

  ExchangeInfoModel getExchangeInfo(ExchangeCountry exchangeCountry) =>
      _exchangeRepository.getExchangeInfo(exchangeCountry);
}
