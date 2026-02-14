import 'dart:async';

import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';

import 'package:adage_spark/app/adage_spark_app.dart';

void main() {
  AppLogger.outputs = [
    const ConsoleLogOutput(),
    const CrashReportLogOutput(),
  ];

  final logger = AppLogger(tag: 'Main');

  FlutterError.onError = (details) {
    logger.error(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runZonedGuarded(
    () => runApp(const AdageSparkApp()),
    (error, stackTrace) {
      logger.error(
        'Uncaught error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
