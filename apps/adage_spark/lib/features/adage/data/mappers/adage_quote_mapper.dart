import 'package:adage_spark/features/adage/data/models/adage_quote_dto.dart';
import 'package:adage_spark/features/adage/domain/entities/adage_quote.dart';

class AdageQuoteMapper {
  const AdageQuoteMapper._();

  static AdageQuote toDomain(AdageQuoteDto dto) {
    return AdageQuote(
      body: dto.body,
      reference: dto.reference,
    );
  }
}
