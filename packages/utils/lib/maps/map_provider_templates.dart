import 'package:flutter/material.dart';

import 'map_provider.dart';

abstract class TemplateMapProvider implements MapProvider {
  const TemplateMapProvider({required this.type, required this.displayName});

  @override
  final MapProviderType type;

  @override
  final String displayName;

  @override
  Future<void> initialize() async {}

  String get integrationHint;

  @override
  Widget buildMap(MapViewRequest request) {
    return MapProviderPlaceholder(
      providerName: displayName,
      markers: request.markers,
      markerCustomizer: request.markerCustomizer,
      description: integrationHint,
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
