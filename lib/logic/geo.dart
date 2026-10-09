/// Small, dependency-free geo helpers used by the route feature.
library;

import 'dart:math' as math;

/// A latitude/longitude pair.
class GeoPoint {
  final double lat;
  final double lon;
  const GeoPoint(this.lat, this.lon);

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);

  @override
  String toString() => '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
}

/// Straight-line ("as the crow flies") distance in metres (haversine).
double haversineMeters(GeoPoint a, GeoPoint b) {
  const r = 6371008.8; // mean Earth radius, metres
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLon = rad(b.lon - a.lon);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(h)));
}

/// "850 m", "4.2 km", "126 km".
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  return km < 100 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
}

/// "3 min", "1 h 05 min", "2 h".
String formatDuration(double seconds) {
  final mins = (seconds / 60).round();
  if (mins < 1) return '< 1 min';
  if (mins < 60) return '$mins min';
  final h = mins ~/ 60, m = mins % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')} min';
}

/// Parses "28.6139, 77.2090", "28.6139 77.2090" or "28.6139;77.2090".
/// Returns null unless both numbers are valid lat/lon values.
GeoPoint? parseLatLon(String input) {
  final m = RegExp(r'^\s*(-?\d{1,3}(?:\.\d+)?)\s*[,;\s]\s*(-?\d{1,3}(?:\.\d+)?)\s*$')
      .firstMatch(input);
  if (m == null) return null;
  final lat = double.parse(m.group(1)!);
  final lon = double.parse(m.group(2)!);
  if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
  return GeoPoint(lat, lon);
}
