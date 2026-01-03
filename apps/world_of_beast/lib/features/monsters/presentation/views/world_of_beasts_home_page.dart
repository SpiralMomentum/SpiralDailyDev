import 'dart:async';

import 'package:flutter/material.dart';
import 'package:world_map_widget/world_map_widget.dart';

import 'package:world_of_beast/features/monsters/domain/entities/monster.dart';
import 'package:world_of_beast/features/monsters/domain/repositories/favorite_monsters_repository.dart';
import 'package:world_of_beast/features/monsters/domain/repositories/monster_repository.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/filter_monsters_by_country_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/get_monsters_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/load_favorite_monster_ids_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/save_favorite_monster_ids_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/sort_monsters_use_case.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_favorites_controller.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_list_view_model.dart';

class WorldOfBeastsHomePage extends StatefulWidget {
  const WorldOfBeastsHomePage({
    super.key,
    required this.monsterRepository,
    required this.favoriteRepository,
  });

  final MonsterRepository monsterRepository;
  final FavoriteMonstersRepository favoriteRepository;

  @override
  State<WorldOfBeastsHomePage> createState() => _WorldOfBeastsHomePageState();
}

class _WorldOfBeastsHomePageState extends State<WorldOfBeastsHomePage> {
  late final MonsterListViewModel _viewModel;
  late final MonsterFavoritesController _favoritesController;
  _MapSelectionOverlayData? _mapSelection;

