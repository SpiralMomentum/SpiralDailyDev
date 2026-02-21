import 'dart:async';

import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';

import 'package:world_of_beast/app/world_of_beasts_app.dart';
export 'package:world_of_beast/app/world_of_beasts_app.dart';

final _logger = AppLogger(tag: 'Main');

void main() {
  AppLogger.outputs = [
    const ConsoleLogOutput(),
    const CrashReportLogOutput(),
  ];

  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        _logger.error(
          'FlutterError: ${details.exceptionAsString()}',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      runApp(WorldOfBeastsApp());
    },
    (error, stackTrace) {
      _logger.error(
        'Uncaught error: $error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
