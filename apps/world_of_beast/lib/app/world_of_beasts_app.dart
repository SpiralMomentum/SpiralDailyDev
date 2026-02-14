import 'package:flutter/material.dart';

import 'package:world_of_beast/features/monsters/data/datasources/favorite_monsters_local_data_source.dart';
import 'package:world_of_beast/features/monsters/data/datasources/monsters_local_data_source.dart';
import 'package:world_of_beast/features/monsters/data/repositories/favorite_monsters_repository_impl.dart';
import 'package:world_of_beast/features/monsters/data/repositories/monster_repository_impl.dart';
import 'package:world_of_beast/features/monsters/domain/repositories/favorite_monsters_repository.dart';
import 'package:world_of_beast/features/monsters/domain/repositories/monster_repository.dart';
import 'package:world_of_beast/features/monsters/presentation/views/world_of_beasts_home_page.dart';

class WorldOfBeastsApp extends StatelessWidget {
  const WorldOfBeastsApp({
    super.key,
    this.repository,
    this.favoriteRepository,
  });

  final MonsterRepository? repository;
  final FavoriteMonstersRepository? favoriteRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'World of Beasts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3F6A)),
        useMaterial3: true,
      ),
      home: WorldOfBeastsHomePage(
        monsterRepository: repository ??
            MonsterRepositoryImpl(
              dataSource: MonstersLocalDataSource(),
            ),
        favoriteRepository: favoriteRepository ??
            FavoriteMonstersRepositoryImpl(
              dataSource: FavoriteMonstersLocalDataSource(),
            ),
      ),
    );
  }
}
