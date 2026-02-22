import 'package:app_analytics/app_analytics.dart';
import 'package:get_it/get_it.dart';
import 'package:networking/networking.dart';
import 'package:spiral_trade_show/app/common/request_format.dart';
import 'package:spiral_trade_show/app/common/secure_file.dart';
import 'package:spiral_trade_show/features/info_shelf/data/datasources/info_shelf_remote_data_source.dart';
import 'package:spiral_trade_show/features/info_shelf/data/info_shelf_repository_impl.dart';
import 'package:spiral_trade_show/features/info_shelf/domain/info_shelf_repository.dart';
import 'package:spiral_trade_show/features/info_shelf/domain/info_shelf_use_case.dart';
import 'package:spiral_trade_show/features/info_shelf/external/remote/info_shelf_remote_data_source_impl.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> setup() async {
    // External
    getIt.registerLazySingleton<AnalyticsTracker>(
      () => DebugAnalyticsTracker(),
    );

    // Network
    final dio = DioProvider(
      options: const NetworkOptions(baseUrl: ''),
    ).create();
    getIt.registerLazySingleton<Dio>(() => dio);

    // Data Sources
    getIt.registerLazySingleton<InfoShelfRemoteDataSource>(
      () => InfoShelfRemoteDataSourceImpl(
        dio: getIt<Dio>(),
        baseUrl: 'http://openapi.seoul.go.kr:8088',
        serviceKey: SecureFile.serviceKey,
        format: RequestFormat.json,
        serviceName: SecureFile.serviceName,
      ),
    );

    // Repositories
    getIt.registerLazySingleton<InfoShelfRepository>(
      () => InfoShelfRepositoryImpl(getIt<InfoShelfRemoteDataSource>()),
    );

    // Use Cases
    getIt.registerLazySingleton<InfoShelfUseCase>(
      () => InfoShelfUseCase(getIt<InfoShelfRepository>()),
    );
  }
}
