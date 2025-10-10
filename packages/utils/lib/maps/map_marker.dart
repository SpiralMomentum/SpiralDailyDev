import 'package:flutter/material.dart';
import 'package:ui_components/card/info.dart';

/// Represents a point of interest that should be rendered on a map.
class MapMarker {
  const MapMarker({
    required this.id,
    required this.position,
    this.info,
    this.icon,
  });

  /// Unique identifier used by providers to track marker state.
  final String id;

  /// Geographical position of the marker.
  final MapCoordinate position;

  /// Optional rich information associated with the marker.
  ///
  /// The structure mirrors [Info] from `ui_components` so map services can
  /// easily reuse existing card templates when showing marker details.
  final Info? info;

  /// Optional icon override for providers that support custom widgets.
  final Widget? icon;
}

/// Immutable latitude/longitude pair.
class MapCoordinate {
  const MapCoordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
