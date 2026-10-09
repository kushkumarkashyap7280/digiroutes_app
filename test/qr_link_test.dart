import 'package:digiroutes_app/core/card_categories.dart';
import 'package:digiroutes_app/core/card_share.dart';
import 'package:digiroutes_app/data/models/address_card.dart';
import 'package:digiroutes_app/logic/digipin.dart';
import 'package:digiroutes_app/logic/qr_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pin = getDigiPin(28.6139, 77.2090); // New Delhi

  group('digipinFromScan', () {
    test('accepts DigiRoutes card and digipin links', () {
      expect(digipinFromScan('https://digiroutes.vercel.app/card/$pin'), pin);
      expect(digipinFromScan('https://digiroutes.vercel.app/digipin/$pin'), pin);
      expect(digipinFromScan('  https://digiroutes.vercel.app/card/$pin  '), pin);
      expect(
          digipinFromScan(
              'https://digiroutes.vercel.app/card/${pin.toLowerCase()}'),
          pin);
    });

    test('accepts a bare DIGIPIN with dashes, spaces and any case', () {
      final dashed =
          '${pin.substring(0, 3)}-${pin.substring(3, 6)}-${pin.substring(6)}';
      expect(digipinFromScan(pin), pin);
      expect(digipinFromScan(dashed.toLowerCase()), pin);
      expect(digipinFromScan(dashed.replaceAll('-', ' ')), pin);
    });

    test('rejects other sites, other paths and garbage', () {
      expect(digipinFromScan('https://evil.example.com/card/$pin'), isNull);
      expect(digipinFromScan('https://digiroutes.vercel.app/about'), isNull);
      expect(digipinFromScan('https://digiroutes.vercel.app/card/NOTAPIN123'),
          isNull);
      expect(digipinFromScan('hello world'), isNull);
      expect(digipinFromScan('1234567890'), isNull); // 0/1 are not DIGIPIN chars
      expect(digipinFromScan(''), isNull);
    });
  });

  group('card extras', () {
    test('parse with safe defaults and expose a WhatsApp number', () {
      final c = AddressCard.fromJson({
        '_id': '1',
        'digipin': pin,
        'category': 'shop',
        'deliveryNote': 'Ring twice',
        'contactPhone': '+91 98765-43210',
      });
      expect(c.category, 'shop');
      expect(c.deliveryNote, 'Ring twice');
      expect(c.whatsappNumber, '919876543210');

      final plain = AddressCard.fromJson({'_id': '2', 'digipin': pin});
      expect(plain.category, '');
      expect(plain.deliveryNote, '');
      expect(plain.contactPhone, '');
    });

    test('categories resolve by id and ignore unknown ones', () {
      expect(CardCategories.byId('home')?.label, 'Home');
      expect(CardCategories.byId(''), isNull);
      expect(CardCategories.byId('villa'), isNull);
    });

    test('share text includes the useful details and omits empty ones', () {
      final full = AddressCard.fromJson({
        '_id': '1',
        'digipin': pin,
        'title': 'Shop gate',
        'deliveryNote': 'Call before entering',
        'contactPhone': '+919876543210',
      });
      final text = cardShareText(full);
      expect(text, contains('Shop gate'));
      expect(text, contains(pin));
      expect(text, contains('Call before entering'));
      expect(text, contains('+919876543210'));
      expect(text, contains('google.com/maps?q='));
      expect(text, contains('digiroutes.vercel.app/card/$pin'));

      final bare = AddressCard.fromJson(
          {'_id': '2', 'digipin': pin, 'title': 'Plain'});
      final t2 = cardShareText(bare);
      expect(t2, isNot(contains('📝')));
      expect(t2, isNot(contains('📞')));
    });
  });
}
