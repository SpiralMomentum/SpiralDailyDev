import 'package:flutter/foundation.dart';

import 'package:film_archive/core/analytics/analytics_events.dart';
import 'package:app_analytics/app_analytics.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_sort_option.dart';
import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_timeline_use_case.dart';

import 'movie_timeline_state.dart';

class MovieTimelineController extends ChangeNotifier {
  MovieTimelineController({
    required this.getMovieTimelineUseCase,
    this.analyticsTracker,
  });

  static const String _defaultErrorMessage =
      '타임라인을 불러오는 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';

  final GetMovieTimelineUseCase getMovieTimelineUseCase;
  final AnalyticsTracker? analyticsTracker;

  MovieTimelineState _state = const MovieTimelineState.initial();

  MovieTimelineState get state => _state;

  void selectSortOption(MovieSortOption option) {
    if (_state.sortOption == option) {
      return;
    }
    analyticsTracker?.trackEvent(
      AnalyticsEvents.sortOrderChanged,
      {'sort_option': option.name},
    );
    _emit(
      MovieTimelineState(
        timeline: _state.timeline,
        isLoading: _state.isLoading,
        errorMessage: _state.errorMessage,
        inputMessage: _state.inputMessage,
        noticeMessage: _state.noticeMessage,
        sortOption: option,
      ),
    );
  }

  Future<void> buildTimeline({
    required String startYearText,
    required String endYearText,
  }) async {
    final currentYear = DateTime.now().year;
    const minStartYear = 2000;
    final startYear = int.tryParse(startYearText);
    final endYear = int.tryParse(endYearText);

    if (startYear == null || endYear == null) {
      _emit(
        MovieTimelineState(
          timeline: _state.timeline,
          isLoading: false,
          errorMessage: null,
          inputMessage: '연도는 숫자로 입력해주세요.',
          noticeMessage: _state.noticeMessage,
          sortOption: _state.sortOption,
        ),
      );
      return;
    }
    if (startYear < minStartYear) {
      _emit(
        MovieTimelineState(
          timeline: _state.timeline,
          isLoading: false,
          errorMessage: null,
          inputMessage: '시작 연도는 $minStartYear년 이후로 입력해주세요.',
          noticeMessage: _state.noticeMessage,
          sortOption: _state.sortOption,
        ),
      );
      return;
    }
    if (endYear > currentYear) {
      _emit(
        MovieTimelineState(
          timeline: _state.timeline,
          isLoading: false,
          errorMessage: null,
          inputMessage: '종료 연도는 $currentYear년까지 입력할 수 있습니다.',
          noticeMessage: _state.noticeMessage,
          sortOption: _state.sortOption,
        ),
      );
      return;
    }
    if (startYear > endYear) {
      _emit(
        MovieTimelineState(
          timeline: _state.timeline,
          isLoading: false,
          errorMessage: null,
          inputMessage: '연도 범위를 다시 확인해주세요.',
          noticeMessage: _state.noticeMessage,
          sortOption: _state.sortOption,
        ),
      );
      return;
    }

    _emit(
      MovieTimelineState(
        timeline: [],
        isLoading: true,
        errorMessage: null,
        inputMessage: null,
        noticeMessage: null,
        sortOption: _state.sortOption,
      ),
    );

    final result = await getMovieTimelineUseCase(
      startYear: startYear,
      endYear: endYear,
      sortOption: _state.sortOption,
    );
    result.when(
      success: (movies) {
        final expectedCount = endYear - startYear + 1;
        final notice = movies.isEmpty
            ? '선택한 기간에 표시할 영화가 없습니다.'
            : (movies.length < expectedCount
                ? '일부 연도에는 표시할 영화가 없어 제외되었습니다.'
                : null);
        analyticsTracker?.trackEvent(
          AnalyticsEvents.timelineViewed,
          {
            'start_year': startYear,
            'end_year': endYear,
            'result_count': movies.length,
          },
        );
        _emit(
          MovieTimelineState(
            timeline: movies,
            isLoading: false,
            errorMessage: null,
            inputMessage: null,
            noticeMessage: notice,
            sortOption: _state.sortOption,
          ),
        );
      },
      error: (failure) {
        _emit(
          MovieTimelineState(
            timeline: const [],
            isLoading: false,
            errorMessage: failure.message ?? _defaultErrorMessage,
            inputMessage: null,
            noticeMessage: null,
            sortOption: _state.sortOption,
          ),
        );
      },
    );
  }

  /// 영화 상세 화면 진입 시 호출하여 이벤트를 기록한다.
  void trackMovieDetailViewed({required int movieId, required String title}) {
    analyticsTracker?.trackEvent(
      AnalyticsEvents.movieDetailViewed,
      {'movie_id': movieId, 'title': title},
    );
  }

  void _emit(MovieTimelineState newState) {
    _state = newState;
    notifyListeners();
  }
}
