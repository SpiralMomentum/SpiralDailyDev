import 'package:film_archive/features/movie_timeline/domain/entities/movie_sort_option.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_summary.dart';

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

  MovieTimelineState copyWith({
    List<MovieSummary>? timeline,
    bool? isLoading,
    MovieSortOption? sortOption,
    String? errorMessage,
    String? inputMessage,
    String? noticeMessage,
  }) {
    return MovieTimelineState(
      timeline: timeline ?? this.timeline,
      isLoading: isLoading ?? this.isLoading,
      sortOption: sortOption ?? this.sortOption,
      errorMessage: errorMessage,
      inputMessage: inputMessage,
      noticeMessage: noticeMessage,
    );
  }
}
