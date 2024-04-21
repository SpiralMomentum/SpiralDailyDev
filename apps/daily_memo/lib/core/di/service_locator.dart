import 'package:apps.daily_memo/core/route/routes_controller/routes_controller.dart';
import 'package:apps.daily_memo/core/route/routes_controller/routes_controller_go_router_impl.dart';
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
          () => RoutesControllerGoRouterImpl())
      ..registerLazySingleton<MemoRepository>(
              () => MemoRepositoryImpl(getIt.get()))
    ;
  }

  static Future<void> setupLocatorFactory() async {
  }
}
