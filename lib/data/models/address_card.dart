/// AddressCard data model — mirrors the Mongoose AddressCard schema.
class AddressCard {
  final String id;
  final String digipin;
  final String ownerId;
  final String title;
  final List<String> photoUrls;
  final List<String> photoIds;
  final String humanAddress;
  final bool isFavorite;
  final String category; // '' or home | work | shop | family | other
  final String deliveryNote; // instructions for whoever is visiting
  final String contactPhone; // digits with optional +, e.g. +919876543210
  final DateTime createdAt;

  const AddressCard({
    required this.id,
    required this.digipin,
    required this.ownerId,
    required this.title,
    required this.photoUrls,
    required this.photoIds,
    required this.humanAddress,
    this.isFavorite = false,
    this.category = '',
    this.deliveryNote = '',
    this.contactPhone = '',
    required this.createdAt,
  });

  factory AddressCard.fromJson(Map<String, dynamic> json) {
    return AddressCard(
      id: json['_id'] as String? ?? '',
      digipin: (json['digipin'] as String? ?? '').toUpperCase(),
      ownerId: json['ownerId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      photoUrls: List<String>.from(json['photoUrls'] as List? ?? []),
      photoIds: List<String>.from(json['photoIds'] as List? ?? []),
      humanAddress: json['humanAddress'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
      category: json['category'] as String? ?? '',
      deliveryNote: json['deliveryNote'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'digipin': digipin,
        'ownerId': ownerId,
        'title': title,
        'photoUrls': photoUrls,
        'photoIds': photoIds,
        'humanAddress': humanAddress,
        'isFavorite': isFavorite,
        'category': category,
        'deliveryNote': deliveryNote,
        'contactPhone': contactPhone,
        'createdAt': createdAt.toIso8601String(),
      };

  AddressCard copyWith({
    String? title,
    List<String>? photoUrls,
    List<String>? photoIds,
    String? humanAddress,
    bool? isFavorite,
    String? category,
    String? deliveryNote,
    String? contactPhone,
  }) =>
      AddressCard(
        id: id,
        digipin: digipin,
        ownerId: ownerId,
        title: title ?? this.title,
        photoUrls: photoUrls ?? this.photoUrls,
        photoIds: photoIds ?? this.photoIds,
        humanAddress: humanAddress ?? this.humanAddress,
        isFavorite: isFavorite ?? this.isFavorite,
        category: category ?? this.category,
        deliveryNote: deliveryNote ?? this.deliveryNote,
        contactPhone: contactPhone ?? this.contactPhone,
        createdAt: createdAt,
      );

  /// Returns the public share URL for this card.
  String get shareUrl => 'https://digiroutes.vercel.app/card/$digipin';

  /// Digits only, for wa.me links (no '+').
  String get whatsappNumber => contactPhone.replaceAll(RegExp(r'[^0-9]'), '');
}
