import 'package:flutter/material.dart';

import 'map_marker.dart';
import 'map_marker_customizer.dart';

/// Supported provider identifiers.
enum MapProviderType { google, naver, amazon, openStreetMap }

/// Parameters required to render a map.
class MapViewRequest {
  const MapViewRequest({
    required this.context,
    required this.markers,
    required this.markerCustomizer,
    this.initialCenter,
    this.initialZoom,
  });

  final BuildContext context;
  final List<MapMarker> markers;
  final MapMarkerCustomizer markerCustomizer;
  final MapCoordinate? initialCenter;
  final double? initialZoom;
}

/// Bridge that exposes imperative operations for the rendered map.
abstract interface class MapProviderController {
  /// Notifies listeners when the user selects or focuses on a marker.
  ValueNotifier<MapMarker?> get selectedMarker;

  /// Moves the visible camera to the provided [position].
  Future<void> moveTo(
    MapCoordinate position, {
    double? zoom,
  });

  /// Replaces the markers currently rendered on the map.
  Future<void> setMarkers(List<MapMarker> markers);

  /// Asks the map to highlight the marker matching the provided [markerId].
  Future<void> highlightMarker(String markerId);

  /// Adjusts the camera so that all [markers] become visible.
  Future<void> fitBounds(List<MapMarker> markers);

  /// Cleans up resources when the controller is no longer required.
  void dispose();
}

/// Combination of the rendered map widget and its controller.
class MapProviderView {
  const MapProviderView({
    required this.map,
    required this.controller,
  });

  final Widget map;
  final MapProviderController controller;
}

/// Base contract for all map provider implementations.
abstract interface class MapProvider {
  MapProviderType get type;
  String get displayName;

  /// Allows the provider to perform async initialization.
  Future<void> initialize();

  /// Builds the map widget and supporting controller for the provider.
  MapProviderView buildView(MapViewRequest request);
}

/// Simple placeholder used by the template implementations.
class MapProviderPlaceholder extends StatelessWidget {
  const MapProviderPlaceholder({
    super.key,
    required this.providerName,
    required this.markersListenable,
    required this.markerCustomizer,
    required this.description,
  });

  final String providerName;
  final ValueListenable<List<MapMarker>> markersListenable;
  final MapMarkerCustomizer markerCustomizer;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<MapMarker>>(
      valueListenable: markersListenable,
      builder: (context, markers, _) {
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
                            color:
                                Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                markerCustomizer.buildMarker(
                                  context,
                                  marker,
                                ),
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
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
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
      },
    );
  }
}
