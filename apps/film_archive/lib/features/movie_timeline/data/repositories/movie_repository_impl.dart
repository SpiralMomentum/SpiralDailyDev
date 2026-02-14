import 'package:app_logging/app_logging.dart';
import 'package:film_archive/features/movie_timeline/data/datasources/movie_remote_data_source.dart';
import 'package:film_archive/features/movie_timeline/data/mappers/movie_detail_mapper.dart';
import 'package:film_archive/features/movie_timeline/data/mappers/movie_summary_mapper.dart';
import 'package:film_archive/features/movie_timeline/data/models/movie_summary_dto.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_detail.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_sort_option.dart';
import 'package:film_archive/features/movie_timeline/domain/entities/movie_summary.dart';
import 'package:film_archive/features/movie_timeline/domain/exceptions/movie_failure.dart';
import 'package:film_archive/features/movie_timeline/domain/repositories/movie_repository.dart';
import 'package:utils/utils.dart';

class MovieRepositoryImpl implements MovieRepository {
  MovieRepositoryImpl({required MovieRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final MovieRemoteDataSource _remoteDataSource;
  final _logger = AppLogger(tag: 'MovieRepository');

  @override
  Future<Result<List<MovieSummary>>> fetchTopMoviesByYearRange({
    required int startYear,
    required int endYear,
    required MovieSortOption sortOption,
  }) async {
    final timeline = <MovieSummary>[];
    for (var year = endYear; year >= startYear; year--) {
      final result = await _remoteDataSource.fetchTopMovieForYear(
        year,
        sortOption,
      );
      if (result is ErrorResult<MovieSummaryDto?>) {
        return ErrorResult(
          _asMovieFailure(result.failure),
        );
      }
      final dto = (result as Success<MovieSummaryDto?>).data;
      if (dto != null) {
        timeline.add(MovieSummaryMapper.toDomain(dto));
      }
    }
    return Success(timeline);
  }

  @override
  Future<Result<MovieDetail>> fetchMovieDetail(int movieId) async {
    final result = await _remoteDataSource.fetchMovieDetail(movieId);
    return result
        .map(MovieDetailMapper.toDomain)
        .mapError(_asMovieFailure);
  }

  MovieFailure _asMovieFailure(Failure failure) {
    _logger.error(
      '영화 데이터 요청 실패: ${failure.message}',
      error: failure.cause,
      stackTrace: failure.stackTrace,
    );
    return MovieFailure(
      message: failure.message ?? '영화 정보를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      code: failure.code,
      cause: failure.cause,
      stackTrace: failure.stackTrace,
    );
  }
}
