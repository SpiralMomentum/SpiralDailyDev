import 'package:film_archive/features/movie_timeline/domain/entities/movie_sort_option.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_summary.dart';
import 'package:film_archive/features/movie_timeline/domain/repositories/movie_repository.dart';
import 'package:utils/utils.dart';

class GetMovieTimelineUseCase {
  const GetMovieTimelineUseCase({required MovieRepository repository})
      : _repository = repository;

  final MovieRepository _repository;

  Future<Result<List<MovieSummary>>> call({
    required int startYear,
    required int endYear,
    required MovieSortOption sortOption,
  }) {
    return _repository.fetchTopMoviesByYearRange(
      startYear: startYear,
      endYear: endYear,
      sortOption: sortOption,
    );
  }
}
