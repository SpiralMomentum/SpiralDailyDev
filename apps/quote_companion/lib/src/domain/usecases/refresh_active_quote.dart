import '../entities/quote.dart';
import '../repositories/quote_repository.dart';

/// Use-case that rotates the currently active quote.
class RefreshActiveQuote {
  /// Creates [RefreshActiveQuote].
  const RefreshActiveQuote(this._repository);

  final QuoteRepository _repository;

  /// Refreshes and returns the new quote.
  Future<Quote> call() => _repository.refreshActiveQuote();
}
