import 'package:app_logging/app_logging.dart';
import 'package:networking/networking.dart' as networking;
import 'package:retrofit/dio.dart';
import 'package:utils/utils.dart';

import 'package:film_archive/features/movie_timeline/domain/entities/movie_sort_option.dart';
import '../models/discover_movie_response_dto.dart';
import '../models/movie_detail_dto.dart';
import '../models/movie_summary_dto.dart';

class MovieRemoteDataSource {
  MovieRemoteDataSource({required networking.TmdbDataSource dataSource})
      : _dataSource = dataSource;

  final networking.TmdbDataSource _dataSource;
  final _logger = AppLogger(tag: 'MovieRemoteDataSource');

  Future<Result<MovieSummaryDto?>> fetchTopMovieForYear(
    int year,
    MovieSortOption sortOption,
  ) async {
    final responseResult = await _safeRequest(
      () => _dataSource.fetchTopMovieForYear(
        sortBy: sortOption.sortQuery,
        year: year,
      ),
    );
    if (responseResult is networking.NetworkError<HttpResponse<dynamic>>) {
      return ErrorResult(
        _mapNetworkError(responseResult.error, StackTrace.current),
      );
    }
    return guard(
      action: () {
        final response =
            (responseResult as networking.NetworkSuccess<HttpResponse<dynamic>>)
                .data;
        final payload = _asJsonMap(response.data);
        final dto = DiscoverMovieResponseDto.fromJson(payload);
        if (dto.results.isEmpty) {
          return null;
        }
        return MovieSummaryDto.fromJson(dto.results.first, fallbackYear: year);
      },
      onError: _mapParsingFailure,
    );
  }

  Future<Result<MovieDetailDto>> fetchMovieDetail(int movieId) async {
    final responseResult = await _safeRequest(
      () => _dataSource.fetchMovieDetail(movieId: movieId),
    );
    if (responseResult is networking.NetworkError<HttpResponse<dynamic>>) {
      return ErrorResult(
        _mapNetworkError(responseResult.error, StackTrace.current),
      );
    }
    return guard(
      action: () {
        final response =
            (responseResult as networking.NetworkSuccess<HttpResponse<dynamic>>)
                .data;
        final payload = _asJsonMap(response.data);
        return MovieDetailDto.fromJson(payload);
      },
      onError: _mapParsingFailure,
    );
  }

  Future<networking.NetworkResult<HttpResponse<dynamic>>> _safeRequest(
    Future<HttpResponse<dynamic>> Function() call,
  ) async {
    return networking.NetworkExecutor.run(call);
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

  Failure _mapNetworkError(
    networking.NetworkException error,
    StackTrace stackTrace,
  ) {
    _logger.error(
      '네트워크 에러 [${error.failure.type.name}]: ${error.failure.message}',
      error: error,
      stackTrace: stackTrace,
    );
    if (error.failure.type == networking.NetworkFailureType.serialization) {
      return ParsingFailure(
        message: '응답을 해석하지 못했습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return NetworkFailure(
      message: _mapFailureMessage(error.failure),
      code: 'network.${error.failure.type.name}',
      cause: error,
      stackTrace: stackTrace,
    );
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

  String _mapFailureMessage(networking.NetworkFailure failure) {
    switch (failure.type) {
      case networking.NetworkFailureType.timeout:
        return '요청 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.';
      case networking.NetworkFailureType.noConnection:
        return '네트워크 연결을 확인한 뒤 다시 시도해주세요.';
      case networking.NetworkFailureType.unauthorized:
        return 'TMDb API 키가 유효하지 않습니다.';
      case networking.NetworkFailureType.forbidden:
        return '이 리소스에 접근할 권한이 없습니다.';
      case networking.NetworkFailureType.notFound:
        return '요청한 영화를 찾을 수 없습니다.';
      case networking.NetworkFailureType.server:
        return 'TMDb 서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case networking.NetworkFailureType.serialization:
      case networking.NetworkFailureType.client:
      case networking.NetworkFailureType.cancelled:
      case networking.NetworkFailureType.unknown:
        return failure.message ?? '영화 정보를 불러오지 못했습니다.';
    }
  }
}
