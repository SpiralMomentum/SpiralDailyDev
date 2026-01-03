import 'package:adage_spark/features/adage/domain/entities/adage_quote.dart';
import 'package:utils/utils.dart';

abstract class AdageRepository {
  Future<Result<List<AdageQuote>>> fetchQuotes();

  Future<Result<AdageQuote>> addCustomQuote({
    required String body,
    required String reference,
  });
}
