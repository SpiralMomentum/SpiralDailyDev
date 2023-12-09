import 'dart:async';

import 'package:apps.daily_memo/app.dart';
import 'package:apps.daily_memo/app_bloc_observer.dart';
import 'package:apps.daily_memo/data/repository_impl/memo/memo_repository_impl.dart';
import 'package:apps.daily_memo/data/repository_interface/memo/memo_repository.dart';
import 'package:apps.daily_memo/data/sql_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  Bloc.observer = const AppBlocObserver();

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // TODO: check dependency injection library
    final DatabaseHelper databaseHelper = SQLHelper();
    final MemoRepository memoRepository = MemoRepositoryImpl(databaseHelper);

    runApp(App(memoRepository: memoRepository));
  }, (error, stack) {});
}
