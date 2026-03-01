import 'package:flutter/foundation.dart';

import 'geo_coordinate.dart';

/// Represents the camera configuration for a map view.
@immutable
class MapCameraPosition {
  const MapCameraPosition({
    required this.target,
    this.zoom = 14,
    this.tilt = 0,
    this.bearing = 0,
  });

  /// The geographical target the camera is pointing to.
  final GeoCoordinate target;

  /// The zoom level of the camera.
  final double zoom;

  /// The camera's tilt angle in degrees.
  final double tilt;

  /// The camera's bearing in degrees measured clockwise from north.
  final double bearing;

  /// Creates a copy with selective overrides.
  MapCameraPosition copyWith({
    GeoCoordinate? target,
    double? zoom,
    double? tilt,
    double? bearing,
  }) {
    return MapCameraPosition(
      target: target ?? this.target,
      zoom: zoom ?? this.zoom,
      tilt: tilt ?? this.tilt,
      bearing: bearing ?? this.bearing,
    );
  }

  @override
  int get hashCode => Object.hash(target, zoom, tilt, bearing);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is MapCameraPosition &&
        other.target == target &&
        other.zoom == zoom &&
        other.tilt == tilt &&
        other.bearing == bearing;
  }

  @override
  String toString() {
    return 'MapCameraPosition(target: $target, zoom: $zoom, tilt: $tilt, bearing: $bearing)';
  }
}
