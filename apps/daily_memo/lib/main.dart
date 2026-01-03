import 'dart:async';

import 'package:apps.daily_memo/app/app.dart';
import 'package:apps.daily_memo/app/app_bloc_observer.dart';
import 'package:apps.daily_memo/app/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  Bloc.observer = const AppBlocObserver();

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await ServiceLocator.setupLocatorSingleton();

    runApp(const App());
  }, (error, stack) {});
}
