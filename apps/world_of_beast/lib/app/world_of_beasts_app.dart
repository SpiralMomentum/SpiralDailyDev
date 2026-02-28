import 'package:flutter/material.dart';

import 'package:world_of_beast/app/di/service_locator.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_favorites_controller.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_list_view_model.dart';
import 'package:world_of_beast/features/monsters/presentation/views/world_of_beasts_home_page.dart';

class WorldOfBeastsApp extends StatelessWidget {
  const WorldOfBeastsApp({super.key});

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
        viewModel: getIt<MonsterListViewModel>(),
        favoritesController: getIt<MonsterFavoritesController>(),
      ),
    );
  }
}
