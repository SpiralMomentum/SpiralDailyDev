import '../repositories/quote_repository.dart';

/// Use-case for removing a user quote.
class RemoveCustomQuote {
  /// Creates [RemoveCustomQuote].
  const RemoveCustomQuote(this._repository);

  final QuoteRepository _repository;

  /// Executes removal.
  Future<void> call(String id) => _repository.removeCustomQuote(id);
}
