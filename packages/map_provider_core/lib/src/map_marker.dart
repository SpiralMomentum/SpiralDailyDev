import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'geo_coordinate.dart';

/// Describes how a marker should be rendered on top of the map.
@immutable
class MapMarkerStyle {
  const MapMarkerStyle({
    this.assetName,
    this.assetPackage,
    this.width,
    this.height,
    this.tintColor,
    this.hue,
  });

  /// Asset name that should be used as the marker icon.
  final String? assetName;

  /// The package containing the asset when [assetName] is provided.
  final String? assetPackage;

  /// Desired width of the marker icon in logical pixels.
  final double? width;

  /// Desired height of the marker icon in logical pixels.
  final double? height;

  /// Tint color to apply to the marker icon if supported by the provider.
  final Color? tintColor;

  /// Convenience hue value for providers that support simple hue-based colors.
  final double? hue;

  MapMarkerStyle copyWith({
    String? assetName,
    String? assetPackage,
    double? width,
    double? height,
    Color? tintColor,
    double? hue,
  }) {
    return MapMarkerStyle(
      assetName: assetName ?? this.assetName,
      assetPackage: assetPackage ?? this.assetPackage,
      width: width ?? this.width,
      height: height ?? this.height,
      tintColor: tintColor ?? this.tintColor,
      hue: hue ?? this.hue,
    );
  }
}

/// Metadata shown when interacting with a marker.
@immutable
class MapMarkerInfoWindow {
  const MapMarkerInfoWindow({this.title, this.snippet});

  final String? title;
  final String? snippet;
}

/// Represents an interactive marker placed on a map view.
@immutable
class MapMarker {
  const MapMarker({
    required this.id,
    required this.position,
    this.style = const MapMarkerStyle(),
    this.infoWindow,
    this.onTap,
  });

  /// Unique identifier for the marker within a map view.
  final String id;

  /// Geographic coordinate of the marker.
  final GeoCoordinate position;

  /// Styling information for the marker.
  final MapMarkerStyle style;

  /// Optional info window metadata that should be displayed on tap.
  final MapMarkerInfoWindow? infoWindow;

  /// Callback invoked when the marker is tapped.
  final VoidCallback? onTap;
}
