import 'package:flutter/widgets.dart';

import 'map_marker.dart';

/// Contract for building visual representations of markers across providers.
abstract interface class MapMarkerCustomizer {
  /// Builds the widget that should be used as the marker glyph on the map.
  Widget buildMarker(BuildContext context, MapMarker marker);

  /// Builds an optional detailed representation for the marker.
  ///
  /// Providers can surface this widget inside an info window, bottom sheet or
  /// any other container that matches the UX of the underlying SDK.
  Widget buildMarkerDetail(BuildContext context, MapMarker marker);
}
