import 'package:adage_spark/features/adage/data/datasources/adage_local_data_source.dart';
import 'package:adage_spark/features/adage/data/mappers/adage_quote_mapper.dart';
import 'package:adage_spark/features/adage/data/models/adage_quote_dto.dart';
import 'package:adage_spark/features/adage/domain/entities/adage_quote.dart';
import 'package:adage_spark/features/adage/domain/repositories/adage_repository.dart';
import 'package:utils/utils.dart';

class AdageRepositoryImpl implements AdageRepository {
  AdageRepositoryImpl({required AdageLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  final AdageLocalDataSource _localDataSource;

  @override
  Future<Result<List<AdageQuote>>> fetchQuotes() async {
    final result = _localDataSource.fetchQuotes();
    return result.map(
      (items) => items.map(AdageQuoteMapper.toDomain).toList(),
    );
  }

  @override
  Future<Result<AdageQuote>> addCustomQuote({
    required String body,
    required String reference,
  }) async {
    final dto = AdageQuoteDto(body: body, reference: reference);
    final result = _localDataSource.addCustomQuote(dto);
    return result.map(AdageQuoteMapper.toDomain);
  }
}
