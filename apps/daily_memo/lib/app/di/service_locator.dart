import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/features/memo/data/datasources/memo_local_data_source.dart';
import 'package:apps.daily_memo/features/memo/data/repositories/memo_repository_impl.dart';
import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:apps.daily_memo/features/memo/external/local/sql_memo_local_data_source.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> setupLocatorSingleton() async {
    getIt
      ..registerLazySingleton<MemoLocalDataSource>(
        () => SqlMemoLocalDataSource(),
      )
      ..registerLazySingleton<RoutesController>(
        () => GoRouterRoutesController(
          navigationType: GoRouterNavigationType.path,
          popAllStrategy: GoRouterPopAllStrategy.pushReplacement,
        ),
      )
      ..registerLazySingleton<MemoRepository>(
        () => MemoRepositoryImpl(getIt.get()),
      );
  }

  static Future<void> setupLocatorFactory() async {}
}
