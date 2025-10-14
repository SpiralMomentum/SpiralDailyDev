import '../entities/feedback_entry.dart';
import '../entities/quote.dart';

/// Contract defining operations for fetching and managing quotes.
abstract class QuoteRepository {
  /// Watches the active quote shown to users.
  Stream<Quote> watchActiveQuote();

  /// Returns the currently active quote snapshot.
  Future<Quote> getActiveQuote();

  /// Returns all custom quotes stored on device.
  Future<List<Quote>> fetchCustomQuotes();

  /// Adds a custom quote to the catalogue.
  Future<void> addCustomQuote({
    required String text,
    required String author,
  });

  /// Removes a custom quote by id.
  Future<void> removeCustomQuote(String id);

  /// Rotates the active quote, combining curated and custom sources.
  Future<Quote> refreshActiveQuote();

  /// Records a user feedback entry in the local VOC queue.
  Future<void> submitFeedback(FeedbackEntry entry);

  /// Returns the most recent feedback submissions.
  Future<List<FeedbackEntry>> loadFeedbackHistory();
}
