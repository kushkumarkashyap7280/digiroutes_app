import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// A plain, no-API-key Google Maps link — opens in the Maps app if one is
/// installed on the recipient's device, otherwise falls back to the browser.
String googleMapsUrl(double lat, double lon) =>
    'https://www.google.com/maps?q=$lat,$lon';

/// Shares a Google Maps link via the system share sheet, so the recipient
/// can open it in whichever they have — browser or the Maps app.
Future<void> shareLocationLink({
  required double lat,
  required double lon,
  String? label,
}) {
  final url = googleMapsUrl(lat, lon);
  return Share.share(
    label != null && label.isNotEmpty ? '$label\n$url' : url,
    subject: label ?? 'Location',
  );
}

/// Opens the location directly — external Maps app if installed, else browser.
Future<void> openInMaps({required double lat, required double lon}) async {
  final uri = Uri.parse(googleMapsUrl(lat, lon));
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
