import 'dart:async';

import 'package:app_navigation/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:utils/utils.dart';

import '../../../../app/map_switcher_dependencies.dart';

class MapDashboardPage extends StatefulWidget {
  const MapDashboardPage({
    super.key,
    required this.registry,
    required this.markers,
    required this.markerCustomizer,
    required this.routesController,
  });

  final MapProviderRegistry registry;
  final List<MapMarker> markers;
  final MapMarkerCustomizer markerCustomizer;
  final RoutesController routesController;

  @override
  State<MapDashboardPage> createState() => _MapDashboardPageState();
}

class _MapDashboardPageState extends State<MapDashboardPage> {
  MapProviderController? _controller;
  MapMarker? _selectedMarker;
  String _searchQuery = '';

  List<MapMarker> get _filteredMarkers {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.markers;
    }
    return widget.markers.where((marker) {
      final values = <String?>[
        marker.id,
        marker.info?.title,
        marker.info?.place,
        marker.info?.description,
      ];
      return values.any(
        (value) => value != null && value.toLowerCase().contains(query),
      );
    }).toList();
  }

  Future<void> _moveToMarker(MapMarker marker) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    unawaited(controller.highlightMarker(marker.id));
    await controller.moveTo(marker.position, zoom: 15);
  }

  Future<void> _fitToAllMarkers() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.fitBounds(widget.markers);
  }

  void _handleControllerReady(MapProviderController controller) {
    setState(() {
      _controller = controller;
    });
  }

  void _handleMarkerSelected(MapMarker? marker) {
    setState(() {
      _selectedMarker = marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    final registry = widget.registry;

    return Scaffold(
      appBar: AppBar(
        title: const Text('지도 제공자 스위처'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: '제공자 목록 보기',
            onPressed: () => widget.routesController.navigateTo(
              context,
              MapSwitcherRoute.providers.path,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedBuilder(
          animation: registry,
          builder: (context, _) {
            final providers = registry.availableProviders;
            final activeType = registry.activeType;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 360,
                  child: _NavigationPanel(
                    providers: providers,
                    activeType: activeType,
                    onProviderSelected: (type) => registry.switchTo(type),
                    onBrowseProviders: () => widget.routesController.navigateTo(
                      context,
                      MapSwitcherRoute.providers.path,
                    ),
                    markers: _filteredMarkers,
                    markerCustomizer: widget.markerCustomizer,
                    selectedMarker: _selectedMarker,
                    onMarkerTap: _moveToMarker,
                    onSearchChanged: (value) => setState(() {
                      _searchQuery = value;
                    }),
                    onClearSelection: () {
                      final controller = _controller;
                      if (controller != null) {
                        controller.highlightMarker('');
                      }
                      setState(() => _selectedMarker = null);
                    },
                    onFitAllMarkers: _fitToAllMarkers,
                    isFiltering: _searchQuery.trim().isNotEmpty,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color:
                            Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _MapViewport(
                        registry: registry,
                        markers: widget.markers,
                        markerCustomizer: widget.markerCustomizer,
                        onControllerReady: _handleControllerReady,
                        onMarkerSelected: _handleMarkerSelected,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fitToAllMarkers,
        icon: const Icon(Icons.center_focus_strong),
        label: const Text('전체 영역 보기'),
      ),
    );
  }
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    required this.providers,
    required this.activeType,
    required this.onProviderSelected,
    required this.onBrowseProviders,
    required this.markers,
    required this.markerCustomizer,
    required this.selectedMarker,
    required this.onMarkerTap,
    required this.onSearchChanged,
    required this.onClearSelection,
    required this.onFitAllMarkers,
    required this.isFiltering,
  });

  final List<MapProvider> providers;
  final MapProviderType activeType;
  final ValueChanged<MapProviderType> onProviderSelected;
  final VoidCallback onBrowseProviders;
  final List<MapMarker> markers;
  final MapMarkerCustomizer markerCustomizer;
  final MapMarker? selectedMarker;
  final ValueChanged<MapMarker> onMarkerTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSelection;
  final Future<void> Function() onFitAllMarkers;
  final bool isFiltering;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '지도 제어',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MapProviderType>(
            value: activeType,
            decoration: const InputDecoration(
              labelText: '활성 지도 제공자',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final provider in providers)
                DropdownMenuItem(
                  value: provider.type,
                  child: Text(provider.displayName),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                onProviderSelected(value);
              }
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onBrowseProviders,
            icon: const Icon(Icons.list_alt),
            label: const Text('제공자 둘러보기'),
          ),
          const Divider(height: 32),
          Text(
            '위치 탐색',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: '지점 이름, 설명, 주소 검색',
              border: OutlineInputBorder(),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onFitAllMarkers,
            icon: const Icon(Icons.zoom_out_map),
            label: const Text('모든 지점 보기'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: markers.isEmpty
                ? Center(
                    child: Text(
                      isFiltering
                          ? '검색 결과가 없습니다.'
                          : '등록된 위치가 없습니다.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final marker in markers)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MarkerListTile(
                              marker: marker,
                              markerCustomizer: markerCustomizer,
                              onTap: () => onMarkerTap(marker),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          if (selectedMarker != null) ...[
            const Divider(height: 32),
            Row(
              children: [
                Text(
                  '선택된 위치',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: '선택 해제',
                  onPressed: onClearSelection,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: SingleChildScrollView(
                child:
                    markerCustomizer.buildMarkerDetail(context, selectedMarker!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarkerListTile extends StatelessWidget {
  const _MarkerListTile({
    required this.marker,
    required this.markerCustomizer,
    required this.onTap,
  });

  final MapMarker marker;
  final MapMarkerCustomizer markerCustomizer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              markerCustomizer.buildMarker(context, marker),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.info?.title ?? marker.id,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (marker.info?.place != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        marker.info!.place,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (marker.info?.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        marker.info!.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapViewport extends StatefulWidget {
  const _MapViewport({
    required this.registry,
    required this.markers,
    required this.markerCustomizer,
    this.onControllerReady,
    this.onMarkerSelected,
  });

  final MapProviderRegistry registry;
  final List<MapMarker> markers;
  final MapMarkerCustomizer markerCustomizer;
  final ValueChanged<MapProviderController>? onControllerReady;
  final ValueChanged<MapMarker?>? onMarkerSelected;

  @override
  State<_MapViewport> createState() => _MapViewportState();
}

class _MapViewportState extends State<_MapViewport> {
  MapProviderType? _activeType;
  MapProviderView? _view;
  VoidCallback? _selectionListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _buildView();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _MapViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeType = widget.registry.activeType;
    if (_activeType != activeType) {
      _buildView();
    } else {
      final controller = _view?.controller;
      if (controller != null) {
        controller.setMarkers(widget.markers);
      }
    }
  }

  @override
  void dispose() {
    _detachSelectionListener();
    _view?.controller.dispose();
    super.dispose();
  }

  Future<void> _buildView() async {
    _detachSelectionListener();
    _view?.controller.dispose();

    final provider = widget.registry.activeProvider;
    final view = provider.buildView(
      MapViewRequest(
        context: context,
        markers: widget.markers,
        markerCustomizer: widget.markerCustomizer,
        initialCenter: widget.markers.isNotEmpty
            ? widget.markers.first.position
            : null,
        initialZoom: 13,
      ),
    );
    await view.controller.setMarkers(widget.markers);

    if (!mounted) {
      view.controller.dispose();
      return;
    }

    setState(() {
      _view = view;
      _activeType = provider.type;
    });

    widget.onControllerReady?.call(view.controller);
    _attachSelectionListener(view.controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _view?.controller != view.controller) {
        return;
      }
      unawaited(view.controller.fitBounds(widget.markers));
    });
  }

  void _attachSelectionListener(MapProviderController controller) {
    _selectionListener = () {
      widget.onMarkerSelected?.call(controller.selectedMarker.value);
    };
    controller.selectedMarker.addListener(_selectionListener!);
    widget.onMarkerSelected?.call(controller.selectedMarker.value);
  }

  void _detachSelectionListener() {
    final listener = _selectionListener;
    final controller = _view?.controller;
    if (listener != null && controller != null) {
      controller.selectedMarker.removeListener(listener);
    }
    _selectionListener = null;
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    if (view == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return view.map;
  }
}
