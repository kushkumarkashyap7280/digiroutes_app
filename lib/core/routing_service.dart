import 'dart:convert';
import '../logic/geo.dart';
import 'api_http.dart';

/// How the user travels; maps to an OpenRouteService profile.
enum RouteMode {
  drive('driving-car', 'Drive'),
  bike('cycling-regular', 'Bike'),
  walk('foot-walking', 'Walk');

  final String profile;
  final String label;
  const RouteMode(this.profile, this.label);
}

class RouteResult {
  final double distanceMeters;
  final double durationSeconds;
  final List<GeoPoint> points;
  const RouteResult(this.distanceMeters, this.durationSeconds, this.points);
}

class GeoPlace {
  final String label;
  final GeoPoint point;
  const GeoPlace(this.label, this.point);
}

class RoutingException implements Exception {
  final String message;
  const RoutingException(this.message);
  @override
  String toString() => message;
}

/// Road routes and place search through OpenRouteService (free key).
/// The key comes from `--dart-define=ORS_API_KEY=…` (CI secret / env.local.json).
/// Straight-line distance never needs it — see `haversineMeters`.
class RoutingService {
  RoutingService._();

  static const _key = String.fromEnvironment('ORS_API_KEY');
  static bool get isConfigured => _key.isNotEmpty;

  static const _host = 'https://api.openrouteservice.org';

  static void _requireKey() {
    if (!isConfigured) {
      throw const RoutingException(
          'Road routes are not set up in this build. Straight-line distance is still shown.');
    }
  }

  static Future<RouteResult> route(
      GeoPoint from, GeoPoint to, RouteMode mode) async {
    _requireKey();
    final res = await ApiHttp.post(
      Uri.parse('$_host/v2/directions/${mode.profile}/geojson'),
      headers: {'Authorization': _key, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'coordinates': [
          [from.lon, from.lat],
          [to.lon, to.lat],
        ],
      }),
    );
    return parseRoute(res.statusCode, res.body);
  }

  /// Place-name search, limited to India. Needs at least 3 characters.
  static Future<List<GeoPlace>> search(String text) async {
    _requireKey();
    final q = text.trim();
    if (q.length < 3) return const [];
    final res = await ApiHttp.get(Uri.parse('$_host/geocode/search').replace(
      queryParameters: {
        'api_key': _key,
        'text': q,
        'boundary.country': 'IN',
        'size': '6',
      },
    ));
    return parsePlaces(res.statusCode, res.body);
  }

  // ── parsing (public for tests) ──────────────────────────────────────────

  static RouteResult parseRoute(int status, String body) {
    if (status != 200) throw RoutingException(_errorFor(status, body));
    try {
      final feature = (jsonDecode(body)['features'] as List).first as Map;
      final summary = feature['properties']['summary'] as Map;
      final coords = (feature['geometry']['coordinates'] as List)
          .map((c) => GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      return RouteResult(
        (summary['distance'] as num).toDouble(),
        (summary['duration'] as num).toDouble(),
        coords,
      );
    } catch (_) {
      throw const RoutingException('Could not read the route. Please try again.');
    }
  }

  static List<GeoPlace> parsePlaces(int status, String body) {
    if (status != 200) throw RoutingException(_errorFor(status, body));
    try {
      final features = jsonDecode(body)['features'] as List;
      return [
        for (final f in features)
          GeoPlace(
            f['properties']['label'] as String,
            GeoPoint((f['geometry']['coordinates'][1] as num).toDouble(),
                (f['geometry']['coordinates'][0] as num).toDouble()),
          ),
      ];
    } catch (_) {
      throw const RoutingException('Could not read the search results.');
    }
  }

  static String _errorFor(int status, String body) {
    int? code;
    try {
      final e = jsonDecode(body)['error'];
      if (e is Map) code = e['code'] as int?;
    } catch (_) {/* non-JSON body */}

    if (status == 401 || status == 403) {
      return 'The routing key was rejected. Check ORS_API_KEY.';
    }
    if (status == 429) {
      return 'Too many route requests right now. Try again in a minute.';
    }
    if (code == 2010) return 'No road found near one of the points.';
    if (code == 2004 || code == 2003) {
      return 'These points are too far apart for this travel mode.';
    }
    if (status == 404) return 'No route found between these points.';
    if (status >= 500) return 'The routing service is having trouble. Try again shortly.';
    return 'Could not get a route. Please try again.';
  }
}
