import 'dart:async';

import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';

import 'package:spiral_trade_show/app/di/service_locator.dart';
import 'package:spiral_trade_show/app/trade_show_app.dart';

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
    () {
      runApp(
        const TradeShowApp(),
      );
    },
    (error, stackTrace) {
      _logger.error(
        'Uncaught exception',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
