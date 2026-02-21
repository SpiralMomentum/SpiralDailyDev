import 'package:flutter/material.dart';

import 'package:world_of_beast/features/monsters/domain/entities/monster.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_favorites_controller.dart';
import 'package:world_of_beast/features/monsters/presentation/widgets/monster_card.dart';

/// 지도에서 국가 선택 시 표시되는 오버레이에 필요한 데이터.
class MapSelectionOverlayData {
  const MapSelectionOverlayData({
    required this.countryCode,
    required this.title,
    required this.monsters,
  });

  final String countryCode;
  final String title;
  final List<Monster> monsters;
}

/// 지도에서 국가를 선택했을 때 하단에 표시되는 몬스터 목록 오버레이.
class MapCountryOverlay extends StatelessWidget {
  const MapCountryOverlay({
    super.key,
    required this.data,
    required this.onClose,
    required this.favoritesController,
    this.onMonsterSelected,
  });

  final MapSelectionOverlayData data;
  final VoidCallback onClose;
  final MonsterFavoritesController favoritesController;
  final ValueChanged<Monster>? onMonsterSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      alignment: Alignment.bottomCenter,
      heightFactor: 0.85,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Material(
          key: const ValueKey('mapCountrySheet'),
          elevation: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          color: theme.scaffoldBackgroundColor,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.title,
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
                        key: const ValueKey('mapCountrySheetClose'),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: AnimatedBuilder(
                    animation: favoritesController,
                    builder: (context, _) {
                      return MonsterListBody(
                        monsters: data.monsters,
                        favoritesController: favoritesController,
                        onMonsterSelected: onMonsterSelected,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
