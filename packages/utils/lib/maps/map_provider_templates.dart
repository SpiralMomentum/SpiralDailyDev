import 'package:flutter/material.dart';

import 'map_marker.dart';
import 'map_provider.dart';

class _TemplateMapProviderController implements MapProviderController {
  _TemplateMapProviderController(List<MapMarker> initialMarkers)
      : _markers = ValueNotifier<List<MapMarker>>(List.of(initialMarkers)),
        _selectedMarker = ValueNotifier<MapMarker?>(null);

  final ValueNotifier<List<MapMarker>> _markers;
  final ValueNotifier<MapMarker?> _selectedMarker;

  @override
  ValueNotifier<MapMarker?> get selectedMarker => _selectedMarker;

  @override
  Future<void> moveTo(MapCoordinate position, {double? zoom}) async {}

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
    MapMarker? match;
    for (final marker in _markers.value) {
      if (marker.id == markerId) {
        match = marker;
        break;
      }
    }
    _selectedMarker.value = match;
  }

  @override
  Future<void> fitBounds(List<MapMarker> markers) async {}

  @override
  void dispose() {
    _markers.dispose();
    _selectedMarker.dispose();
  }

  ValueNotifier<List<MapMarker>> get markers => _markers;
}

abstract class TemplateMapProvider implements MapProvider {
  const TemplateMapProvider({required this.type, required this.displayName});

  @override
  final MapProviderType type;

  @override
  final String displayName;

  @override
  Future<void> initialize() async {}

  String get integrationHint;

  MapProviderView buildView(MapViewRequest request) {
    final controller = _TemplateMapProviderController(request.markers);
    return MapProviderView(
      map: MapProviderPlaceholder(
        providerName: displayName,
        markersListenable: controller.markers,
        markerCustomizer: request.markerCustomizer,
        description: integrationHint,
      ),
      controller: controller,
    );
  }
}

class GoogleMapsProviderTemplate extends TemplateMapProvider {
  const GoogleMapsProviderTemplate()
      : super(
          type: MapProviderType.google,
          displayName: 'Google Maps',
        );

  @override
  String get integrationHint =>
      'TODO: Google Maps SDK 연동 후 실제 지도를 표시하세요.';
}

class NaverMapsProviderTemplate extends TemplateMapProvider {
  const NaverMapsProviderTemplate()
      : super(
          type: MapProviderType.naver,
          displayName: 'Naver Map',
        );

  @override
  String get integrationHint =>
      'TODO: 네이버 지도 SDK 연동 및 인증 키 설정이 필요합니다.';
}

class AmazonLocationProviderTemplate extends TemplateMapProvider {
  const AmazonLocationProviderTemplate()
      : super(
          type: MapProviderType.amazon,
          displayName: 'Amazon Location Service',
        );

  @override
  String get integrationHint =>
      'TODO: Amazon Location Service 지도를 구성하고 권한을 연결하세요.';
}
