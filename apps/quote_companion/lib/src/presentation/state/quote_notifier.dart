import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../di/providers.dart';
import '../../domain/entities/feedback_entry.dart';
import '../../domain/entities/quote.dart';
import '../../domain/usecases/add_custom_quote.dart';
import '../../domain/usecases/fetch_custom_quotes.dart';
import '../../domain/usecases/load_feedback_history.dart';
import '../../domain/usecases/refresh_active_quote.dart';
import '../../domain/usecases/remove_custom_quote.dart';
import '../../domain/usecases/submit_feedback.dart';
import '../../domain/usecases/watch_active_quote.dart';
import 'quote_state.dart';

/// Riverpod notifier backing the quote dashboard UI.
class QuoteNotifier extends StateNotifier<QuoteState> {
  /// Creates a [QuoteNotifier].
  QuoteNotifier(
    this._watchActiveQuote,
    this._addCustomQuote,
    this._removeCustomQuote,
    this._refreshActiveQuote,
    this._fetchCustomQuotes,
    this._submitFeedback,
    this._loadFeedbackHistory,
  ) : super(QuoteState.initial()) {
    _initialize();
  }

  final WatchActiveQuote _watchActiveQuote;
  final AddCustomQuote _addCustomQuote;
  final RemoveCustomQuote _removeCustomQuote;
  final RefreshActiveQuote _refreshActiveQuote;
  final FetchCustomQuotes _fetchCustomQuotes;
  final SubmitFeedback _submitFeedback;
  final LoadFeedbackHistory _loadFeedbackHistory;
  final Uuid _uuid = const Uuid();

  StreamSubscription<Quote>? _quoteSubscription;

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    _quoteSubscription = _watchActiveQuote().listen((Quote quote) {
      state = state.copyWith(activeQuote: quote, isLoading: false);
    });
    final List<Quote> customQuotes = await _fetchCustomQuotes();
    final List<FeedbackEntry> feedbackHistory =
        await _loadFeedbackHistory();
    state = state.copyWith(
      customQuotes: customQuotes,
      feedbackHistory: feedbackHistory,
      isLoading: false,
    );
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    super.dispose();
  }

  /// Adds a custom quote entered by the user.
  Future<void> addQuote({required String text, required String author}) async {
    try {
      await _addCustomQuote(text: text, author: author);
      final List<Quote> customQuotes = await _fetchCustomQuotes();
      state = state.copyWith(customQuotes: customQuotes, errorMessage: null);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  /// Removes a quote by id.
  Future<void> removeQuote(String id) async {
    await _removeCustomQuote(id);
    final List<Quote> customQuotes = await _fetchCustomQuotes();
    state = state.copyWith(customQuotes: customQuotes);
  }

  /// Rotates the active quote.
  Future<void> refreshQuote() async {
    await _refreshActiveQuote();
  }

  /// Submits quick feedback and stores it locally.
  Future<void> submitFeedback({
    required String message,
    required int rating,
    String? contactEmail,
  }) async {
    final FeedbackEntry entry = FeedbackEntry(
      id: _uuid.v4(),
      message: message,
      rating: rating,
      createdAt: DateTime.now(),
      contactEmail: contactEmail,
    );
    await _submitFeedback(entry);
    final List<FeedbackEntry> history = await _loadFeedbackHistory();
    state = state.copyWith(feedbackHistory: history);
  }
}

/// Provider wiring the [QuoteNotifier].
final quoteNotifierProvider =
    StateNotifierProvider<QuoteNotifier, QuoteState>((ref) {
  return QuoteNotifier(
    ref.watch(watchActiveQuoteProvider),
    ref.watch(addCustomQuoteProvider),
    ref.watch(removeCustomQuoteProvider),
    ref.watch(refreshActiveQuoteProvider),
    ref.watch(fetchCustomQuotesProvider),
    ref.watch(submitFeedbackProvider),
    ref.watch(loadFeedbackHistoryProvider),
  );
});
