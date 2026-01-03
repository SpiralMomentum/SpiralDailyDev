import 'package:exchange_rate_calculator/features/exchange/domain/entities/exchange_info.dart';
import 'package:exchange_rate_calculator/features/exchange/domain/repositories/exchange_repository.dart';
import 'package:utils/utils.dart';

class GetExchangeInfoUseCase {
  const GetExchangeInfoUseCase({required ExchangeRepository repository})
      : _repository = repository;

  final ExchangeRepository _repository;

  Result<ExchangeInfo> call(ExchangeCountry exchangeCountry) {
    return _repository.getExchangeInfo(exchangeCountry);
  }
}
