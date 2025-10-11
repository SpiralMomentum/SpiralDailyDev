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
    required this.preferences,
    required this.feedbackHistory,
    this.errorMessage,
  });

  /// Initial state.
  factory QuoteState.initial() => QuoteState(
        isLoading: true,
        customQuotes: const <Quote>[],
        preferences: QuoteDisplayPreferences.defaults(),
        feedbackHistory: const <FeedbackEntry>[],
      );

  /// Loading indicator.
  final bool isLoading;

  /// Currently active quote.
  final Quote? activeQuote;

  /// Stored custom quotes.
  final List<Quote> customQuotes;

  /// Display preferences.
  final QuoteDisplayPreferences preferences;

  /// Stored feedback submissions.
  final List<FeedbackEntry> feedbackHistory;

  /// Optional error message.
  final String? errorMessage;

  /// Creates a copy with updates.
  QuoteState copyWith({
    bool? isLoading,
    Quote? activeQuote,
    List<Quote>? customQuotes,
    QuoteDisplayPreferences? preferences,
    List<FeedbackEntry>? feedbackHistory,
    String? errorMessage,
  }) {
    return QuoteState(
      isLoading: isLoading ?? this.isLoading,
      activeQuote: activeQuote ?? this.activeQuote,
      customQuotes: customQuotes ?? this.customQuotes,
      preferences: preferences ?? this.preferences,
      feedbackHistory: feedbackHistory ?? this.feedbackHistory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        isLoading,
        activeQuote,
        customQuotes,
        preferences,
        feedbackHistory,
        errorMessage,
      ];
}
