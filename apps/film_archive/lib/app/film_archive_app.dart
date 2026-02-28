import 'package:app_analytics/app_analytics.dart';
import 'package:film_archive/app/di/service_locator.dart';
import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_detail_use_case.dart';
import 'package:film_archive/features/movie_timeline/domain/usecases/get_movie_timeline_use_case.dart';
import 'package:film_archive/features/movie_timeline/presentation/timeline/movie_timeline_page.dart';
import 'package:flutter/material.dart';

class FilmArchiveApp extends StatelessWidget {
  const FilmArchiveApp({super.key});

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
        getMovieTimelineUseCase: getIt<GetMovieTimelineUseCase>(),
        getMovieDetailUseCase: getIt<GetMovieDetailUseCase>(),
        analyticsTracker: getIt<AnalyticsTracker>(),
      ),
    );
  }
}
