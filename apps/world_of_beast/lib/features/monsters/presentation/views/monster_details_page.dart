import 'package:flutter/material.dart';

import 'package:world_of_beast/features/monsters/domain/entities/monster.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_favorites_controller.dart';

/// 몬스터 상세 정보를 표시하는 페이지.
class MonsterDetailsPage extends StatelessWidget {
  const MonsterDetailsPage({
    super.key,
    required this.monster,
    required this.favoritesController,
  });

  final Monster monster;
  final MonsterFavoritesController favoritesController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(monster.name),
        actions: [
          AnimatedBuilder(
            animation: favoritesController,
            builder: (context, _) {
              final isFavorite = favoritesController.isFavorite(monster.id);
              return IconButton(
                key: ValueKey('detailsFavorite_${monster.id}'),
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                tooltip: isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                onPressed: () => favoritesController.toggleFavorite(monster.id),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Country',
              style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ) ??
                  TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              monster.country,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              monster.shortDescription,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4) ??
                  const TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
