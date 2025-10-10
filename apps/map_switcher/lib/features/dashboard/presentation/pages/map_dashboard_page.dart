import 'package:app_navigation/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:utils/utils.dart';

import '../../../../app/map_switcher_dependencies.dart';

class MapDashboardPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지도 제공자 스위처'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: '제공자 목록 보기',
            onPressed: () => routesController.navigateTo(
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
            final activeProvider = registry.activeProvider;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      '현재 사용 중인 지도',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<MapProviderType>(
                      value: activeType,
                      items: [
                        for (final provider in providers)
                          DropdownMenuItem<MapProviderType>(
                            value: provider.type,
                            child: Text(provider.displayName),
                          ),
                      ],
                      onChanged: (value) async {
                        if (value == null) return;
                        await registry.switchTo(value);
                      },
                    ),
                    FilledButton.icon(
                      onPressed: () => routesController.navigateTo(
                        context,
                        MapSwitcherRoute.providers.path,
                      ),
                      icon: const Icon(Icons.list_alt),
                      label: const Text('제공자 둘러보기'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: activeProvider.buildMap(
                        MapViewRequest(
                          context: context,
                          markers: markers,
                          markerCustomizer: markerCustomizer,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
