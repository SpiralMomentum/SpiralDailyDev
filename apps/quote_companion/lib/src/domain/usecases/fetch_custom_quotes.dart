import '../entities/quote.dart';
import '../repositories/quote_repository.dart';

/// Loads the saved custom quotes.
class FetchCustomQuotes {
  /// Creates [FetchCustomQuotes].
  const FetchCustomQuotes(this._repository);

  final QuoteRepository _repository;

  /// Executes the use-case.
  Future<List<Quote>> call() => _repository.fetchCustomQuotes();
}
