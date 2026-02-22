import 'package:app_logging/app_logging.dart';
import 'package:networking/networking.dart';
import 'package:retrofit/dio.dart';

import 'package:film_archive/features/movie_timeline/domain/entities/movie_sort_option.dart';
import 'tmdb_data_source.dart';
import '../models/discover_movie_response_dto.dart';
import '../models/movie_detail_dto.dart';
import '../models/movie_summary_dto.dart';

class MovieRemoteDataSource {
  MovieRemoteDataSource({required TmdbDataSource dataSource})
      : _dataSource = dataSource;

  final TmdbDataSource _dataSource;
  final _logger = AppLogger(tag: 'MovieRemoteDataSource');

  Future<Result<MovieSummaryDto?>> fetchTopMovieForYear(
    int year,
    MovieSortOption sortOption,
  ) async {
    final responseResult = await NetworkExecutor.run(
      () => _dataSource.fetchTopMovieForYear(
        sortBy: sortOption.sortQuery,
        year: year,
      ),
    );
    return responseResult.when(
      success: (response) => guard(
        action: () {
          final payload = _asJsonMap(response.data);
          final dto = DiscoverMovieResponseDto.fromJson(payload);
          if (dto.results.isEmpty) {
            return null;
          }
          return MovieSummaryDto.fromJson(dto.results.first,
              fallbackYear: year);
        },
        onError: _mapParsingFailure,
      ),
      error: (failure) {
        _logNetworkFailure(failure);
        return ErrorResult(failure);
      },
    );
  }

  Future<Result<MovieDetailDto>> fetchMovieDetail(int movieId) async {
    final responseResult = await NetworkExecutor.run(
      () => _dataSource.fetchMovieDetail(movieId: movieId),
    );
    return responseResult.when(
      success: (response) => guard(
        action: () {
          final payload = _asJsonMap(response.data);
          return MovieDetailDto.fromJson(payload);
        },
        onError: _mapParsingFailure,
      ),
      error: (failure) {
        _logNetworkFailure(failure);
        return ErrorResult(failure);
      },
    );
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const FormatException('응답을 해석하지 못했습니다.');
  }

  void _logNetworkFailure(Failure failure) {
    if (failure is NetworkFailure) {
      _logger.error(
        '네트워크 에러 [${failure.type.name}]: ${failure.message}',
        error: failure.cause,
        stackTrace: failure.stackTrace,
      );
    }
  }

  Failure _mapParsingFailure(Object error, StackTrace stackTrace) {
    _logger.warning(
      '응답 파싱 실패',
      error: error,
      stackTrace: stackTrace,
    );
    return ParsingFailure(
      message: '응답을 해석하지 못했습니다.',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
