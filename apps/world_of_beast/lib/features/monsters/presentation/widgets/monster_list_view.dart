import 'package:flutter/material.dart';

import 'package:world_of_beast/features/monsters/domain/entities/monster.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_favorites_controller.dart';
import 'package:world_of_beast/features/monsters/presentation/widgets/monster_card.dart';

/// 헤더와 함께 몬스터 카드 목록을 표시하는 리스트 뷰 위젯.
class MonsterListView extends StatelessWidget {
  const MonsterListView({
    super.key,
    required this.header,
    required this.monsters,
    required this.favoritesController,
    this.onMonsterSelected,
    this.emptyState,
  });

  final String header;
  final List<Monster> monsters;
  final MonsterFavoritesController favoritesController;
  final ValueChanged<Monster>? onMonsterSelected;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            header,
            key: const ValueKey('monsterListHeader'),
            style:
                theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ) ??
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: favoritesController,
              builder: (context, _) {
                return MonsterListBody(
                  monsters: monsters,
                  favoritesController: favoritesController,
                  onMonsterSelected: onMonsterSelected,
                  emptyState: emptyState,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
