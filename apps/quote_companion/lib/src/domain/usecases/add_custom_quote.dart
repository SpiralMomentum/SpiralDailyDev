import '../repositories/quote_repository.dart';

/// Use-case for adding a user supplied quote.
class AddCustomQuote {
  /// Creates an [AddCustomQuote] use-case.
  const AddCustomQuote(this._repository);

  final QuoteRepository _repository;

  /// Persists the quote.
  Future<void> call({required String text, required String author}) {
    return _repository.addCustomQuote(text: text, author: author);
  }
}
