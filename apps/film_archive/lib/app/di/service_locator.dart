import 'package:app_analytics/app_analytics.dart';
import 'package:film_archive/features/movie_timeline/data/datasources/movie_remote_data_source.dart';
import 'package:film_archive/features/movie_timeline/data/datasources/tmdb_data_source.dart';
import 'package:film_archive/features/movie_timeline/data/repositories/movie_repository_impl.dart';
import 'package:film_archive/features/movie_timeline/domain/repositories/movie_repository.dart';
import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_detail_use_case.dart';
import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_timeline_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:networking/networking.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> setup({required String apiKey}) async {
    // External
    getIt.registerLazySingleton<AnalyticsTracker>(
      () => DebugAnalyticsTracker(),
    );

    // Network
    final dioOptions = NetworkOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      defaultHeaders: const {'Accept': 'application/json'},
      defaultQueryParameters: const {'language': 'ko-KR'},
      dynamicQueryParameters: () => {'api_key': apiKey},
    );
    final dio = DioProvider(options: dioOptions).create();
    getIt.registerLazySingleton<Dio>(() => dio);

    // Data Sources
    getIt.registerLazySingleton<TmdbDataSource>(
      () => TmdbDataSource(getIt<Dio>()),
    );
    getIt.registerLazySingleton<MovieRemoteDataSource>(
      () => MovieRemoteDataSource(dataSource: getIt<TmdbDataSource>()),
    );

    // Repositories
    getIt.registerLazySingleton<MovieRepository>(
      () => MovieRepositoryImpl(remoteDataSource: getIt<MovieRemoteDataSource>()),
    );

    // Use Cases
    getIt.registerLazySingleton<GetMovieDetailUseCase>(
      () => GetMovieDetailUseCase(repository: getIt<MovieRepository>()),
    );
    getIt.registerLazySingleton<GetMovieTimelineUseCase>(
      () => GetMovieTimelineUseCase(repository: getIt<MovieRepository>()),
    );
  }
}
