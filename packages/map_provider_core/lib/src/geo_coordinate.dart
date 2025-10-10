import 'package:flutter/foundation.dart';

/// Represents a geographic coordinate using latitude and longitude values.
@immutable
class GeoCoordinate {
  const GeoCoordinate(this.latitude, this.longitude)
      : assert(latitude >= -90 && latitude <= 90,
            'Latitude must be between -90 and 90 degrees.'),
        assert(longitude >= -180 && longitude <= 180,
            'Longitude must be between -180 and 180 degrees.');

  /// Latitude component in degrees.
  final double latitude;

  /// Longitude component in degrees.
  final double longitude;

  /// Creates a copy of the coordinate with modified values.
  GeoCoordinate copyWith({double? latitude, double? longitude}) {
    return GeoCoordinate(latitude ?? this.latitude, longitude ?? this.longitude);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is GeoCoordinate &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoCoordinate(lat: $latitude, lng: $longitude)';
}
