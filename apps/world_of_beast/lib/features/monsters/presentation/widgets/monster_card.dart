import 'package:flutter/material.dart';

import 'package:world_of_beast/features/monsters/domain/entities/monster.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_favorites_controller.dart';

/// 몬스터 정보를 표시하는 카드 위젯.
class MonsterCard extends StatelessWidget {
  const MonsterCard({
    super.key,
    required this.monster,
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.onTap,
  });

  final Monster monster;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(16);
    return Card(
      key: ValueKey('monsterCard_${monster.id}'),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      monster.name,
                      key: ValueKey('monsterName_${monster.id}'),
                      style:
                          theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ) ??
                          const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('favoriteToggle_${monster.id}'),
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite
                          ? theme.colorScheme.secondary
                          : theme.iconTheme.color,
                    ),
                    tooltip: isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    onPressed: onFavoriteToggle,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                monster.shortDescription,
                key: ValueKey('monsterDescription_${monster.id}'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    theme.textTheme.bodyMedium ??
                    const TextStyle(fontSize: 16, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 몬스터 목록 본문 위젯. 카드 리스트 또는 빈 상태를 표시한다.
class MonsterListBody extends StatelessWidget {
  const MonsterListBody({
    super.key,
    required this.monsters,
    required this.favoritesController,
    this.onMonsterSelected,
    this.emptyState,
  });

  final List<Monster> monsters;
  final MonsterFavoritesController favoritesController;
  final ValueChanged<Monster>? onMonsterSelected;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    if (monsters.isEmpty) {
      return emptyState ?? const MonsterEmptyState();
    }
    return ListView.separated(
      key: const ValueKey('monsterCardsList'),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final monster = monsters[index];
        return MonsterCard(
          monster: monster,
          isFavorite: favoritesController.isFavorite(monster.id),
          onFavoriteToggle: () {
            favoritesController.toggleFavorite(monster.id);
          },
          onTap: onMonsterSelected == null
              ? null
              : () => onMonsterSelected!(monster),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: monsters.length,
    );
  }
}

/// 몬스터가 없을 때 표시하는 빈 상태 위젯.
class MonsterEmptyState extends StatelessWidget {
  const MonsterEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'No monsters found for this country.',
        key: const ValueKey('monsterEmptyState'),
        style: theme.textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 오류 발생 시 재시도 버튼과 함께 표시하는 위젯.
class MonsterErrorState extends StatelessWidget {
  const MonsterErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
