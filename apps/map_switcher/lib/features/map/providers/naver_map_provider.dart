// import 'dart:async';
// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:naver_map_plugin/naver_map_plugin.dart';
// import 'package:utils/utils.dart';

// class NaverMapProvider implements MapProvider {
//   NaverMapProvider({
//     required this.clientId,
//     this.clientSecret,
//     NaverMapSdk? sdk,
//   })  : assert(clientId.isNotEmpty, 'clientId must not be empty'),
//         _sdk = sdk ?? NaverMapSdk.instance;

//   final String clientId;
//   final String? clientSecret;
//   final NaverMapSdk _sdk;
//   bool _initialized = false;

//   @override
//   MapProviderType get type => MapProviderType.naver;

//   @override
//   String get displayName => 'Naver Map';

//   @override
//   Future<void> initialize() async {
//     if (_initialized) {
//       return;
//     }
//     await _sdk.initialize(
//       clientId: clientId,
//       clientSecret: clientSecret,
//       onAuthFailed: (error) {
//         debugPrint('Naver Map authentication failed: $error');
//       },
//     );
//     _initialized = true;
//   }

//   @override
//   MapProviderView buildView(MapViewRequest request) {
//     final markers = ValueNotifier<List<MapMarker>>(<MapMarker>[]);
//     final selectedMarker = ValueNotifier<MapMarker?>(null);
//     final controller = _NaverMapController(
//       markers: markers,
//       selectedMarker: selectedMarker,
//     );

//     return MapProviderView(
//       map: _NaverMapView(
//         controller: controller,
//         markers: markers,
//         selectedMarker: selectedMarker,
//         request: request,
//       ),
//       controller: controller,
//     );
//   }
// }

// class _NaverMapController implements MapProviderController {
//   _NaverMapController({
//     required ValueNotifier<List<MapMarker>> markers,
//     required ValueNotifier<MapMarker?> selectedMarker,
//   })  : _markers = markers,
//         _selectedMarker = selectedMarker;

//   final ValueNotifier<List<MapMarker>> _markers;
//   final ValueNotifier<MapMarker?> _selectedMarker;
//   final Completer<NaverMapController> _mapControllerCompleter =
//       Completer<NaverMapController>();

//   @override
//   ValueNotifier<MapMarker?> get selectedMarker => _selectedMarker;

//   void attachMapController(NaverMapController controller) {
//     if (_mapControllerCompleter.isCompleted) {
//       return;
//     }
//     _mapControllerCompleter.complete(controller);
//   }

//   Future<NaverMapController> get _mapController async {
//     return _mapControllerCompleter.future;
//   }

//   @override
//   Future<void> moveTo(MapCoordinate position, {double? zoom}) async {
//     final controller = await _mapController;
//     final targetZoom = zoom ?? (await controller.getCameraPosition()).zoom;
//     await controller.moveCamera(
//       CameraUpdate.toCameraPosition(
//         CameraPosition(
//           target: LatLng(position.latitude, position.longitude),
//           zoom: targetZoom,
//         ),
//       ),
//     );
//   }

//   @override
//   Future<void> setMarkers(List<MapMarker> markers) async {
//     _markers.value = List<MapMarker>.unmodifiable(markers);
//   }

//   @override
//   Future<void> highlightMarker(String markerId) async {
//     if (markerId.isEmpty) {
//       _selectedMarker.value = null;
//       return;
//     }
//     _selectedMarker.value =
//         _markers.value.firstWhereOrNull((marker) => marker.id == markerId);
//   }

//   @override
//   Future<void> fitBounds(List<MapMarker> markers) async {
//     if (markers.isEmpty) {
//       return;
//     }
//     if (markers.length == 1) {
//       await moveTo(markers.first.position, zoom: 14);
//       return;
//     }

//     final controller = await _mapController;
//     final latitudes = markers.map((marker) => marker.position.latitude);
//     final longitudes = markers.map((marker) => marker.position.longitude);

//     final southWest = LatLng(
//       latitudes.reduce(min),
//       longitudes.reduce(min),
//     );
//     final northEast = LatLng(
//       latitudes.reduce(max),
//       longitudes.reduce(max),
//     );

//     await controller.moveCamera(
//       CameraUpdate.fitBounds(
//         LatLngBounds(southWest, northEast),
//         padding: 48,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _markers.dispose();
//     _selectedMarker.dispose();
//   }
// }

// class _NaverMapView extends StatefulWidget {
//   const _NaverMapView({
//     required this.controller,
//     required this.markers,
//     required this.selectedMarker,
//     required this.request,
//   });

//   final _NaverMapController controller;
//   final ValueNotifier<List<MapMarker>> markers;
//   final ValueNotifier<MapMarker?> selectedMarker;
//   final MapViewRequest request;

//   @override
//   State<_NaverMapView> createState() => _NaverMapViewState();
// }

// class _NaverMapViewState extends State<_NaverMapView> {
//   late final double _initialZoom = widget.request.initialZoom ?? 12.0;

//   @override
//   Widget build(BuildContext context) {
//     final initialPosition = widget.request.initialCenter ??
//         (widget.markers.value.isNotEmpty
//             ? widget.markers.value.first.position
//             : const MapCoordinate(latitude: 37.5665, longitude: 126.9780));

//     return Stack(
//       children: [
//         ValueListenableBuilder<List<MapMarker>>(
//           valueListenable: widget.markers,
//           builder: (context, markers, _) {
//             return NaverMap(
//               onMapCreated: widget.controller.attachMapController,
//               initialCameraPosition: CameraPosition(
//                 target: LatLng(
//                   initialPosition.latitude,
//                   initialPosition.longitude,
//                 ),
//                 zoom: _initialZoom,
//               ),
//               onMapTap: (point, latLng) {
//                 widget.selectedMarker.value = null;
//               },
//               markers: markers
//                   .map((marker) => _buildMarker(context, marker))
//                   .toSet(),
//             );
//           },
//         ),
//         Positioned(
//           left: 16,
//           right: 16,
//           bottom: 16,
//           child: ValueListenableBuilder<MapMarker?>(
//             valueListenable: widget.selectedMarker,
//             builder: (context, marker, _) {
//               if (marker == null) {
//                 return const SizedBox.shrink();
//               }
//               return DecoratedBox(
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.surface,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       blurRadius: 12,
//                       color: Colors.black.withOpacity(0.2),
//                     ),
//                   ],
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: widget.request.markerCustomizer
//                       .buildMarkerDetail(context, marker),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Marker _buildMarker(BuildContext context, MapMarker marker) {
//     return Marker(
//       markerId: MarkerId(marker.id),
//       position: LatLng(
//         marker.position.latitude,
//         marker.position.longitude,
//       ),
//       captionText: marker.info?.title ?? marker.id,
//       onMarkerTab: (overlay, iconSize) {
//         widget.selectedMarker.value = marker;
//         return true;
//       },
//     );
//   }
// }

// extension on Iterable<MapMarker> {
//   MapMarker? firstWhereOrNull(bool Function(MapMarker marker) predicate) {
//     for (final marker in this) {
//       if (predicate(marker)) {
//         return marker;
//       }
//     }
//     return null;
//   }
// }
