import 'dart:async';

import 'package:flutter/material.dart';
import 'package:world_map_widget/world_map_widget.dart';

import 'package:world_of_beast/features/monsters/domain/entities/monster.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_favorites_controller.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_list_view_model.dart';
import 'package:world_of_beast/features/monsters/presentation/views/favorites_page.dart';
import 'package:world_of_beast/features/monsters/presentation/views/monster_details_page.dart';
import 'package:world_of_beast/features/monsters/presentation/views/widgets/map_country_overlay.dart';
import 'package:world_of_beast/features/monsters/presentation/widgets/monster_card.dart';
import 'package:world_of_beast/features/monsters/presentation/widgets/monster_list_view.dart';
import 'package:world_of_beast/features/monsters/presentation/widgets/monster_map_view.dart';

/// The main home page of the app. Acts as a scaffold that composes separated widgets.
class WorldOfBeastsHomePage extends StatefulWidget {
  const WorldOfBeastsHomePage({
    super.key,
    required this.viewModel,
    required this.favoritesController,
  });

  final MonsterListViewModel viewModel;
  final MonsterFavoritesController favoritesController;

  @override
  State<WorldOfBeastsHomePage> createState() => _WorldOfBeastsHomePageState();
}

class _WorldOfBeastsHomePageState extends State<WorldOfBeastsHomePage> {
  late final MonsterListViewModel _viewModel;
  late final MonsterFavoritesController _favoritesController;
  MapSelectionOverlayData? _mapSelection;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel;
    _favoritesController = widget.favoritesController;
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
      _mapSelection = MapSelectionOverlayData(
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
          MapCountryOverlay(
            data: _mapSelection!,
            onClose: _closeMapSelection,
            favoritesController: _favoritesController,
            onMonsterSelected: _openMonsterDetails,
          ),
      ],
    );
  }
}
