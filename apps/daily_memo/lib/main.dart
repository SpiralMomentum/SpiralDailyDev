import 'dart:async';

import 'package:app_logging/app_logging.dart';
import 'package:apps.daily_memo/app/app.dart';
import 'package:apps.daily_memo/app/app_bloc_observer.dart';
import 'package:apps.daily_memo/app/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final _logger = AppLogger(tag: 'Main');

void main() {
  Bloc.observer = const AppBlocObserver();

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    AppLogger.outputs = [
      const ConsoleLogOutput(),
      const CrashReportLogOutput(),
    ];

    FlutterError.onError = (details) {
      _logger.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    await ServiceLocator.setupLocatorSingleton();

    runApp(const App());
  }, (error, stack) {
    _logger.error('Unhandled error', error: error, stackTrace: stack);
  });
}
