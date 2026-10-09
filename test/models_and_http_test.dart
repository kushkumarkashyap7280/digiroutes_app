import 'package:digiroutes_app/core/api_http.dart';
import 'package:digiroutes_app/data/models/address_card.dart';
import 'package:digiroutes_app/data/models/user.dart';
import 'package:digiroutes_app/data/repositories/auth_repository.dart';
import 'package:digiroutes_app/data/repositories/cards_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('AddressCard', () {
    test('parses favorites and defaults to not favorite', () {
      final fav = AddressCard.fromJson({
        '_id': '1', 'digipin': 'abc', 'title': 'Home', 'isFavorite': true,
      });
      final plain = AddressCard.fromJson({'_id': '2', 'digipin': 'xyz'});
      expect(fav.isFavorite, isTrue);
      expect(fav.digipin, 'ABC'); // normalised to upper case
      expect(plain.isFavorite, isFalse);
      expect(plain.photoUrls, isEmpty);
    });

    test('copyWith changes only the given fields', () {
      final c = AddressCard.fromJson({'_id': '1', 'digipin': 'ABC', 'title': 'A'});
      final f = c.copyWith(isFavorite: true);
      expect(f.isFavorite, isTrue);
      expect(f.title, 'A');
      expect(f.id, '1');
    });
  });

  group('AppUser', () {
    test('initials from a one- and two-word name', () {
      expect(const AppUser(id: '1', email: 'a@b.c', name: 'kush kumar').initials, 'KK');
      expect(const AppUser(id: '1', email: 'a@b.c', name: 'k').initials, 'K');
      expect(const AppUser(id: '1', email: 'a@b.c', name: '').initials, '?');
    });

    test('round-trips through json including avatar', () {
      final u = AppUser.fromJson(const AppUser(
        id: '1', email: 'a@b.c', name: 'N', avatarUrl: 'u', avatarId: 'i',
      ).toJson());
      expect(u.avatarUrl, 'u');
      expect(u.avatarId, 'i');
    });
  });

  group('ApiHttp.errorMessage', () {
    test('uses the server error field', () {
      final r = http.Response('{"error":"Email already registered."}', 409);
      expect(ApiHttp.errorMessage(r, 'fallback'), 'Email already registered.');
    });

    test('handles rate limiting, server errors and non-JSON bodies', () {
      expect(ApiHttp.errorMessage(http.Response('<html>', 429), 'f'),
          contains('Too many attempts'));
      expect(ApiHttp.errorMessage(http.Response('<html>', 502), 'f'),
          contains('Server error'));
      expect(ApiHttp.errorMessage(http.Response('<html>', 400), 'fallback'),
          'fallback');
    });

    test('NetworkException is caught by both repository handlers', () {
      const e = NetworkException('offline');
      expect(e, isA<AuthException>());
      expect(e, isA<CardsException>());
    });
  });
}