  @override
  void initState() {
    super.initState();
    final repository = widget.monsterRepository;
    final favoriteRepository = widget.favoriteRepository;
    const sortUseCase = SortMonstersUseCase();
    _viewModel = MonsterListViewModel(
      getMonsters: GetMonstersUseCase(
        repository: repository,
        sortMonsters: sortUseCase,
      ),
      filterByCountry: FilterMonstersByCountryUseCase(
        sortMonsters: sortUseCase,
      ),
    );
    _favoritesController = MonsterFavoritesController(
      loadFavorites: LoadFavoriteMonsterIdsUseCase(
        repository: favoriteRepository,
      ),
      saveFavorites: SaveFavoriteMonsterIdsUseCase(
        repository: favoriteRepository,
      ),
    );
    unawaited(_favoritesController.initialize());
    _viewModel.addListener(_handleViewModelChanged);
    _viewModel.loadMonsters();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    _favoritesController.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!mounted) return;
    if (!_viewModel.isLoading && _viewModel.errorMessage == null) {
      final validIds = _viewModel.allMonsters
          .map((monster) => monster.id)
          .toSet();
      unawaited(_favoritesController.pruneUnknownFavorites(validIds));
    }
    setState(() {
      if (_viewModel.viewMode == ViewMode.list) {
        _mapSelection = null;
      }
    });
  }

  void _onCountryTap(WorldCountryTapDetails details) {
    final normalizedCode = details.countryId.toUpperCase();
    final monsters = _viewModel.monstersForCountry(normalizedCode);
    if (monsters.isEmpty) {
      return;
    }
    final title = _viewModel.titleForCountry(
      normalizedCode,
      fallbackName: details.countryName,
    );
    setState(() {
      _mapSelection = _MapSelectionOverlayData(
        countryCode: normalizedCode,
        title: title,
        monsters: monsters,
      );
    });
  }

  void _closeMapSelection() {
    if (_mapSelection == null) {
      return;
    }
    setState(() {
      _mapSelection = null;
    });
  }

  Future<void> _openMonsterDetails(Monster monster) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MonsterDetailsPage(
          monster: monster,
          favoritesController: _favoritesController,
        ),
      ),
    );
  }

  void _openFavoritesPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FavoritesPage(
          viewModel: _viewModel,
          favoritesController: _favoritesController,
          onMonsterSelected: _openMonsterDetails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('World of Beasts'),
        actions: [
          AnimatedBuilder(
            animation: _favoritesController,
            builder: (context, _) {
              final hasFavorites = _favoritesController.favoriteIds.isNotEmpty;
              return IconButton(
                key: const ValueKey('favoritesButton'),
                icon: Icon(
                  hasFavorites ? Icons.star : Icons.star_border,
                ),
                tooltip: 'View favorites',
                onPressed: _openFavoritesPage,
              );
            },
          ),
          IconButton(
            key: const ValueKey('viewToggleButton'),
            icon: Icon(
              _viewModel.viewMode == ViewMode.list ? Icons.public : Icons.list,
            ),
            tooltip: _viewModel.viewMode == ViewMode.list
                ? 'View map'
                : 'View list',
            onPressed: _viewModel.canToggleView
                ? () {
                    _closeMapSelection();
                    _viewModel.toggleViewMode();
                  }
                : null,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    if (_viewModel.isLoading) {
      return const Center(
        key: ValueKey('monsterLoadingState'),
        child: CircularProgressIndicator(),
      );
    }

    if (_viewModel.errorMessage != null) {
      return _MonsterErrorState(
        key: const ValueKey('monsterErrorState'),
        message: _viewModel.errorMessage!,
        onRetry: _viewModel.retry,
      );
    }

    if (_viewModel.viewMode == ViewMode.list) {
      return MonsterListView(
        key: const ValueKey('monsterListView'),
        header: _viewModel.headerTitle,
        monsters: _viewModel.visibleMonsters,
        favoritesController: _favoritesController,
        onMonsterSelected: _openMonsterDetails,
      );
    }

    return Stack(
      children: [
        MonsterMapView(
          key: const ValueKey('monsterMapView'),
          caption: 'Tap any country to jump into its legendary monster list.',
          activeCountries: _viewModel.availableCountries,
          activeCountryColor: theme.colorScheme.primary,
          inactiveCountryColor: theme.colorScheme.surfaceContainerHighest,
          onCountrySelected: _viewModel.canInteractWithMap
              ? _onCountryTap
              : null,
        ),
        if (_mapSelection != null)
          _MapCountryOverlay(
            data: _mapSelection!,
            onClose: _closeMapSelection,
            favoritesController: _favoritesController,
            onMonsterSelected: _openMonsterDetails,
          ),
      ],
    );
  }
}

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

class _MonsterEmptyState extends StatelessWidget {
  const _MonsterEmptyState();

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
      return emptyState ?? const _MonsterEmptyState();
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

class _MonsterErrorState extends StatelessWidget {
  const _MonsterErrorState({
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

class MonsterMapView extends StatelessWidget {
  const MonsterMapView({
    super.key,
    required this.caption,
    required this.activeCountries,
    required this.activeCountryColor,
    required this.inactiveCountryColor,
    this.onCountrySelected,
  });

  final String caption;
  final Set<String> activeCountries;
  final Color activeCountryColor;
  final Color inactiveCountryColor;
  final CountryTapCallback? onCountrySelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: WorldMapWidget(
              key: const ValueKey('worldMapWidget'),
              caption: caption,
              mapColor: inactiveCountryColor,
              countryColors: _buildCountryColors(),
              onCountryTap: onCountrySelected == null
                  ? null
                  : (details) => _handleCountryTap(details),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color>? _buildCountryColors() {
    if (activeCountries.isEmpty) {
      return null;
    }
    return {
      for (final code in activeCountries)
        code.toLowerCase(): activeCountryColor,
    };
  }

  void _handleCountryTap(WorldCountryTapDetails details) {
    final normalized = details.countryId.toUpperCase();
    if (!activeCountries.contains(normalized)) {
      return;
    }
    onCountrySelected?.call(details);
  }
}

class _MapSelectionOverlayData {
  const _MapSelectionOverlayData({
    required this.countryCode,
    required this.title,
    required this.monsters,
  });

  final String countryCode;
  final String title;
  final List<Monster> monsters;
}

class _MapCountryOverlay extends StatelessWidget {
  const _MapCountryOverlay({
    required this.data,
    required this.onClose,
    required this.favoritesController,
    this.onMonsterSelected,
  });

  final _MapSelectionOverlayData data;
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
            return _MonsterErrorState(
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
