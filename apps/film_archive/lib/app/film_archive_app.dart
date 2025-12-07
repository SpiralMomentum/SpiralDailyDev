import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/movie_api_client.dart';
import '../domain/repositories/movie_repository.dart';
import '../presentation/timeline/movie_timeline_page.dart';

class FilmArchiveApp extends StatefulWidget {
  const FilmArchiveApp({super.key, required this.apiKey});

  final String apiKey;

  @override
  State<FilmArchiveApp> createState() => _FilmArchiveAppState();
}

class _FilmArchiveAppState extends State<FilmArchiveApp> {
  late final http.Client _httpClient;
  late final MovieRepository _repository;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
    _repository = MovieRepository(
      apiClient: MovieApiClient(
        apiKey: widget.apiKey,
        httpClient: _httpClient,
      ),
    );
  }

  @override
  void dispose() {
    _httpClient.close();
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
      home: MovieTimelinePage(repository: _repository),
    );
  }
}
