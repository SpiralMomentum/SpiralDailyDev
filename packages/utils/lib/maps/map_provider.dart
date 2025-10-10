import 'package:flutter/material.dart';

import 'map_marker.dart';
import 'map_marker_customizer.dart';

/// Supported provider identifiers.
enum MapProviderType { google, naver, amazon }

/// Parameters required to render a map.
class MapViewRequest {
  const MapViewRequest({
    required this.context,
    required this.markers,
    required this.markerCustomizer,
  });

  final BuildContext context;
  final List<MapMarker> markers;
  final MapMarkerCustomizer markerCustomizer;
}

/// Base contract for all map provider implementations.
abstract interface class MapProvider {
  MapProviderType get type;
  String get displayName;

  /// Allows the provider to perform async initialization.
  Future<void> initialize();

  /// Builds the map widget for the current provider.
  Widget buildMap(MapViewRequest request);
}

/// Simple placeholder used by the template implementations.
class MapProviderPlaceholder extends StatelessWidget {
  const MapProviderPlaceholder({
    super.key,
    required this.providerName,
    required this.markers,
    required this.markerCustomizer,
    required this.description,
  });

  final String providerName;
  final List<MapMarker> markers;
  final MapMarkerCustomizer markerCustomizer;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          providerName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: markers.isEmpty
              ? const Center(
                  child: Text('표시할 마커가 없습니다. 마커 설정을 추가하세요.'),
                )
              : ListView.separated(
                  itemBuilder: (context, index) {
                    final marker = markers[index];
                    return DecoratedBox(
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
                              child: markerCustomizer
                                  .buildMarkerDetail(context, marker),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemCount: markers.length,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
