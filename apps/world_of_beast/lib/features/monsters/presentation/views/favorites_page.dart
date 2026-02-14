import 'package:flutter/material.dart';

import 'package:world_of_beast/features/monsters/domain/entities/monster.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_favorites_controller.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_list_view_model.dart';
import 'package:world_of_beast/features/monsters/presentation/widgets/monster_card.dart';

/// 즐겨찾기한 몬스터 목록을 표시하는 페이지.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    super.key,
    required this.viewModel,
    required this.favoritesController,
    required this.onMonsterSelected,
  });

  final MonsterListViewModel viewModel;
  final MonsterFavoritesController favoritesController;
  final ValueChanged<Monster> onMonsterSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Monsters'),
      ),
      body: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (viewModel.errorMessage != null) {
            return MonsterErrorState(
              message: viewModel.errorMessage!,
              onRetry: viewModel.retry,
            );
          }
          return AnimatedBuilder(
            animation: favoritesController,
            builder: (context, __) {
              final favorites =
                  favoritesController.filterFavorites(viewModel.allMonsters);
              final theme = Theme.of(context);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Favorite Monsters',
                      style:
                          theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ) ??
                          const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: MonsterListBody(
                        monsters: favorites,
                        favoritesController: favoritesController,
                        onMonsterSelected: onMonsterSelected,
                        emptyState: const _FavoritesEmptyState(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        '즐겨찾기한 괴물이 없습니다',
        key: const ValueKey('favoritesEmptyState'),
        style: theme.textTheme.bodyLarge,
      ),
    );
  }
}
