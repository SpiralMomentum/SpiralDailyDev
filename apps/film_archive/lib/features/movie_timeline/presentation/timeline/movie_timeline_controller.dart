import 'package:flutter/foundation.dart';

import 'package:film_archive/features/movie_timeline/domain/entities/movie_sort_option.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_summary.dart';
import 'package:film_archive/features/movie_timeline/domain/exceptions/exceptions.dart';
import 'package:film_archive/features/movie_timeline/domain/repositories/movie_repository.dart';

class MovieTimelineController extends ChangeNotifier {
  MovieTimelineController({required this.repository});

  final MovieRepository repository;

  MovieTimelineState _state = const MovieTimelineState.initial();

  MovieTimelineState get state => _state;

  void selectSortOption(MovieSortOption option) {
    if (_state.sortOption == option) {
      return;
    }
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

    try {
      final movies = await repository.fetchTopMoviesByYearRange(
        startYear: startYear,
        endYear: endYear,
        sortOption: _state.sortOption,
      );
      final expectedCount = endYear - startYear + 1;
      final notice = movies.isEmpty
          ? '선택한 기간에 표시할 영화가 없습니다.'
          : (movies.length < expectedCount
              ? '일부 연도에는 표시할 영화가 없어 제외되었습니다.'
              : null);
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
    } on MovieRepositoryException catch (error) {
      _emit(
        MovieTimelineState(
          timeline: const [],
          isLoading: false,
          errorMessage: error.message,
          inputMessage: null,
          noticeMessage: null,
          sortOption: _state.sortOption,
        ),
      );
    } catch (_) {
      _emit(
        MovieTimelineState(
          timeline: [],
          isLoading: false,
          errorMessage: '타임라인을 불러오는 중 문제가 발생했습니다.',
          inputMessage: null,
          noticeMessage: null,
          sortOption: _state.sortOption,
        ),
      );
    }
  }

  void _emit(MovieTimelineState newState) {
    _state = newState;
    notifyListeners();
  }
}

class MovieTimelineState {
  const MovieTimelineState({
    required this.timeline,
    required this.isLoading,
    required this.sortOption,
    this.errorMessage,
    this.inputMessage,
    this.noticeMessage,
  });

  const MovieTimelineState.initial()
      : timeline = const [],
        isLoading = false,
        sortOption = MovieSortOption.popularity,
        errorMessage = null,
        inputMessage = null,
        noticeMessage = null;

  final List<MovieSummary> timeline;
  final bool isLoading;
  final MovieSortOption sortOption;
  final String? errorMessage;
  final String? inputMessage;
  final String? noticeMessage;
}
