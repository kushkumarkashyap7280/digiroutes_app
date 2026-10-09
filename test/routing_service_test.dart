import 'package:digiroutes_app/core/routing_service.dart';
import 'package:digiroutes_app/logic/geo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const routeJson = '''
{"type":"FeatureCollection","features":[{"type":"Feature",
 "properties":{"summary":{"distance":4210.5,"duration":812.3}},
 "geometry":{"type":"LineString","coordinates":[[77.209,28.6139],[77.21,28.62],[77.22,28.63]]}}]}''';

  const placesJson = '''
{"features":[
 {"geometry":{"coordinates":[77.2167,28.6315]},"properties":{"label":"Connaught Place, New Delhi, India"}},
 {"geometry":{"coordinates":[77.2090,28.6139]},"properties":{"label":"New Delhi, India"}}]}''';

  group('RoutingService.parseRoute', () {
    test('reads distance, duration and swaps lon/lat into lat/lon', () {
      final r = RoutingService.parseRoute(200, routeJson);
      expect(r.distanceMeters, 4210.5);
      expect(r.durationSeconds, 812.3);
      expect(r.points.length, 3);
      expect(r.points.first.lat, 28.6139);
      expect(r.points.first.lon, 77.209);
    });

    test('maps error responses to friendly messages', () {
      String msg(int s, String b) {
        try {
          RoutingService.parseRoute(s, b);
        } on RoutingException catch (e) {
          return e.message;
        }
        return '';
      }

      expect(msg(401, '{}'), contains('key'));
      expect(msg(429, '{}'), contains('Too many'));
      expect(msg(404, '{"error":{"code":2010,"message":"x"}}'),
          contains('No road found'));
      expect(msg(400, '{"error":{"code":2004,"message":"x"}}'),
          contains('too far apart'));
      expect(msg(503, '<html>'), contains('trouble'));
    });

    test('garbage body becomes a readable error, not a crash', () {
      expect(() => RoutingService.parseRoute(200, 'nope'),
          throwsA(isA<RoutingException>()));
    });
  });

  group('RoutingService.parsePlaces', () {
    test('returns labelled points', () {
      final places = RoutingService.parsePlaces(200, placesJson);
      expect(places.length, 2);
      expect(places.first.label, startsWith('Connaught Place'));
      expect(places.first.point.lat, 28.6315);
      expect(places.first.point.lon, 77.2167);
    });
  });

  test('without a key the service reports it is not configured', () {
    // Tests run without --dart-define=ORS_API_KEY.
    expect(RoutingService.isConfigured, isFalse);
    expect(
        () => RoutingService.route(
            const GeoPoint(28.61, 77.20), const GeoPoint(28.63, 77.22), RouteMode.drive),
        throwsA(isA<RoutingException>()));
  });
}
