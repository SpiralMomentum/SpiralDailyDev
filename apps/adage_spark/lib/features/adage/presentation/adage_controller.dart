import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:adage_spark/features/adage/domain/entities/adage_quote.dart';
import 'package:adage_spark/features/adage/domain/usecases/add_adage_quote_use_case.dart';
import 'package:adage_spark/features/adage/domain/usecases/get_adage_quotes_use_case.dart';

import 'adage_state.dart';

class AdageController extends ChangeNotifier {
  AdageController({
    required GetAdageQuotesUseCase getAdageQuotesUseCase,
    required AddAdageQuoteUseCase addAdageQuoteUseCase,
  })  : _getAdageQuotesUseCase = getAdageQuotesUseCase,
        _addAdageQuoteUseCase = addAdageQuoteUseCase;

  final GetAdageQuotesUseCase _getAdageQuotesUseCase;
  final AddAdageQuoteUseCase _addAdageQuoteUseCase;
  final Random _random = Random();

  AdageState _state = const AdageState.initial();
  AdageState get state => _state;

  Future<void> load() async {
    final result = await _getAdageQuotesUseCase();
    result.when(
      success: (quotes) {
        _emit(
          AdageState(
            quotes: quotes,
            current: quotes.isNotEmpty ? quotes.first : null,
          ),
        );
      },
      error: (failure) {
        _emit(
          AdageState(
            quotes: const [],
            current: null,
            errorMessage: failure.message ?? '격언을 불러오지 못했습니다.',
          ),
        );
      },
    );
  }

  void showNextQuote() {
    final current = _state.current;
    if (current == null || !_state.canShuffle) {
      return;
    }

    AdageQuote next;
    do {
      next = _state.quotes[_random.nextInt(_state.quotes.length)];
    } while (identical(next, current));

    _emit(
      AdageState(
        quotes: _state.quotes,
        current: next,
      ),
    );
  }

  Future<void> addQuote({
    required String body,
    required String reference,
  }) async {
    final result = await _addAdageQuoteUseCase(
      body: body,
      reference: reference,
    );
    result.when(
      success: (quote) {
        final updatedQuotes = [quote, ..._state.quotes];
        _emit(
          AdageState(
            quotes: updatedQuotes,
            current: quote,
          ),
        );
      },
      error: (failure) {
        _emit(
          AdageState(
            quotes: _state.quotes,
            current: _state.current,
            errorMessage: failure.message ?? '격언을 저장하지 못했습니다.',
          ),
        );
      },
    );
  }

  void _emit(AdageState state) {
    _state = state;
    notifyListeners();
  }
}
