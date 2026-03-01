import 'dart:async';

import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';

import 'package:adage_spark/app/adage_spark_app.dart';
import 'package:adage_spark/app/di/service_locator.dart';

final _logger = AppLogger(tag: 'Main');

void main() async {
  AppLogger.outputs = [
    const ConsoleLogOutput(),
    const CrashReportLogOutput(),
  ];

  FlutterError.onError = (details) {
    _logger.error(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.setup();

  runZonedGuarded(
    () => runApp(const AdageSparkApp()),
    (error, stackTrace) {
      _logger.error(
        'Uncaught error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
