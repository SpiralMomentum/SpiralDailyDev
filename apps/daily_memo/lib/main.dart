import 'dart:async';

import 'package:app_logging/app_logging.dart';
import 'package:apps.daily_memo/app/app.dart';
import 'package:apps.daily_memo/app/app_bloc_observer.dart';
import 'package:apps.daily_memo/app/di/service_locator.dart';
import 'package:apps.daily_memo/core/firebase/firebase_crash_reporter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';

final _logger = AppLogger(tag: 'Main');

void main() {
  Bloc.observer = const AppBlocObserver();

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    CrashReporter.instance = FirebaseCrashReporter();

    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      _logger.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    AppLogger.outputs = [
      const ConsoleLogOutput(),
      const CrashReportLogOutput(),
    ];

    await ServiceLocator.setupLocatorSingleton();

    runApp(const App());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    _logger.error('Unhandled error', error: error, stackTrace: stack);
  });
}
