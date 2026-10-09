import 'package:digiroutes_app/data/models/address_card.dart';
import 'package:digiroutes_app/data/models/cards_page.dart';
import 'package:flutter_test/flutter_test.dart';

AddressCard card(String title,
        {String category = '', bool fav = false, String pin = 'ABCDEFGHJK'}) =>
    AddressCard.fromJson({
      '_id': title,
      'digipin': pin,
      'title': title,
      'category': category,
      'isFavorite': fav,
      'humanAddress': 'Street 5',
    });

void main() {
  group('CardsPage.fromJson', () {
    test('first page carries total and facets', () {
      final p = CardsPage.fromJson({
        'cards': [
          {'_id': '1', 'digipin': 'ABC', 'title': 'A'}
        ],
        'nextCursor': 'abc123',
        'hasMore': true,
        'total': 7,
        'facets': {'all': 12, 'favorites': 3, 'categories': ['home', 'shop']},
      });
      expect(p.cards.length, 1);
      expect(p.nextCursor, 'abc123');
      expect(p.hasMore, isTrue);
      expect(p.total, 7);
      expect(p.allCount, 12);
      expect(p.favoriteCount, 3);
      expect(p.categories, ['home', 'shop']);
    });

    test('later pages (and old backends) have no facets', () {
      final p = CardsPage.fromJson({'cards': [], 'nextCursor': null, 'hasMore': false});
      expect(p.hasMore, isFalse);
      expect(p.nextCursor, isNull);
      expect(p.total, isNull);
      expect(p.allCount, isNull);
      expect(p.categories, isNull);
    });
  });

  group('cardMatches (mirrors the server filters)', () {
    final shopFav = card('Corner Shop', category: 'shop', fav: true);
    final home = card('Flat 4B', category: 'home');

    test('filters by favorite and category', () {
      expect(cardMatches(shopFav, filter: 'fav'), isTrue);
      expect(cardMatches(home, filter: 'fav'), isFalse);
      expect(cardMatches(shopFav, filter: 'shop'), isTrue);
      expect(cardMatches(home, filter: 'shop'), isFalse);
      expect(cardMatches(home), isTrue);
    });

    test('searches title, address and DIGIPIN, ignoring case and spacing', () {
      expect(cardMatches(home, query: ' flat '), isTrue);
      expect(cardMatches(home, query: 'street'), isTrue);
      expect(cardMatches(home, query: 'abcdef'), isTrue);
      expect(cardMatches(home, query: 'nothing'), isFalse);
    });

    test('filter and search combine', () {
      expect(cardMatches(shopFav, filter: 'shop', query: 'corner'), isTrue);
      expect(cardMatches(shopFav, filter: 'home', query: 'corner'), isFalse);
    });
  });
}
