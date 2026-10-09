import 'package:flutter/material.dart';

/// A label users can put on a card. [id] is what the API stores.
class CardCategory {
  final String id;
  final String label;
  final IconData icon;
  const CardCategory(this.id, this.label, this.icon);
}

class CardCategories {
  CardCategories._();

  static const all = <CardCategory>[
    CardCategory('home', 'Home', Icons.home_rounded),
    CardCategory('work', 'Work', Icons.work_rounded),
    CardCategory('shop', 'Shop', Icons.storefront_rounded),
    CardCategory('family', 'Family', Icons.family_restroom_rounded),
    CardCategory('other', 'Other', Icons.place_rounded),
  ];

  /// Returns the category for [id], or null for "" / unknown.
  static CardCategory? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
