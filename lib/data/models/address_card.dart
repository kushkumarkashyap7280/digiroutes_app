/// AddressCard data model — mirrors the Mongoose AddressCard schema.
class AddressCard {
  final String id;
  final String digipin;
  final String ownerId;
  final String title;
  final List<String> photoUrls;
  final List<String> photoIds;
  final String humanAddress;
  final DateTime createdAt;

  const AddressCard({
    required this.id,
    required this.digipin,
    required this.ownerId,
    required this.title,
    required this.photoUrls,
    required this.photoIds,
    required this.humanAddress,
    required this.createdAt,
  });

  factory AddressCard.fromJson(Map<String, dynamic> json) {
    return AddressCard(
      id:           json['_id'] as String? ?? '',
      digipin:      (json['digipin'] as String? ?? '').toUpperCase(),
      ownerId:      json['ownerId'] as String? ?? '',
      title:        json['title'] as String? ?? '',
      photoUrls:    List<String>.from(json['photoUrls'] as List? ?? []),
      photoIds:     List<String>.from(json['photoIds']  as List? ?? []),
      humanAddress: json['humanAddress'] as String? ?? '',
      createdAt:    json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id':          id,
    'digipin':      digipin,
    'ownerId':      ownerId,
    'title':        title,
    'photoUrls':    photoUrls,
    'photoIds':     photoIds,
    'humanAddress': humanAddress,
    'createdAt':    createdAt.toIso8601String(),
  };

  AddressCard copyWith({
    String? title,
    List<String>? photoUrls,
    List<String>? photoIds,
    String? humanAddress,
  }) =>
      AddressCard(
        id:           id,
        digipin:      digipin,
        ownerId:      ownerId,
        title:        title ?? this.title,
        photoUrls:    photoUrls ?? this.photoUrls,
        photoIds:     photoIds ?? this.photoIds,
        humanAddress: humanAddress ?? this.humanAddress,
        createdAt:    createdAt,
      );

  /// Returns the public share URL for this card.
  String get shareUrl => 'https://digiroutes.vercel.app/card/$digipin';
}
