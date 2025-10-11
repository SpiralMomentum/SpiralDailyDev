import 'package:app_navigation/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_components/ui_components.dart';
import 'package:utils/utils.dart';

import '../features/dashboard/presentation/pages/map_dashboard_page.dart';
import '../features/map/providers/naver_map_provider.dart';
import '../features/map/providers/open_street_map_provider.dart';
import '../features/providers/presentation/pages/provider_catalog_page.dart';

enum MapSwitcherRoute {
  home('/'),
  providers('/providers');

  const MapSwitcherRoute(this.path);
  final String path;
}

class MapSwitcherDependencies {
  MapSwitcherDependencies._({
    required this.registry,
    required this.routesController,
    required this.markerCustomizer,
    required this.router,
    required this.markers,
  });

  static Future<MapSwitcherDependencies> bootstrap() async {
    final naverClientId =
        const String.fromEnvironment('NAVER_MAP_CLIENT_ID', defaultValue: '');
    final naverClientSecret = const String.fromEnvironment(
      'NAVER_MAP_CLIENT_SECRET',
      defaultValue: '',
    );

    final providers = <MapProvider>[
      OpenStreetMapProvider(),
      // if (naverClientId.isNotEmpty)
      //   NaverMapProvider(
      //     clientId: naverClientId,
      //     clientSecret:
      //         naverClientSecret.isEmpty ? null : naverClientSecret,
      //   )
      // else
        const NaverMapsProviderTemplate(),
      const GoogleMapsProviderTemplate(),
      const AmazonLocationProviderTemplate(),
    ];

    final registry = MapProviderRegistry(
      providers: providers,
    );
    await registry.initializeActive();

    final routesController = GoRouterRoutesController(
      navigationType: GoRouterNavigationType.path,
      popAllStrategy: GoRouterPopAllStrategy.navigate,
    );

    final markerCustomizer = DetailCardMarkerCustomizer();
    final markers = _buildSampleMarkers();

    late final GoRouter router;

    router = GoRouter(
      initialLocation: MapSwitcherRoute.home.path,
      routes: [
        GoRoute(
          path: MapSwitcherRoute.home.path,
          builder: (context, state) => MapDashboardPage(
            registry: registry,
            markers: markers,
            markerCustomizer: markerCustomizer,
            routesController: routesController,
          ),
        ),
        GoRoute(
          path: MapSwitcherRoute.providers.path,
          builder: (context, state) => ProviderCatalogPage(
            registry: registry,
            routesController: routesController,
            markerCustomizer: markerCustomizer,
          ),
        ),
      ],
    );

    return MapSwitcherDependencies._(
      registry: registry,
      routesController: routesController,
      markerCustomizer: markerCustomizer,
      router: router,
      markers: markers,
    );
  }

  final MapProviderRegistry registry;
  final RoutesController routesController;
  final MapMarkerCustomizer markerCustomizer;
  final GoRouter router;
  final List<MapMarker> markers;
}

class DetailCardMarkerCustomizer implements MapMarkerCustomizer {
  @override
  Widget buildMarker(BuildContext context, MapMarker marker) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          marker.info?.title ?? marker.id,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }

  @override
  Widget buildMarkerDetail(BuildContext context, MapMarker marker) {
    final info = marker.info;
    if (info == null) {
      return Text('마커 ${marker.id}');
    }

    return DetailCard(
      sectionTitle: info.place,
      primaryColor: Theme.of(context).colorScheme.primaryContainer,
      info: info,
    );
  }
}

List<MapMarker> _buildSampleMarkers() {
  return [
    MapMarker(
      id: 'seoul-city-hall',
      position: const MapCoordinate(latitude: 37.5665, longitude: 126.9780),
      info: Info(
        '서울특별시청',
        'https://images.unsplash.com/photo-1549692520-acc6669e2f0c?auto=format&fit=crop&w=400&q=80',
        '서울 중구 세종대로 110',
        '서울의 역사와 현재가 공존하는 대표적인 시민 소통 공간입니다.',
        DateTime(2024, 1, 1),
        DateTime(2024, 12, 31),
      ),
    ),
    MapMarker(
      id: 'han-river-park',
      position: const MapCoordinate(latitude: 37.5286, longitude: 126.9326),
      info: Info(
        '한강공원',
        'https://images.unsplash.com/photo-1526481280695-3c4692dcaaf9?auto=format&fit=crop&w=400&q=80',
        '서울 영등포구 여의동로 330',
        '도심 속에서 레저와 휴식을 동시에 즐길 수 있는 대표 수변공원입니다.',
        DateTime(2024, 3, 1),
        DateTime(2024, 11, 30),
      ),
    ),
    MapMarker(
      id: 'namdaemun-market',
      position: const MapCoordinate(latitude: 37.5593, longitude: 126.9770),
      info: Info(
        '남대문시장',
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
        '서울 중구 남창동 49-1',
        '조선시대부터 이어져 온 국내 최대 규모의 전통 시장입니다.',
        DateTime(2024, 1, 1),
        DateTime(2024, 12, 31),
      ),
    ),
  ];
}
