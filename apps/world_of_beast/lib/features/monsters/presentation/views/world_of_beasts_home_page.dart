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
import 'package:world_of_beast/features/monsters/presentation/views/favorites_page.dart';
import 'package:world_of_beast/features/monsters/presentation/views/monster_details_page.dart';
import 'package:world_of_beast/features/monsters/presentation/widgets/monster_card.dart';
import 'package:world_of_beast/features/monsters/presentation/widgets/monster_list_view.dart';
import 'package:world_of_beast/features/monsters/presentation/widgets/monster_map_view.dart';

/// 앱의 메인 홈 페이지. 분리된 위젯들을 조합하는 scaffold 역할만 담당한다.
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
      return MonsterErrorState(
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
