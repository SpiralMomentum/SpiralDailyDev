import 'package:adage_spark/features/adage/domain/entities/adage_quote.dart';
import 'package:adage_spark/features/adage/domain/repositories/adage_repository.dart';
import 'package:utils/utils.dart';

class GetAdageQuotesUseCase {
  const GetAdageQuotesUseCase({required AdageRepository repository})
      : _repository = repository;

  final AdageRepository _repository;

  Future<Result<List<AdageQuote>>> call() {
    return _repository.fetchQuotes();
  }
}
