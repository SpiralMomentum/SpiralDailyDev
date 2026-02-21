import 'package:app_analytics/app_analytics.dart';
import 'package:flutter/material.dart';
import 'package:networking/networking.dart';

import 'package:film_archive/features/movie_timeline/data/datasources/movie_remote_data_source.dart';
import 'package:film_archive/features/movie_timeline/data/repositories/movie_repository_impl.dart';
import 'package:film_archive/features/movie_timeline/domain/repositories/movie_repository.dart';
import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_detail_use_case.dart';
import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_timeline_use_case.dart';
import 'package:film_archive/features/movie_timeline/presentation/timeline/movie_timeline_page.dart';

class FilmArchiveApp extends StatefulWidget {
  const FilmArchiveApp({super.key, required this.apiKey});

  final String apiKey;

  @override
  State<FilmArchiveApp> createState() => _FilmArchiveAppState();
}

class _FilmArchiveAppState extends State<FilmArchiveApp> {
  late final Dio _dio;
  late final DebugAnalyticsTracker _analyticsTracker;
  late final GetMovieDetailUseCase _getMovieDetailUseCase;
  late final GetMovieTimelineUseCase _getMovieTimelineUseCase;
  late final MovieRepository _repository;

  @override
  void initState() {
    super.initState();
    final dioOptions = NetworkOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      defaultHeaders: const {
        'Accept': 'application/json',
      },
      defaultQueryParameters: const {
        'language': 'ko-KR',
      },
      dynamicQueryParameters: () => {
        'api_key': widget.apiKey,
      },
    );
    _analyticsTracker = DebugAnalyticsTracker();
    _dio = DioProvider(options: dioOptions).create();
    final tmdbDataSource = TmdbDataSource(_dio);
    final movieRemoteDataSource =
        MovieRemoteDataSource(dataSource: tmdbDataSource);
    _repository = MovieRepositoryImpl(
      remoteDataSource: movieRemoteDataSource,
    );
    _getMovieDetailUseCase = GetMovieDetailUseCase(repository: _repository);
    _getMovieTimelineUseCase = GetMovieTimelineUseCase(repository: _repository);
  }

  @override
  void dispose() {
    _dio.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Film Archive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3D91)),
        useMaterial3: true,
      ),
      home: MovieTimelinePage(
        getMovieTimelineUseCase: _getMovieTimelineUseCase,
        getMovieDetailUseCase: _getMovieDetailUseCase,
        analyticsTracker: _analyticsTracker,
      ),
    );
  }
}
