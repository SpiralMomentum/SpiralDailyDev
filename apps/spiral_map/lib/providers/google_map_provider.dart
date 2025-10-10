import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_provider_core/map_provider_core.dart';

class GoogleMapProvider extends MapProviderAdapter {
  GoogleMapProvider();

  CameraPosition? _lastKnownCameraPosition;

  @override
  String get id => 'google_maps';

  @override
  String get displayName => 'Google Maps';

  @override
  Widget buildMap(BuildContext context, MapViewConfiguration configuration) {
    return GoogleMap(
      initialCameraPosition:
          _toCameraPosition(configuration.initialCameraPosition),
      markers: configuration.markers
          .map((marker) => _toGoogleMarker(marker, configuration))
          .toSet(),
      onTap: (position) =>
          configuration.onMapTap?.call(_toGeoCoordinate(position)),
      onCameraMove: (position) {
        _lastKnownCameraPosition = position;
        configuration.onCameraMove?.call(_toMapCameraPosition(position));
      },
      onCameraIdle: () {
        final camera = _lastKnownCameraPosition;
        if (camera != null) {
          configuration.onCameraIdle?.call(_toMapCameraPosition(camera));
        }
      },
    );
  }

  @override
  bool supportsMarkerStyle(MapMarkerStyle style) {
    // The Google Maps Flutter plugin supports marker tinting via hue. Asset
    // based icons require asynchronous loading which is not handled in this
    // adapter template.
    return style.assetName == null;
  }

  Marker _toGoogleMarker(
    MapMarker marker,
    MapViewConfiguration configuration,
  ) {
    return Marker(
      markerId: MarkerId(marker.id),
      position: LatLng(marker.position.latitude, marker.position.longitude),
      icon: marker.style.hue != null
          ? BitmapDescriptor.defaultMarkerWithHue(marker.style.hue!)
          : BitmapDescriptor.defaultMarker,
      infoWindow: marker.infoWindow == null
          ? InfoWindow.noText
          : InfoWindow(
              title: marker.infoWindow!.title,
              snippet: marker.infoWindow!.snippet,
            ),
      onTap: () {
        marker.onTap?.call();
        configuration.onMarkerTap?.call(marker);
      },
    );
  }

  CameraPosition _toCameraPosition(MapCameraPosition position) {
    return CameraPosition(
      target: LatLng(position.target.latitude, position.target.longitude),
      zoom: position.zoom,
      tilt: position.tilt,
      bearing: position.bearing,
    );
  }

  MapCameraPosition _toMapCameraPosition(CameraPosition position) {
    return MapCameraPosition(
      target: GeoCoordinate(position.target.latitude, position.target.longitude),
      zoom: position.zoom,
      tilt: position.tilt,
      bearing: position.bearing,
    );
  }

  GeoCoordinate _toGeoCoordinate(LatLng position) {
    return GeoCoordinate(position.latitude, position.longitude);
  }
}
