import '../entities/feedback_entry.dart';
import '../repositories/quote_repository.dart';

/// Records VOC submissions from the user.
class SubmitFeedback {
  /// Creates [SubmitFeedback].
  const SubmitFeedback(this._repository);

  final QuoteRepository _repository;

  /// Persists the entry.
  Future<void> call(FeedbackEntry entry) =>
      _repository.submitFeedback(entry);
}
