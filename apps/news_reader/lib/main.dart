import 'dart:async';

import 'package:apps.news_reader/app/app.dart';
import 'package:apps.news_reader/app/di/service_locator.dart';
import 'package:flutter/material.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    await ServiceLocator.setupLocatorSingleton();

    runApp(const App());
  }, (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
  });
}
