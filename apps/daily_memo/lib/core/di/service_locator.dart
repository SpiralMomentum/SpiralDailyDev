import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/data/repository_impl/memo/memo_repository_impl.dart';
import 'package:apps.daily_memo/data/repository_interface/memo/memo_repository.dart';
import 'package:apps.daily_memo/data/sql_helper.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> setupLocatorSingleton() async {
    getIt
      ..registerLazySingleton<DatabaseHelper>(
              () => SQLHelper())
      ..registerLazySingleton<RoutesController>(
        () => GoRouterRoutesController(
          navigationType: GoRouterNavigationType.path,
          popAllStrategy: GoRouterPopAllStrategy.pushReplacement,
        ),
      )
      ..registerLazySingleton<MemoRepository>(
              () => MemoRepositoryImpl(getIt.get()))
    ;
  }

  static Future<void> setupLocatorFactory() async {
  }
}
