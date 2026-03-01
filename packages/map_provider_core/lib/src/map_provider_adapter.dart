import 'package:flutter/material.dart';

import 'map_marker.dart';
import 'map_view_configuration.dart';

/// Base contract that every map provider implementation must fulfil.
abstract class MapProviderAdapter {
  const MapProviderAdapter();

  /// Unique identifier for the provider.
  String get id;

  /// Human readable name used in selection UIs.
  String get displayName;

  /// Builds the map widget using the supplied configuration.
  Widget buildMap(BuildContext context, MapViewConfiguration configuration);

  /// Returns whether the provider supports rendering markers styled with [style].
  bool supportsMarkerStyle(MapMarkerStyle style);
}
