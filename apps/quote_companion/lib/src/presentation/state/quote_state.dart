import 'package:equatable/equatable.dart';

import '../../domain/entities/feedback_entry.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/quote_display_preferences.dart';

/// Represents the UI state for the quote dashboard.
class QuoteState extends Equatable {
  /// Creates [QuoteState].
  const QuoteState({
    required this.isLoading,
    this.activeQuote,
    required this.customQuotes,
    required this.feedbackHistory,
    required this.displayPreferences,
    this.errorMessage,
  });

  /// Initial state.
  factory QuoteState.initial() => QuoteState(
        isLoading: true,
        customQuotes: const <Quote>[],
        feedbackHistory: const <FeedbackEntry>[],
        displayPreferences: const QuoteDisplayPreferences.defaults(),
      );

  /// Loading indicator.
  final bool isLoading;

  /// Currently active quote.
  final Quote? activeQuote;

  /// Stored custom quotes.
  final List<Quote> customQuotes;

  /// Stored feedback submissions.
  final List<FeedbackEntry> feedbackHistory;

  /// Preferred delivery configuration across surfaces.
  final QuoteDisplayPreferences displayPreferences;

  /// Optional error message.
  final String? errorMessage;

  /// Creates a copy with updates.
  QuoteState copyWith({
    bool? isLoading,
    Quote? activeQuote,
    List<Quote>? customQuotes,
    List<FeedbackEntry>? feedbackHistory,
    QuoteDisplayPreferences? displayPreferences,
    String? errorMessage,
  }) {
    return QuoteState(
      isLoading: isLoading ?? this.isLoading,
      activeQuote: activeQuote ?? this.activeQuote,
      customQuotes: customQuotes ?? this.customQuotes,
      feedbackHistory: feedbackHistory ?? this.feedbackHistory,
      displayPreferences: displayPreferences ?? this.displayPreferences,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        isLoading,
        activeQuote,
        customQuotes,
        feedbackHistory,
        displayPreferences,
        errorMessage,
      ];
}
