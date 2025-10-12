import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:utils/utils.dart';

class NaverMapProvider implements MapProvider {
  NaverMapProvider({
    required this.clientId,
    this.clientSecret,
  }) : assert(clientId.isNotEmpty, 'clientId must not be empty');

  final String clientId;
  final String? clientSecret;
  bool _initialized = false;

  @override
  MapProviderType get type => MapProviderType.naver;

  @override
  String get displayName => 'Naver Map';

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    // SDK v0.10.0+ relies on native platform metadata for authentication.
    if (clientSecret != null) {
      debugPrint(
        'Naver Map clientSecret is currently unused by flutter_naver_map.',
      );
    }
    _initialized = true;
  }

  @override
  MapProviderView buildView(MapViewRequest request) {
    final markers = ValueNotifier<List<MapMarker>>(<MapMarker>[]);
    final selectedMarker = ValueNotifier<MapMarker?>(null);
    final controller = _NaverMapController(
      markers: markers,
      selectedMarker: selectedMarker,
    );

    unawaited(controller.setMarkers(request.markers));

    return MapProviderView(
      map: _NaverMapView(
        controller: controller,
        markers: markers,
        selectedMarker: selectedMarker,
        request: request,
      ),
      controller: controller,
    );
  }
}

class _NaverMapController implements MapProviderController {
  _NaverMapController({
    required ValueNotifier<List<MapMarker>> markers,
    required ValueNotifier<MapMarker?> selectedMarker,
  })  : _markers = markers,
        _selectedMarker = selectedMarker;

  final ValueNotifier<List<MapMarker>> _markers;
  final ValueNotifier<MapMarker?> _selectedMarker;
  final Completer<NaverMapController> _mapControllerCompleter =
      Completer<NaverMapController>();
  final Map<String, NMarker> _markerOverlays = <String, NMarker>{};

  @override
  ValueNotifier<MapMarker?> get selectedMarker => _selectedMarker;

  void attachMapController(NaverMapController controller) {
    if (_mapControllerCompleter.isCompleted) {
      return;
    }
    _mapControllerCompleter.complete(controller);
    unawaited(_synchronizeMarkers(controller));
  }

  Future<NaverMapController> get _mapController async {
    return _mapControllerCompleter.future;
  }

  Future<void> _synchronizeMarkers([NaverMapController? providedController]) async {
    final controller = providedController ??
        (_mapControllerCompleter.isCompleted ? await _mapController : null);
    if (controller == null) {
      return;
    }

    await controller.clearOverlays();
    _markerOverlays.clear();

    for (final marker in _markers.value) {
      final overlay = NMarker(
        id: marker.id,
        position: NLatLng(
          marker.position.latitude,
          marker.position.longitude,
        ),
      );
      overlay.setOnTapListener((overlay) {
        _selectedMarker.value = marker;
        return true;
      });
      await controller.addOverlay(overlay);
      _markerOverlays[marker.id] = overlay;
    }
  }

  @override
  Future<void> moveTo(MapCoordinate position, {double? zoom}) async {
    final controller = await _mapController;
    final target = NLatLng(position.latitude, position.longitude);
    final targetZoom = zoom ?? (await controller.getCameraPosition()).zoom;
    final update = NCameraUpdate.scrollAndZoomTo(target, targetZoom);
    await controller.updateCamera(update);
  }

  @override
  Future<void> setMarkers(List<MapMarker> markers) async {
    _markers.value = List<MapMarker>.unmodifiable(markers);
    await _synchronizeMarkers();
  }

  @override
  Future<void> highlightMarker(String markerId) async {
    if (markerId.isEmpty) {
      _selectedMarker.value = null;
      return;
    }
    final marker =
        _markers.value.firstWhereOrNull((element) => element.id == markerId);
    _selectedMarker.value = marker;
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
    final controller = await _mapController;
    final latitudes = markers.map((marker) => marker.position.latitude);
    final longitudes = markers.map((marker) => marker.position.longitude);
    final southWest = NLatLng(latitudes.reduce(min), longitudes.reduce(min));
    final northEast = NLatLng(latitudes.reduce(max), longitudes.reduce(max));
    await controller.updateCamera(
      NCameraUpdate.fitBounds(
        NLatLngBounds(southWest: southWest, northEast: northEast),
        padding: 48,
      ),
    );
  }

  @override
  void dispose() {
    _markers.dispose();
    _selectedMarker.dispose();
  }
}

class _NaverMapView extends StatefulWidget {
  const _NaverMapView({
    required this.controller,
    required this.markers,
    required this.selectedMarker,
    required this.request,
  });

  final _NaverMapController controller;
  final ValueNotifier<List<MapMarker>> markers;
  final ValueNotifier<MapMarker?> selectedMarker;
  final MapViewRequest request;

  @override
  State<_NaverMapView> createState() => _NaverMapViewState();
}

class _NaverMapViewState extends State<_NaverMapView> {
  static const MapCoordinate _defaultCoordinate =
      MapCoordinate(latitude: 37.5665, longitude: 126.9780);

  @override
  Widget build(BuildContext context) {
    final initialPosition = widget.request.initialCenter ??
        (widget.markers.value.isNotEmpty
            ? widget.markers.value.first.position
            : _defaultCoordinate);
    final initialZoom = widget.request.initialZoom ?? 12.0;

    return Stack(
      children: [
        NaverMap(
          options: NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: NLatLng(
                initialPosition.latitude,
                initialPosition.longitude,
              ),
              zoom: initialZoom,
            ),
          ),
          onMapReady: (controller) async {
            widget.controller.attachMapController(controller);
            await widget.controller.setMarkers(widget.markers.value);
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
