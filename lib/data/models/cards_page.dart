import 'address_card.dart';

/// One page of the user's cards plus (on the first page) counts for the UI.
class CardsPage {
  final List<AddressCard> cards;
  final String? nextCursor;
  final bool hasMore;

  /// Cards matching the current search/filter (first page only).
  final int? total;

  /// Overall counts, independent of the filter (first page only).
  final int? allCount;
  final int? favoriteCount;
  final List<String>? categories;

  const CardsPage({
    required this.cards,
    required this.nextCursor,
    required this.hasMore,
    this.total,
    this.allCount,
    this.favoriteCount,
    this.categories,
  });

  factory CardsPage.fromJson(Map<String, dynamic> json) {
    final facets = json['facets'] as Map<String, dynamic>?;
    return CardsPage(
      cards: [
        for (final j in (json['cards'] as List? ?? const []))
          AddressCard.fromJson(j as Map<String, dynamic>),
      ],
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
      total: (json['total'] as num?)?.toInt(),
      allCount: (facets?['all'] as num?)?.toInt(),
      favoriteCount: (facets?['favorites'] as num?)?.toInt(),
      categories: facets == null
          ? null
          : List<String>.from(facets['categories'] as List? ?? const []),
    );
  }
}

/// Whether [card] belongs in the list for [filter] ('all' | 'fav' | a category
/// id) and search [query]. Mirrors the server-side filtering so the list can be
/// updated locally after an edit without a refetch.
bool cardMatches(AddressCard card, {String filter = 'all', String query = ''}) {
  if (filter == 'fav' && !card.isFavorite) return false;
  if (filter != 'all' && filter != 'fav' && card.category != filter) {
    return false;
  }
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return card.title.toLowerCase().contains(q) ||
      card.digipin.toLowerCase().contains(q) ||
      card.humanAddress.toLowerCase().contains(q);
}
