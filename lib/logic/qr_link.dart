/// Turns whatever a QR code (or a pasted string) contains into a DIGIPIN.
///
/// Accepts:
///  * a DigiRoutes link  — https://digiroutes.vercel.app/card/<PIN> or /digipin/<PIN>
///  * a bare DIGIPIN     — with or without dashes/spaces, any case
/// Returns the normalised 10-character DIGIPIN, or null if [raw] isn't one.
library;

import 'digipin.dart';

const _hosts = {'digiroutes.vercel.app', 'www.digiroutes.vercel.app'};

String? digipinFromScan(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
    if (!_hosts.contains(uri.host.toLowerCase())) return null;
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.length >= 2 && (segs[0] == 'card' || segs[0] == 'digipin')) {
      return _validPin(segs[1]);
    }
    return null;
  }
  return _validPin(text);
}

String? _validPin(String candidate) {
  final pin = candidate.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
  try {
    getLatLngFromDigiPin(pin);
    return pin;
  } catch (_) {
    return null;
  }
}
