import 'package:geolocator/geolocator.dart';
import '../logic/geo.dart';

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
  @override
  String toString() => message;
}

/// Current GPS position, asking for permission when needed.
Future<GeoPoint> currentLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationException('Turn on GPS / location services and try again.');
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    throw const LocationException(
        'Location permission is off. Allow it in Settings to use your current location.');
  }
  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return GeoPoint(pos.latitude, pos.longitude);
  } catch (_) {
    throw const LocationException('Could not get your location. Try again outside or with GPS on.');
  }
}
