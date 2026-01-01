import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'tmdb_data_source.g.dart';

@RestApi()
abstract class TmdbDataSource {
  factory TmdbDataSource(Dio dio, {String baseUrl}) = _TmdbDataSource;

  @GET('/discover/movie')
  Future<HttpResponse<dynamic>> fetchTopMovieForYear({
    @Query('sort_by') required String sortBy,
    @Query('primary_release_year') required int year,
    @Query('include_adult') bool includeAdult = false,
    @Query('include_video') bool includeVideo = false,
    @Query('page') int page = 1,
    @Query('with_original_language') String originalLanguage = '',
  });

  @GET('/movie/{movieId}')
  Future<HttpResponse<dynamic>> fetchMovieDetail({
    @Path('movieId') required int movieId,
  });
}
