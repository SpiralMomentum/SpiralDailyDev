import 'package:flutter/material.dart';

import 'app/film_archive_app.dart';
import 'tmdb_api_key.dart';

final String _tmdbApiKey = tmdbApiKey.isNotEmpty
    ? tmdbApiKey
    : const String.fromEnvironment('TMDB_API_KEY');

void main() {
  runApp(FilmArchiveApp(apiKey: _tmdbApiKey));
}
