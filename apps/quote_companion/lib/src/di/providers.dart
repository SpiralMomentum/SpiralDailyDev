import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/quote_local_data_source.dart';
import '../data/repositories/quote_repository_impl.dart';
import '../domain/repositories/quote_repository.dart';
import '../domain/usecases/add_custom_quote.dart';
import '../domain/usecases/fetch_custom_quotes.dart';
import '../domain/usecases/load_feedback_history.dart';
import '../domain/usecases/load_display_preferences.dart';
import '../domain/usecases/refresh_active_quote.dart';
import '../domain/usecases/remove_custom_quote.dart';
import '../domain/usecases/submit_feedback.dart';
import '../domain/usecases/update_display_preferences.dart';
import '../domain/usecases/watch_active_quote.dart';

/// Provider for the local data source.
final quoteLocalDataSourceProvider = Provider<QuoteLocalDataSource>((ref) {
  return SecureQuoteLocalDataSource();
});

/// Provider for the [QuoteRepository].
final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  final QuoteLocalDataSource dataSource =
      ref.watch(quoteLocalDataSourceProvider);
  return QuoteRepositoryImpl(localDataSource: dataSource);
});

/// Watch active quote use-case provider.
final watchActiveQuoteProvider = Provider<WatchActiveQuote>((ref) {
  return WatchActiveQuote(ref.watch(quoteRepositoryProvider));
});

/// Add custom quote use-case provider.
final addCustomQuoteProvider = Provider<AddCustomQuote>((ref) {
  return AddCustomQuote(ref.watch(quoteRepositoryProvider));
});

/// Remove custom quote use-case provider.
final removeCustomQuoteProvider = Provider<RemoveCustomQuote>((ref) {
  return RemoveCustomQuote(ref.watch(quoteRepositoryProvider));
});

/// Refresh active quote use-case provider.
final refreshActiveQuoteProvider = Provider<RefreshActiveQuote>((ref) {
  return RefreshActiveQuote(ref.watch(quoteRepositoryProvider));
});

/// Fetch custom quotes use-case provider.
final fetchCustomQuotesProvider = Provider<FetchCustomQuotes>((ref) {
  return FetchCustomQuotes(ref.watch(quoteRepositoryProvider));
});

/// Submit feedback use-case provider.
final submitFeedbackProvider = Provider<SubmitFeedback>((ref) {
  return SubmitFeedback(ref.watch(quoteRepositoryProvider));
});

/// Load feedback history use-case provider.
final loadFeedbackHistoryProvider = Provider<LoadFeedbackHistory>((ref) {
  return LoadFeedbackHistory(ref.watch(quoteRepositoryProvider));
});

/// Load display preferences use-case provider.
final loadDisplayPreferencesProvider = Provider<LoadDisplayPreferences>((ref) {
  return LoadDisplayPreferences(ref.watch(quoteRepositoryProvider));
});

/// Update display preferences use-case provider.
final updateDisplayPreferencesProvider =
    Provider<UpdateDisplayPreferences>((ref) {
  return UpdateDisplayPreferences(ref.watch(quoteRepositoryProvider));
});
