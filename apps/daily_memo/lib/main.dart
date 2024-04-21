import 'dart:async';

import 'package:apps.daily_memo/app.dart';
import 'package:apps.daily_memo/app_bloc_observer.dart';
import 'package:apps.daily_memo/core/di/service_locator.dart';
import 'package:apps.daily_memo/data/repository_interface/memo/memo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void main() async {
  Bloc.observer = const AppBlocObserver();

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await ServiceLocator.setupLocatorSingleton();

    runApp(
      App(
        memoRepository: getIt.get<MemoRepository>(),
      ),
    );
  }, (error, stack) {});
}
