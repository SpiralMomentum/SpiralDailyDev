import 'package:exchange_rate_calculator/features/exchange/domain/repositories/exchange_repository.dart';
import 'package:utils/utils.dart';

class LoadExchangeInfoUseCase {
  const LoadExchangeInfoUseCase({required ExchangeRepository repository})
      : _repository = repository;

  final ExchangeRepository _repository;

  Future<Result<void>> call() {
    return _repository.loadAllExchangeInfo();
  }
}
