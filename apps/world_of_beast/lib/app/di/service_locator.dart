import 'package:app_analytics/app_analytics.dart';
import 'package:get_it/get_it.dart';

import 'package:world_of_beast/features/monsters/data/datasources/favorite_monsters_local_data_source.dart';
import 'package:world_of_beast/features/monsters/data/datasources/monsters_local_data_source.dart';
import 'package:world_of_beast/features/monsters/data/repositories/favorite_monsters_repository_impl.dart';
import 'package:world_of_beast/features/monsters/data/repositories/monster_repository_impl.dart';
import 'package:world_of_beast/features/monsters/domain/repositories/favorite_monsters_repository.dart';
import 'package:world_of_beast/features/monsters/domain/repositories/monster_repository.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/filter_monsters_by_country_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/get_monsters_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/load_favorite_monster_ids_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/save_favorite_monster_ids_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/sort_monsters_use_case.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_favorites_controller.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_list_view_model.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> setup() async {
    // External
    getIt.registerLazySingleton<AnalyticsTracker>(
      () => DebugAnalyticsTracker(),
    );

    // Data Sources
    getIt.registerLazySingleton<MonstersLocalDataSource>(
      () => MonstersLocalDataSource(),
    );
    getIt.registerLazySingleton<FavoriteMonstersLocalDataSource>(
      () => FavoriteMonstersLocalDataSource(),
    );

    // Repositories
    getIt.registerLazySingleton<MonsterRepository>(
      () => MonsterRepositoryImpl(
        dataSource: getIt<MonstersLocalDataSource>(),
      ),
    );
    getIt.registerLazySingleton<FavoriteMonstersRepository>(
      () => FavoriteMonstersRepositoryImpl(
        dataSource: getIt<FavoriteMonstersLocalDataSource>(),
      ),
    );

    // Use Cases
    getIt.registerLazySingleton<SortMonstersUseCase>(
      () => const SortMonstersUseCase(),
    );
    getIt.registerLazySingleton<GetMonstersUseCase>(
      () => GetMonstersUseCase(
        repository: getIt<MonsterRepository>(),
        sortMonsters: getIt<SortMonstersUseCase>(),
      ),
    );
    getIt.registerLazySingleton<FilterMonstersByCountryUseCase>(
      () => FilterMonstersByCountryUseCase(
        sortMonsters: getIt<SortMonstersUseCase>(),
      ),
    );
    getIt.registerLazySingleton<LoadFavoriteMonsterIdsUseCase>(
      () => LoadFavoriteMonsterIdsUseCase(
        repository: getIt<FavoriteMonstersRepository>(),
      ),
    );
    getIt.registerLazySingleton<SaveFavoriteMonsterIdsUseCase>(
      () => SaveFavoriteMonsterIdsUseCase(
        repository: getIt<FavoriteMonstersRepository>(),
      ),
    );

    // ViewModels / Controllers
    getIt.registerFactory<MonsterListViewModel>(
      () => MonsterListViewModel(
        getMonsters: getIt<GetMonstersUseCase>(),
        filterByCountry: getIt<FilterMonstersByCountryUseCase>(),
        analyticsTracker: getIt<AnalyticsTracker>(),
      ),
    );
    getIt.registerFactory<MonsterFavoritesController>(
      () => MonsterFavoritesController(
        loadFavorites: getIt<LoadFavoriteMonsterIdsUseCase>(),
        saveFavorites: getIt<SaveFavoriteMonsterIdsUseCase>(),
      ),
    );
  }
}
