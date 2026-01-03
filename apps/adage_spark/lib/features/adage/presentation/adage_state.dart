import 'package:adage_spark/features/adage/domain/entities/adage_quote.dart';

class AdageState {
  const AdageState({
    required this.quotes,
    required this.current,
    this.errorMessage,
  });

  const AdageState.initial()
      : quotes = const [],
        current = null,
        errorMessage = null;

  final List<AdageQuote> quotes;
  final AdageQuote? current;
  final String? errorMessage;

  bool get canShuffle => quotes.length > 1;
}
