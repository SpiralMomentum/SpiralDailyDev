import '../../data/movie_api_client.dart';
import '../entities/movie_detail.dart';
import '../entities/movie_sort_option.dart';
import '../entities/movie_summary.dart';
import '../exceptions.dart';

class MovieRepository {
  MovieRepository({required MovieApiClient apiClient}) : _apiClient = apiClient;

  final MovieApiClient _apiClient;

  Future<List<MovieSummary>> fetchTopMoviesByYearRange({
    required int startYear,
    required int endYear,
    required MovieSortOption sortOption,
  }) async {
    try {
      final timeline = <MovieSummary>[];
      for (var year = endYear; year >= startYear; year--) {
        final summary = await _apiClient.fetchTopMovieForYear(
          year,
          sortOption,
        );
        if (summary != null) {
          timeline.add(summary);
        }
      }
      return timeline;
    } on MovieApiException catch (error) {
      throw MovieRepositoryException(error.message);
    } catch (_) {
      throw MovieRepositoryException(
        '타임라인을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    }
  }

  Future<MovieDetail> fetchMovieDetail(int movieId) async {
    try {
      return await _apiClient.fetchMovieDetail(movieId);
    } on MovieApiException catch (error) {
      throw MovieRepositoryException(error.message);
    } catch (_) {
      throw MovieRepositoryException(
        '영화 정보를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    }
  }
}
