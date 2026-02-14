import 'dart:async';

import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';

import 'package:spiral_trade_show/app/trade_show_app.dart';

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
    () {
      runApp(
        const TradeShowApp(),
      );
    },
    (error, stackTrace) {
      logger.error(
        'Uncaught exception',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
