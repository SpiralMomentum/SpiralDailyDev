import 'package:film_archive/features/movie_timeline/domain/entities/movie_detail.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_sort_option.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_summary.dart';
import 'package:utils/utils.dart';

abstract class MovieRepository {
  Future<Result<List<MovieSummary>>> fetchTopMoviesByYearRange({
    required int startYear,
    required int endYear,
    required MovieSortOption sortOption,
  });

  Future<Result<MovieDetail>> fetchMovieDetail(int movieId);
}
