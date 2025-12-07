import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/movie_detail.dart';
import '../domain/entities/movie_sort_option.dart';
import '../domain/entities/movie_summary.dart';
import '../domain/exceptions.dart';

class MovieApiClient {
  MovieApiClient({
    required this.apiKey,
    required this.httpClient,
    this.language = 'ko-KR',
    this.baseUrl = 'https://api.themoviedb.org/3',
  });

  final String apiKey;
  final http.Client httpClient;
  final String language;
  final String baseUrl;

  Future<MovieSummary?> fetchTopMovieForYear(
    int year,
    MovieSortOption sortOption,
  ) async {
    final response = await _get(
      '/discover/movie',
      queryParameters: {
        'sort_by': sortOption.sortQuery,
        'primary_release_year': '$year',
        'include_adult': 'false',
        'include_video': 'false',
        'page': '1',
        'with_original_language': '',
      },
    );
    final results = response['results'] as List<dynamic>? ?? const [];
    if (results.isEmpty) {
      return null;
    }
    final first = results.first as Map<String, dynamic>;
    final overview = (first['overview'] as String? ?? '').trim();
    final releaseDate = (first['release_date'] as String? ?? '').trim();
    final parsedYear = _parseReleaseYear(releaseDate) ?? year;
    return MovieSummary(
      id: first['id'] as int,
      year: parsedYear,
      title: (first['title'] as String? ??
              first['name'] as String? ??
              '제목 미정')
          .trim(),
      overview: overview,
    );
  }

  Future<MovieDetail> fetchMovieDetail(int movieId) async {
    final response = await _get('/movie/$movieId');
    return MovieDetail.fromJson(response);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    if (apiKey.isEmpty) {
      throw MovieApiException(
        'TMDb API 키가 설정되지 않았습니다. '
        '--dart-define=TMDB_API_KEY=YOUR_KEY 로 설정해주세요.',
      );
    }

    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: {
        'api_key': apiKey,
        'language': language,
        ...?queryParameters,
      },
    );

    late http.Response response;
    try {
      response = await httpClient.get(uri).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw MovieApiException('요청 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.');
    } on Exception catch (error) {
      throw MovieApiException('영화 정보를 불러오지 못했습니다: $error');
    }

    if (response.statusCode != 200) {
      final message = _extractErrorMessage(response.body);
      throw MovieApiException(
        message ?? '영화 정보를 불러오는 중 오류가 발생했습니다.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw MovieApiException('알 수 없는 응답 형식입니다.');
    }
    return decoded;
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['status_message'] as String? ??
            decoded['message'] as String?;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

int? _parseReleaseYear(String date) {
  if (date.isEmpty || date.length < 4) {
    return null;
  }
  return int.tryParse(date.substring(0, 4));
}
