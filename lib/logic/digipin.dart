/// DIGIPIN Encoder and Decoder — Dart port
///
/// Direct port of India Post's DIGIPIN algorithm from the TypeScript
/// implementation in the DigiRoutes web server (lib/digipin.ts).
///
/// Works entirely offline — no network call needed.
///
/// Functions:
///   getDigiPin(lat, lon)              → 10-char DIGIPIN string
///   getLatLngFromDigiPin(digiPin)     → DigipinCoords { latitude, longitude }
library;

class DigipinCoords {
  final double latitude;
  final double longitude;
  const DigipinCoords({required this.latitude, required this.longitude});

  @override
  String toString() =>
      'DigipinCoords(${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)})';
}

/// 4×4 character grid used to encode each refinement level.
const List<List<String>> _digipinGrid = [
  ['F', 'C', '9', '8'],
  ['J', '3', '2', '7'],
  ['K', '4', '5', '6'],
  ['L', 'M', 'P', 'T'],
];

const double _minLat =  2.5;
const double _maxLat = 38.5;
const double _minLon = 63.5;
const double _maxLon = 99.5;

final RegExp _validCharsRe = RegExp(r'^[23456789CFJKLMPT]{10}$');

/// Encodes [lat]/[lon] into a 10-character DIGIPIN string.
///
/// Throws [ArgumentError] if coordinates are outside India Post bounds.
String getDigiPin(double lat, double lon) {
  if (lat < _minLat || lat > _maxLat) {
    throw ArgumentError(
      'Latitude $lat is out of range [$_minLat, $_maxLat]. '
      'DIGIPIN covers the Indian subcontinent only.',
    );
  }
  if (lon < _minLon || lon > _maxLon) {
    throw ArgumentError(
      'Longitude $lon is out of range [$_minLon, $_maxLon]. '
      'DIGIPIN covers the Indian subcontinent only.',
    );
  }

  double minLat = _minLat, maxLat = _maxLat;
  double minLon = _minLon, maxLon = _maxLon;
  final sb = StringBuffer();

  for (int level = 1; level <= 10; level++) {
    final latDiv = (maxLat - minLat) / 4;
    final lonDiv = (maxLon - minLon) / 4;

    int row = 3 - ((lat - minLat) / latDiv).floor();
    int col = ((lon - minLon) / lonDiv).floor();

    row = row.clamp(0, 3);
    col = col.clamp(0, 3);

    sb.write(_digipinGrid[row][col]);

    maxLat = minLat + latDiv * (4 - row);
    minLat = minLat + latDiv * (3 - row);
    minLon = minLon + lonDiv * col;
    maxLon = minLon + lonDiv;
  }

  return sb.toString().toUpperCase();
}

/// Decodes a 10-character [digiPin] back to the central lat/lon of its cell.
///
/// Throws [ArgumentError] if the string is invalid.
DigipinCoords getLatLngFromDigiPin(String digiPin) {
  final pin = digiPin.trim().toUpperCase();

  if (pin.length != 10) {
    throw ArgumentError('Invalid DIGIPIN: must be exactly 10 characters.');
  }
  if (!_validCharsRe.hasMatch(pin)) {
    throw ArgumentError(
      'Invalid DIGIPIN: only characters 2,3,4,5,6,7,8,9,C,F,J,K,L,M,P,T are allowed.',
    );
  }

  double minLat = _minLat, maxLat = _maxLat;
  double minLon = _minLon, maxLon = _maxLon;

  for (int i = 0; i < 10; i++) {
    final char = pin[i];
    int ri = -1, ci = -1;
    bool found = false;

    outer:
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (_digipinGrid[r][c] == char) {
          ri = r; ci = c; found = true;
          break outer;
        }
      }
    }

    if (!found) throw ArgumentError('Invalid character "$char" in DIGIPIN.');

    final latDiv = (maxLat - minLat) / 4;
    final lonDiv = (maxLon - minLon) / 4;

    final lat1 = maxLat - latDiv * (ri + 1);
    final lat2 = maxLat - latDiv * ri;
    final lon1 = minLon + lonDiv * ci;
    final lon2 = minLon + lonDiv * (ci + 1);

    minLat = lat1; maxLat = lat2;
    minLon = lon1; maxLon = lon2;
  }

  return DigipinCoords(
    latitude:  (minLat + maxLat) / 2,
    longitude: (minLon + maxLon) / 2,
  );
}
