import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/address_card.dart';
import '../logic/digipin.dart';
import 'api_http.dart';

/// Builds the plain-text body used when sharing a card.
String cardShareText(AddressCard card) {
  final buf = StringBuffer()
    ..writeln('📍 ${card.title}')
    ..writeln('DIGIPIN: ${card.digipin}');
  if (card.humanAddress.isNotEmpty) buf.writeln(card.humanAddress);
  if (card.deliveryNote.isNotEmpty) buf.writeln('📝 ${card.deliveryNote}');
  if (card.contactPhone.isNotEmpty && !card.hidePhone) {
    buf.writeln('📞 ${card.contactPhone}');
  }
  try {
    final c = getLatLngFromDigiPin(card.digipin);
    buf.writeln('🗺️ https://www.google.com/maps?q=${c.latitude},${c.longitude}');
  } catch (_) {/* invalid pin: skip the map link */}
  buf.write('Open in DigiRoutes: ${card.shareUrl}');
  return buf.toString();
}

/// Shares the card as one message: entrance photo (when there is one), DIGIPIN,
/// address, note, phone, Google Maps link and the DigiRoutes link.
/// Falls back to text only if the photo can't be downloaded.
Future<void> shareCardRich(AddressCard card) async {
  final text = cardShareText(card);
  final photo =
      card.photoUrls.isEmpty ? null : await _download(card.photoUrls.first, card.digipin);
  if (photo != null) {
    await Share.shareXFiles([XFile(photo.path)], text: text, subject: card.title);
  } else {
    await Share.share(text, subject: card.title);
  }
}

/// Shares a rendered QR code PNG for [card].
Future<void> shareCardQr(AddressCard card, Uint8List png) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/digiroutes-qr-${card.digipin}.png');
  await file.writeAsBytes(png, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'image/png')],
    text: '${card.title} — scan to open on DigiRoutes\n${card.shareUrl}',
    subject: '${card.title} QR code',
  );
}

Future<File?> _download(String url, String pin) async {
  try {
    final res = await ApiHttp.get(Uri.parse(url));
    if (res.statusCode != 200) return null;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/digiroutes-$pin.jpg');
    await file.writeAsBytes(res.bodyBytes, flush: true);
    return file;
  } catch (_) {
    return null;
  }
}
