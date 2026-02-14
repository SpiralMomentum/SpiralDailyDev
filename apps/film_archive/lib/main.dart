import 'dart:async';

import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';

import 'app/film_archive_app.dart';
import 'tmdb_api_key.dart';

final String _tmdbApiKey = tmdbApiKey;

final _logger = AppLogger(tag: 'Main');

void main() {
  AppLogger.outputs = [
    const ConsoleLogOutput(),
    const CrashReportLogOutput(),
  ];

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _logger.error(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runZonedGuarded(
    () {
      runApp(FilmArchiveApp(apiKey: _tmdbApiKey));
    },
    (error, stackTrace) {
      _logger.error(
        '처리되지 않은 예외 발생',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
