import 'package:flutter/foundation.dart';

import 'geo_coordinate.dart';
import 'map_camera_position.dart';
import 'map_marker.dart';

/// Represents the data required for rendering a map view regardless of the
/// underlying provider implementation.
@immutable
class MapViewConfiguration {
  const MapViewConfiguration({
    required this.initialCameraPosition,
    this.markers = const <MapMarker>{},
    this.onMarkerTap,
    this.onMapTap,
    this.onCameraIdle,
    this.onCameraMove,
  });

  /// Initial camera configuration when the map is first rendered.
  final MapCameraPosition initialCameraPosition;

  /// Markers that should be displayed on the map.
  final Set<MapMarker> markers;

  /// Callback invoked when a marker has been tapped. Providers should prefer
  /// delegating marker tap handling to the marker itself, but this acts as a
  /// global fallback to keep APIs consistent across implementations.
  final ValueChanged<MapMarker>? onMarkerTap;

  /// Callback invoked when the map surface is tapped by the user.
  final ValueChanged<GeoCoordinate>? onMapTap;

  /// Callback invoked when the camera stops moving.
  final ValueChanged<MapCameraPosition>? onCameraIdle;

  /// Callback invoked whenever the camera moves.
  final ValueChanged<MapCameraPosition>? onCameraMove;

  MapViewConfiguration copyWith({
    MapCameraPosition? initialCameraPosition,
    Set<MapMarker>? markers,
    ValueChanged<MapMarker>? onMarkerTap,
    ValueChanged<GeoCoordinate>? onMapTap,
    ValueChanged<MapCameraPosition>? onCameraIdle,
    ValueChanged<MapCameraPosition>? onCameraMove,
  }) {
    return MapViewConfiguration(
      initialCameraPosition:
          initialCameraPosition ?? this.initialCameraPosition,
      markers: markers ?? this.markers,
      onMarkerTap: onMarkerTap ?? this.onMarkerTap,
      onMapTap: onMapTap ?? this.onMapTap,
      onCameraIdle: onCameraIdle ?? this.onCameraIdle,
      onCameraMove: onCameraMove ?? this.onCameraMove,
    );
  }
}
