import 'package:app_analytics/app_analytics.dart';
import 'package:adage_spark/features/adage/data/datasources/adage_local_data_source.dart';
import 'package:adage_spark/features/adage/data/repositories/adage_repository_impl.dart';
import 'package:adage_spark/features/adage/domain/repositories/adage_repository.dart';
import 'package:adage_spark/features/adage/domain/usecases/add_adage_quote_use_case.dart';
import 'package:adage_spark/features/adage/domain/usecases/get_adage_quotes_use_case.dart';
import 'package:adage_spark/features/adage/presentation/adage_controller.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> setup() async {
    // External
    getIt.registerLazySingleton<AnalyticsTracker>(
      () => DebugAnalyticsTracker(),
    );

    // Data Sources
    getIt.registerLazySingleton<AdageLocalDataSource>(
      () => AdageLocalDataSource(),
    );

    // Repositories
    getIt.registerLazySingleton<AdageRepository>(
      () => AdageRepositoryImpl(localDataSource: getIt<AdageLocalDataSource>()),
    );

    // Use Cases
    getIt.registerLazySingleton<GetAdageQuotesUseCase>(
      () => GetAdageQuotesUseCase(repository: getIt<AdageRepository>()),
    );
    getIt.registerLazySingleton<AddAdageQuoteUseCase>(
      () => AddAdageQuoteUseCase(repository: getIt<AdageRepository>()),
    );

    // Presentation
    getIt.registerFactory<AdageController>(
      () => AdageController(
        getAdageQuotesUseCase: getIt<GetAdageQuotesUseCase>(),
        addAdageQuoteUseCase: getIt<AddAdageQuoteUseCase>(),
        analyticsTracker: getIt<AnalyticsTracker>(),
      ),
    );
  }
}
