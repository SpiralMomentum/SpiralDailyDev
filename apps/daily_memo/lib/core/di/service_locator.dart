import 'package:apps.daily_memo/data/repository_impl/memo/memo_repository_impl.dart';
import 'package:apps.daily_memo/data/repository_interface/memo/memo_repository.dart';
import 'package:apps.daily_memo/data/sql_helper.dart';
import 'package:core_di/core_di.dart';
import 'package:core_navigation/core_navigation.dart';

class ServiceLocator {
  static Future<void> setupLocatorSingleton() async {
    await registerDependencies([
      (getIt) async {
        getIt
          ..registerLazySingleton<DatabaseHelper>(() => SQLHelper())
          ..registerLazySingleton<RoutesController>(
            () => const GoRouterRoutesController(),
          )
          ..registerLazySingleton<MemoRepository>(
            () => MemoRepositoryImpl(getIt.get()),
          );
      },
    ]);
  }

  static Future<void> setupLocatorFactory() async {}
}
