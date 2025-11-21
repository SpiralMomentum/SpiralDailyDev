import 'package:flutter/material.dart';
import 'package:world_map_widget/world_map_widget.dart';

import 'data/datasources/monsters_local_data_source.dart';
import 'data/repositories/monster_repository_impl.dart';
import 'domain/entities/monster.dart';
import 'domain/repositories/monster_repository.dart';
import 'domain/usecases/filter_monsters_by_country_use_case.dart';
import 'domain/usecases/get_monsters_use_case.dart';
import 'domain/usecases/sort_monsters_use_case.dart';
import 'presentation/viewmodels/monster_list_view_model.dart';

void main() {
  runApp(const WorldOfBeastsApp());
}

class WorldOfBeastsApp extends StatelessWidget {
  const WorldOfBeastsApp({super.key, this.repository});

  final MonsterRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'World of Beasts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3F6A)),
        useMaterial3: true,
      ),
      home: WorldOfBeastsHomePage(repository: repository),
    );
  }
}

class WorldOfBeastsHomePage extends StatefulWidget {
  const WorldOfBeastsHomePage({super.key, this.repository});

  final MonsterRepository? repository;

  @override
  State<WorldOfBeastsHomePage> createState() => _WorldOfBeastsHomePageState();
}

class _WorldOfBeastsHomePageState extends State<WorldOfBeastsHomePage> {
  late final MonsterListViewModel _viewModel;
  _MapSelectionOverlayData? _mapSelection;

  @override
  void initState() {
    super.initState();
    final repository =
        widget.repository ??
        MonsterRepositoryImpl(dataSource: const MonstersLocalDataSource());
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
    _viewModel.addListener(_handleViewModelChanged);
    _viewModel.loadMonsters();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('World of Beasts'),
        actions: [
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
      );
    }

    return Stack(
      children: [
        MonsterMapView(
          key: const ValueKey('monsterMapView'),
          caption: 'Tap any country to jump into its legendary monster list.',
          activeCountries: _viewModel.availableCountries,
          activeCountryColor: theme.colorScheme.primary,
          inactiveCountryColor: theme.colorScheme.surfaceVariant,
          onCountrySelected: _viewModel.canInteractWithMap
              ? _onCountryTap
              : null,
        ),
        if (_mapSelection != null)
          _MapCountryOverlay(data: _mapSelection!, onClose: _closeMapSelection),
      ],
    );
  }
}

class MonsterListView extends StatelessWidget {
  const MonsterListView({
    super.key,
    required this.header,
    required this.monsters,
  });

  final String header;
  final List<Monster> monsters;

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
            child: MonsterListBody(monsters: monsters),
          ),
        ],
      ),
    );
  }
}

class MonsterCard extends StatelessWidget {
  const MonsterCard({super.key, required this.monster});

  final Monster monster;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('monsterCard_${monster.id}'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monster.name,
              key: ValueKey('monsterName_${monster.id}'),
              style:
                  theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ) ??
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
  const MonsterListBody({super.key, required this.monsters});

  final List<Monster> monsters;

  @override
  Widget build(BuildContext context) {
    if (monsters.isEmpty) {
      return const _MonsterEmptyState();
    }
    return ListView.separated(
      key: const ValueKey('monsterCardsList'),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final monster = monsters[index];
        return MonsterCard(monster: monster);
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
  const _MapCountryOverlay({required this.data, required this.onClose});

  final _MapSelectionOverlayData data;
  final VoidCallback onClose;

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
                    color: theme.dividerColor.withOpacity(0.6),
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
                Expanded(child: MonsterListBody(monsters: data.monsters)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
