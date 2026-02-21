import 'dart:math';

import 'package:app_logging/app_logging.dart';
import 'package:flutter/foundation.dart';

import 'package:adage_spark/core/analytics/analytics_events.dart';
import 'package:app_analytics/app_analytics.dart';
import 'package:adage_spark/features/adage/domain/entities/adage_quote.dart';
import 'package:adage_spark/features/adage/domain/usecases/add_adage_quote_use_case.dart';
import 'package:adage_spark/features/adage/domain/usecases/get_adage_quotes_use_case.dart';

import 'adage_state.dart';

class AdageController extends ChangeNotifier {
  AdageController({
    required GetAdageQuotesUseCase getAdageQuotesUseCase,
    required AddAdageQuoteUseCase addAdageQuoteUseCase,
    AnalyticsTracker? analyticsTracker,
  })  : _getAdageQuotesUseCase = getAdageQuotesUseCase,
        _addAdageQuoteUseCase = addAdageQuoteUseCase,
        _analyticsTracker = analyticsTracker;

  final GetAdageQuotesUseCase _getAdageQuotesUseCase;
  final AddAdageQuoteUseCase _addAdageQuoteUseCase;
  final AnalyticsTracker? _analyticsTracker;
  final Random _random = Random();
  final AppLogger _logger = AppLogger(tag: 'AdageController');

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
        // 첫 번째 격언이 표시되면 quoteViewed 이벤트 기록
        if (quotes.isNotEmpty) {
          _analyticsTracker?.trackEvent(
            AnalyticsEvents.quoteViewed,
            {'body': quotes.first.body},
          );
        }
      },
      error: (failure) {
        _logger.error(
          '격언 로드 실패: ${failure.message}',
          error: failure,
        );
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

    // 셔플로 새 격언이 표시되면 이벤트 기록
    _analyticsTracker?.trackEvent(
      AnalyticsEvents.quoteShuffle,
      {'body': next.body},
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
        // 새 격언 추가 성공 시 이벤트 기록
        _analyticsTracker?.trackEvent(
          AnalyticsEvents.quoteAdded,
          {'body': quote.body, 'reference': quote.reference},
        );
      },
      error: (failure) {
        _logger.error(
          '격언 추가 실패: ${failure.message}',
          error: failure,
        );
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
