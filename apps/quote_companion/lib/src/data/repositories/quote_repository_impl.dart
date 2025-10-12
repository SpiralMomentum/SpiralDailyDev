import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/feedback_entry.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/quote_display_preferences.dart';
import '../../domain/repositories/quote_repository.dart';
import '../datasources/quote_local_data_source.dart';
import '../models/feedback_entry_model.dart';
import '../models/quote_display_preferences_model.dart';
import '../models/quote_model.dart';

/// Implementation of [QuoteRepository] using local data sources.
class QuoteRepositoryImpl implements QuoteRepository {
  /// Creates a [QuoteRepositoryImpl].
  QuoteRepositoryImpl({
    required QuoteLocalDataSource localDataSource,
    List<Quote>? curatedQuotes,
    AssetBundle? bundle,
  })  : _localDataSource = localDataSource,
        _bundle = bundle ?? rootBundle,
        _curatedQuotes = curatedQuotes ?? <Quote>[],
        _controller = StreamController<Quote>.broadcast();

  final QuoteLocalDataSource _localDataSource;
  final AssetBundle _bundle;
  final List<Quote> _curatedQuotes;
  final StreamController<Quote> _controller;
  final Random _random = Random();
  final Uuid _uuid = const Uuid();

  Quote? _activeQuote;
  List<Quote> _customQuotes = <Quote>[];
  QuoteDisplayPreferences _preferences = QuoteDisplayPreferences.defaults();

  Future<void> _ensureInitialised() async {
    if (_curatedQuotes.isEmpty) {
      await _loadCuratedQuotesFromAssets();
    }
    if (_customQuotes.isEmpty) {
      _customQuotes = await _localDataSource.loadCustomQuotes();
    }
    _preferences = await _localDataSource.loadPreferences();
    _activeQuote ??= await _pickRandomQuote();
    _controller.add(_activeQuote!);
  }

  Future<void> _loadCuratedQuotesFromAssets() async {
    try {
      final String raw = await _bundle.loadString(
        'assets/curated_quotes.json',
      );
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      _curatedQuotes
        ..clear()
        ..addAll(decoded.map((dynamic item) {
          final Map<String, dynamic> json = item as Map<String, dynamic>;
          return Quote.curated(
            id: json['id'] as String,
            text: json['text'] as String,
            author: json['author'] as String? ?? '',
          );
        }));
    } on Exception {
      _curatedQuotes
        ..clear()
        ..addAll(<Quote>[
          Quote.curated(
            id: 'fallback-1',
            text: 'Stay positive, work hard, make it happen.',
            author: 'Unknown',
          ),
        ]);
    }
  }

  Future<Quote> _pickRandomQuote() async {
    final List<Quote> availableQuotes = <Quote>[
      ..._curatedQuotes,
      ..._customQuotes,
    ];
    if (availableQuotes.isEmpty) {
      return Quote.curated(
        id: 'fallback-empty',
        text: 'Add your first quote to get started!',
        author: 'Quote Companion',
      );
    }
    return availableQuotes[_random.nextInt(availableQuotes.length)];
  }

  void _emitQuote(Quote quote) {
    _activeQuote = quote;
    if (!_controller.isClosed) {
      _controller.add(quote);
    }
  }

  @override
  Future<void> addCustomQuote({
    required String text,
    required String author,
  }) async {
    await _ensureInitialised();
    final QuoteModel model = QuoteModel(
      id: _uuid.v4(),
      text: text.trim(),
      author: author.trim(),
      source: QuoteSourceType.custom,
      createdAt: DateTime.now(),
    );
    _customQuotes = <Quote>[..._customQuotes, model];
    await _localDataSource.saveCustomQuotes(
      _customQuotes.map(QuoteModel.fromEntity).toList(),
    );
    _emitQuote(model);
  }

  @override
  Future<List<Quote>> fetchCustomQuotes() async {
    await _ensureInitialised();
    return List<Quote>.unmodifiable(_customQuotes);
  }

  @override
  Future<Quote> getActiveQuote() async {
    await _ensureInitialised();
    return _activeQuote!;
  }

  @override
  Future<QuoteDisplayPreferences> getDisplayPreferences() async {
    await _ensureInitialised();
    return _preferences;
  }

  @override
  Future<List<FeedbackEntry>> loadFeedbackHistory() async {
    await _ensureInitialised();
    final List<FeedbackEntryModel> models =
        await _localDataSource.loadFeedbackHistory();
    return models;
  }

  @override
  Future<void> removeCustomQuote(String id) async {
    await _ensureInitialised();
    _customQuotes = _customQuotes.where((Quote quote) => quote.id != id).toList();
    await _localDataSource.saveCustomQuotes(
      _customQuotes.map(QuoteModel.fromEntity).toList(),
    );
    if (_activeQuote?.id == id) {
      await refreshActiveQuote();
    }
  }

  @override
  Future<Quote> refreshActiveQuote() async {
    await _ensureInitialised();
    final Quote quote = await _pickRandomQuote();
    _emitQuote(quote);
    return quote;
  }

  @override
  Future<void> saveDisplayPreferences(
    QuoteDisplayPreferences preferences,
  ) async {
    await _ensureInitialised();
    _preferences = preferences;
    await _localDataSource.savePreferences(
      QuoteDisplayPreferencesModel.fromEntity(preferences),
    );
  }

  @override
  Future<void> submitFeedback(FeedbackEntry entry) async {
    await _ensureInitialised();
    await _localDataSource.appendFeedback(
      FeedbackEntryModel.fromEntity(entry),
    );
  }

  @override
  Stream<Quote> watchActiveQuote() {
    unawaited(_ensureInitialised());
    return _controller.stream;
  }
}
