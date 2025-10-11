import '../entities/feedback_entry.dart';
import '../repositories/quote_repository.dart';

/// Loads locally stored feedback submissions.
class LoadFeedbackHistory {
  /// Creates [LoadFeedbackHistory].
  const LoadFeedbackHistory(this._repository);

  final QuoteRepository _repository;

  /// Executes the use-case.
  Future<List<FeedbackEntry>> call() =>
      _repository.loadFeedbackHistory();
}
