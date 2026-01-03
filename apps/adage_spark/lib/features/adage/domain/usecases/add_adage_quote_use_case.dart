import 'package:adage_spark/features/adage/domain/entities/adage_quote.dart';
import 'package:adage_spark/features/adage/domain/repositories/adage_repository.dart';
import 'package:utils/utils.dart';

class AddAdageQuoteUseCase {
  const AddAdageQuoteUseCase({required AdageRepository repository})
      : _repository = repository;

  final AdageRepository _repository;

  Future<Result<AdageQuote>> call({
    required String body,
    required String reference,
  }) {
    return _repository.addCustomQuote(body: body, reference: reference);
  }
}
