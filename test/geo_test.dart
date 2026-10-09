import 'package:digiroutes_app/logic/geo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('haversineMeters', () {
    test('Delhi to Mumbai is about 1,150 km', () {
      final km = haversineMeters(const GeoPoint(28.6139, 77.2090),
              const GeoPoint(19.0760, 72.8777)) /
          1000;
      expect(km, inInclusiveRange(1140, 1160));
    });

    test('same point is zero and the distance is symmetric', () {
      const a = GeoPoint(12.97, 77.59), b = GeoPoint(13.08, 80.27);
      expect(haversineMeters(a, a), 0);
      expect(haversineMeters(a, b), closeTo(haversineMeters(b, a), 1e-6));
    });
  });

  group('formatting', () {
    test('distance', () {
      expect(formatDistance(850), '850 m');
      expect(formatDistance(4200), '4.2 km');
      expect(formatDistance(126400), '126 km');
    });

    test('duration', () {
      expect(formatDuration(20), '< 1 min');
      expect(formatDuration(180), '3 min');
      expect(formatDuration(3900), '1 h 05 min');
      expect(formatDuration(7200), '2 h');
    });
  });

  group('parseLatLon', () {
    test('accepts comma, space and semicolon separators', () {
      const p = GeoPoint(28.6139, 77.2090);
      expect(parseLatLon('28.6139, 77.2090'), p);
      expect(parseLatLon('  28.6139 77.2090 '), p);
      expect(parseLatLon('28.6139;77.2090'), p);
      expect(parseLatLon('-33.86, 151.21'), const GeoPoint(-33.86, 151.21));
    });

    test('rejects out-of-range values and text', () {
      expect(parseLatLon('95, 77'), isNull);
      expect(parseLatLon('28, 190'), isNull);
      expect(parseLatLon('Connaught Place'), isNull);
      expect(parseLatLon('28.6139'), isNull);
      expect(parseLatLon(''), isNull);
    });
  });
}
