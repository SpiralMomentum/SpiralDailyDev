import '../entities/quote.dart';
import '../repositories/quote_repository.dart';

/// Use-case for observing the active quote.
class WatchActiveQuote {
  /// Creates a [WatchActiveQuote].
  const WatchActiveQuote(this._repository);

  final QuoteRepository _repository;

  /// Executes the use-case.
  Stream<Quote> call() => _repository.watchActiveQuote();
}
