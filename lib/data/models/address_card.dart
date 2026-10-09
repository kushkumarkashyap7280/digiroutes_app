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

  // ── Sharing (owner view only; absent on cards seen through a share link) ──
  final String shareToken; // random id used in https://…/c/<token> links
  final bool sharingEnabled; // false = link is switched off, card is private
  final DateTime? shareExpiresAt; // link stops working after this time
  final bool hidePhone; // omit the phone from the shared view
  final bool legacyPublic; // old DIGIPIN-based link still works until reset
  final int viewCount; // times the shared link was opened
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
    this.shareToken = '',
    this.sharingEnabled = true,
    this.shareExpiresAt,
    this.hidePhone = false,
    this.legacyPublic = false,
    this.viewCount = 0,
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
      shareToken: json['shareToken'] as String? ?? '',
      sharingEnabled: json['sharingEnabled'] as bool? ?? true,
      shareExpiresAt: json['shareExpiresAt'] != null
          ? DateTime.tryParse(json['shareExpiresAt'] as String)
          : null,
      hidePhone: json['hidePhone'] as bool? ?? false,
      legacyPublic: json['legacyPublic'] as bool? ?? false,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
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
        'shareToken': shareToken,
        'sharingEnabled': sharingEnabled,
        'shareExpiresAt': shareExpiresAt?.toIso8601String(),
        'hidePhone': hidePhone,
        'legacyPublic': legacyPublic,
        'viewCount': viewCount,
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
    bool? sharingEnabled,
    bool? hidePhone,
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
        shareToken: shareToken,
        sharingEnabled: sharingEnabled ?? this.sharingEnabled,
        shareExpiresAt: shareExpiresAt,
        hidePhone: hidePhone ?? this.hidePhone,
        legacyPublic: legacyPublic,
        viewCount: viewCount,
        createdAt: createdAt,
      );

  /// The link to hand out. Uses the private token when the card has one; the
  /// DIGIPIN-based form is only a fallback for cards without a token yet.
  String get shareUrl => shareToken.isNotEmpty
      ? 'https://digiroutes.vercel.app/c/$shareToken'
      : 'https://digiroutes.vercel.app/card/$digipin';

  /// Link is switched on and not expired (owner view).
  bool get isShareActive =>
      sharingEnabled &&
      (shareExpiresAt == null || shareExpiresAt!.isAfter(DateTime.now()));

  /// Digits only, for wa.me links (no '+').
  String get whatsappNumber => contactPhone.replaceAll(RegExp(r'[^0-9]'), '');
}
