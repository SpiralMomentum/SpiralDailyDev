import 'package:app_analytics/app_analytics.dart';
import 'package:get_it/get_it.dart';
import 'package:world_field_guide/features/world_map/data/repositories/world_local_specialty_repository_impl.dart';
import 'package:world_field_guide/features/world_map/data/repositories/world_map_repository_impl.dart';
import 'package:world_field_guide/features/world_map/domain/repositories/world_local_specialty_repository.dart';
import 'package:world_field_guide/features/world_map/domain/repositories/world_map_repository.dart';
import 'package:world_field_guide/features/world_map/domain/usecases/get_country_specialties_use_case.dart';
import 'package:world_field_guide/features/world_map/domain/usecases/get_world_map_use_case.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static void setup() {
    // External
    getIt.registerLazySingleton<AnalyticsTracker>(
      () => DebugAnalyticsTracker(),
    );

    // Repositories
    getIt.registerLazySingleton<WorldMapRepository>(
      () => const WorldMapRepositoryImpl(),
    );
    getIt.registerLazySingleton<WorldLocalSpecialtyRepository>(
      () => const WorldLocalSpecialtyRepositoryImpl(),
    );

    // Use Cases
    getIt.registerLazySingleton<GetWorldMapUseCase>(
      () => GetWorldMapUseCase(repository: getIt<WorldMapRepository>()),
    );
    getIt.registerLazySingleton<GetCountrySpecialtiesUseCase>(
      () => GetCountrySpecialtiesUseCase(
        repository: getIt<WorldLocalSpecialtyRepository>(),
      ),
    );
  }
}
