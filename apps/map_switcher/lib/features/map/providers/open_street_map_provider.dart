import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:utils/utils.dart';

class OpenStreetMapProvider implements MapProvider {
  OpenStreetMapProvider()
      : _controller = MapController(),
        _markers = ValueNotifier<List<MapMarker>>(<MapMarker>[]),
        _selectedMarker = ValueNotifier<MapMarker?>(null);

  final MapController _controller;
  final ValueNotifier<List<MapMarker>> _markers;
  final ValueNotifier<MapMarker?> _selectedMarker;

  @override
  MapProviderType get type => MapProviderType.openStreetMap;

  @override
  String get displayName => 'OpenStreetMap';

  @override
  Future<void> initialize() async {}

  @override
  MapProviderView buildView(MapViewRequest request) {
    return MapProviderView(
      map: _OpenStreetMapView(
        controller: _controller,
        markers: _markers,
        selectedMarker: _selectedMarker,
        request: request,
      ),
      controller: _OpenStreetMapController(
        mapController: _controller,
        markers: _markers,
        selectedMarker: _selectedMarker,
      ),
    );
  }
}

class _OpenStreetMapController implements MapProviderController {
  _OpenStreetMapController({
    required MapController mapController,
    required ValueNotifier<List<MapMarker>> markers,
    required ValueNotifier<MapMarker?> selectedMarker,
  })  : _mapController = mapController,
        _markers = markers,
        _selectedMarker = selectedMarker;

  final MapController _mapController;
  final ValueNotifier<List<MapMarker>> _markers;
  final ValueNotifier<MapMarker?> _selectedMarker;

  @override
  ValueNotifier<MapMarker?> get selectedMarker => _selectedMarker;

  @override
  Future<void> moveTo(MapCoordinate position, {double? zoom}) async {
    final point = LatLng(position.latitude, position.longitude);
    final targetZoom = zoom ?? _mapController.zoom;
    _mapController.move(point, targetZoom);
  }

  @override
  Future<void> setMarkers(List<MapMarker> markers) async {
    _markers.value = List<MapMarker>.unmodifiable(markers);
  }

  @override
  Future<void> highlightMarker(String markerId) async {
    if (markerId.isEmpty) {
      _selectedMarker.value = null;
      return;
    }
    _selectedMarker.value =
        _markers.value.firstWhereOrNull((marker) => marker.id == markerId);
  }

  @override
  Future<void> fitBounds(List<MapMarker> markers) async {
    if (markers.isEmpty) {
      return;
    }
    if (markers.length == 1) {
      await moveTo(markers.first.position, zoom: 14);
      return;
    }
    final bounds = LatLngBounds.fromPoints(
      markers
          .map((marker) => LatLng(
                marker.position.latitude,
                marker.position.longitude,
              ))
          .toList(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitBounds(
        bounds,
        options: const FitBoundsOptions(padding: EdgeInsets.all(48)),
      );
    });
  }

  @override
  void dispose() {
    _markers.dispose();
    _selectedMarker.dispose();
  }
}

class _OpenStreetMapView extends StatefulWidget {
  const _OpenStreetMapView({
    required this.controller,
    required this.markers,
    required this.selectedMarker,
    required this.request,
  });

  final MapController controller;
  final ValueNotifier<List<MapMarker>> markers;
  final ValueNotifier<MapMarker?> selectedMarker;
  final MapViewRequest request;

  @override
  State<_OpenStreetMapView> createState() => _OpenStreetMapViewState();
}

class _OpenStreetMapViewState extends State<_OpenStreetMapView> {
  late final MapController _controller = widget.controller;

  @override
  Widget build(BuildContext context) {
    final initialPosition = widget.request.initialCenter ??
        (widget.markers.value.isNotEmpty
            ? widget.markers.value.first.position
            : const MapCoordinate(latitude: 37.5665, longitude: 126.9780));
    final initialZoom = widget.request.initialZoom ?? 12.0;

    return Stack(
      children: [
        ValueListenableBuilder<List<MapMarker>>(
          valueListenable: widget.markers,
          builder: (context, markers, _) {
            return FlutterMap(
              mapController: _controller,
              options: MapOptions(
                center: LatLng(
                  initialPosition.latitude,
                  initialPosition.longitude,
                ),
                zoom: initialZoom,
                interactiveFlags: InteractiveFlag.all,
                onTap: (_, __) => widget.selectedMarker.value = null,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.spiraldev.map_switcher',
                  retinaMode: true,
                ),
                MarkerLayer(
                  markers: [
                    for (final marker in markers)
                      Marker(
                        point: LatLng(
                          marker.position.latitude,
                          marker.position.longitude,
                        ),
                        width: 120,
                        height: 120,
                        builder: (context) => GestureDetector(
                          onTap: () => widget.selectedMarker.value = marker,
                          child: marker.icon ??
                              widget.request.markerCustomizer
                                  .buildMarker(context, marker),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: ValueListenableBuilder<MapMarker?>(
            valueListenable: widget.selectedMarker,
            builder: (context, marker, _) {
              if (marker == null) {
                return const SizedBox.shrink();
              }
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: widget.request.markerCustomizer
                      .buildMarkerDetail(context, marker),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

extension on Iterable<MapMarker> {
  MapMarker? firstWhereOrNull(bool Function(MapMarker marker) predicate) {
    for (final marker in this) {
      if (predicate(marker)) {
        return marker;
      }
    }
    return null;
  }
}
