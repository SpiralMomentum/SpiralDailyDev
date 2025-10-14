import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/feedback_entry_model.dart';
import '../models/quote_model.dart';

/// Defines the contract for local quote persistence.
abstract class QuoteLocalDataSource {
  /// Loads persisted custom quotes.
  Future<List<QuoteModel>> loadCustomQuotes();

  /// Stores the provided custom quotes.
  Future<void> saveCustomQuotes(List<QuoteModel> quotes);

  /// Appends a feedback entry to the queue.
  Future<void> appendFeedback(FeedbackEntryModel entry);

  /// Loads the stored feedback history.
  Future<List<FeedbackEntryModel>> loadFeedbackHistory();
}

/// Local data source leveraging secure storage for quotes and feedback data.
class SecureQuoteLocalDataSource implements QuoteLocalDataSource {
  /// Creates [SecureQuoteLocalDataSource].
  SecureQuoteLocalDataSource({
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences>? sharedPreferences,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _prefsFuture = sharedPreferences ?? SharedPreferences.getInstance();

  static const String _customQuotesKey = 'quote_companion.custom_quotes';
  static const String _feedbackQueueKey = 'quote_companion.feedback_queue';

  final FlutterSecureStorage _secureStorage;
  final Future<SharedPreferences> _prefsFuture;

  @override
  Future<List<QuoteModel>> loadCustomQuotes() async {
    final String? storedJson =
        await _secureStorage.read(key: _customQuotesKey);
    if (storedJson == null || storedJson.isEmpty) {
      return <QuoteModel>[];
    }
    final List<dynamic> decoded = jsonDecode(storedJson) as List<dynamic>;
    return decoded
        .map((dynamic item) =>
            QuoteModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveCustomQuotes(List<QuoteModel> quotes) async {
    final List<Map<String, dynamic>> serialized =
        quotes.map((QuoteModel q) => q.toJson()).toList();
    await _secureStorage.write(
      key: _customQuotesKey,
      value: jsonEncode(serialized),
    );
  }

  @override
  Future<void> appendFeedback(FeedbackEntryModel entry) async {
    final SharedPreferences prefs = await _prefsFuture;
    final String? storedJson = prefs.getString(_feedbackQueueKey);
    final List<dynamic> entries = storedJson == null
        ? <dynamic>[]
        : jsonDecode(storedJson) as List<dynamic>;
    entries.add(entry.toJson());
    await prefs.setString(_feedbackQueueKey, jsonEncode(entries));
  }

  @override
  Future<List<FeedbackEntryModel>> loadFeedbackHistory() async {
    final SharedPreferences prefs = await _prefsFuture;
    final String? storedJson = prefs.getString(_feedbackQueueKey);
    if (storedJson == null) {
      return <FeedbackEntryModel>[];
    }
    final List<dynamic> decoded = jsonDecode(storedJson) as List<dynamic>;
    return decoded
        .map((dynamic item) =>
            FeedbackEntryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
