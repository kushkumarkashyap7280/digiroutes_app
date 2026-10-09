import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/api_http.dart';
import '../models/address_card.dart';
import '../local/token_storage.dart';
import '../../core/constants.dart';

class CardsException implements Exception {
  final String message;
  const CardsException(this.message);
  @override
  String toString() => message;
}

/// Repository for AddressCard CRUD and image upload.
class CardsRepository {
  static final _base = Uri.parse(AppConstants.baseUrl);

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.get();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch a paginated list of the user's address cards.
  /// Returns `(cards, nextCursor, hasMore)`.
  Future<({List<AddressCard> cards, String? nextCursor, bool hasMore})>
      getCards({String? cursor, int limit = 12}) async {
    final headers = await _authHeaders();
    final uri = _base.replace(
      path: AppConstants.cardsEndpoint,
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': '$limit',
      },
    );
    final res = await ApiHttp.get(uri, headers: headers);

    if (res.statusCode == 401)
      throw const CardsException('Please log in first.');
    if (res.statusCode != 200)
      throw const CardsException('Failed to load cards.');

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = data['cards'] as List? ?? [];
    return (
      cards: raw
          .map((j) => AddressCard.fromJson(j as Map<String, dynamic>))
          .toList(),
      nextCursor: data['nextCursor'] as String?,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  /// Fetch a single public card by [digipin].
  Future<AddressCard?> getCardByDigipin(String digipin) async {
    final res = await ApiHttp.get(
      _base.replace(path: '${AppConstants.cardsEndpoint}/digipin/$digipin'),
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200)
      throw const CardsException('Failed to load card.');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AddressCard.fromJson(data['card'] as Map<String, dynamic>);
  }

  /// Create a new address card.
  Future<AddressCard> createCard({
    required String digipin,
    required String title,
    String humanAddress = '',
    List<String> photoUrls = const [],
    List<String> photoIds = const [],
    String category = '',
    String deliveryNote = '',
    String contactPhone = '',
  }) async {
    final headers = await _authHeaders();
    final res = await ApiHttp.post(
      _base.replace(path: AppConstants.cardsEndpoint),
      headers: headers,
      body: jsonEncode({
        'digipin': digipin,
        'title': title,
        'humanAddress': humanAddress,
        'photoUrls': photoUrls,
        'photoIds': photoIds,
        'category': category,
        'deliveryNote': deliveryNote,
        'contactPhone': contactPhone,
      }),
    );

    if (res.statusCode == 401)
      throw const CardsException('Please log in first.');
    if (res.statusCode != 201) {
      throw CardsException(ApiHttp.errorMessage(res, 'Failed to create card.'));
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AddressCard.fromJson(data['card'] as Map<String, dynamic>);
  }

  /// Delete a card by [id].
  Future<void> deleteCard(String id) async {
    final headers = await _authHeaders();
    final res = await ApiHttp.delete(
      _base.replace(path: '${AppConstants.cardsEndpoint}/$id'),
      headers: headers,
    );
    if (res.statusCode != 200)
      throw const CardsException('Failed to delete card.');
  }

  /// Update a card. Only non-null fields are sent.
  Future<AddressCard> updateCard(
    String id, {
    String? title,
    String? humanAddress,
    List<String>? photoUrls,
    List<String>? photoIds,
    bool? isFavorite,
    String? category,
    String? deliveryNote,
    String? contactPhone,
  }) async {
    final headers = await _authHeaders();
    final res = await ApiHttp.put(
      _base.replace(path: '${AppConstants.cardsEndpoint}/$id'),
      headers: headers,
      body: jsonEncode({
        if (title != null) 'title': title,
        if (humanAddress != null) 'humanAddress': humanAddress,
        if (photoUrls != null) 'photoUrls': photoUrls,
        if (photoIds != null) 'photoIds': photoIds,
        if (isFavorite != null) 'isFavorite': isFavorite,
        if (category != null) 'category': category,
        if (deliveryNote != null) 'deliveryNote': deliveryNote,
        if (contactPhone != null) 'contactPhone': contactPhone,
      }),
    );
    if (res.statusCode == 401)
      throw const CardsException('Please log in first.');
    if (res.statusCode != 200) {
      throw CardsException(ApiHttp.errorMessage(res, 'Failed to update card.'));
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AddressCard.fromJson(data['card'] as Map<String, dynamic>);
  }

  /// Max accepted image size (matches the web client).
  static const int maxImageBytes = 4 * 1024 * 1024;

  /// Upload an image straight to Cloudinary using signed params from the
  /// backend (`/api/upload/sign`). Returns `{ url, publicId }`.
  Future<({String url, String publicId})> uploadImage(File imageFile) async {
    if (await imageFile.length() > maxImageBytes) {
      throw const CardsException('Image is larger than 4MB.');
    }

    final signRes = await ApiHttp.post(
      _base.replace(path: '${AppConstants.uploadEndpoint}/sign'),
      headers: await _authHeaders(),
    );
    if (signRes.statusCode != 200) {
      String? msg;
      try {
        msg = (jsonDecode(signRes.body) as Map<String, dynamic>)['error']
            as String?;
      } catch (_) {}
      throw CardsException(msg ?? 'Could not start image upload.');
    }
    final sign = jsonDecode(signRes.body) as Map<String, dynamic>;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://api.cloudinary.com/v1_1/${sign['cloud_name']}/image/upload'),
    )
      ..fields['timestamp'] = '${sign['timestamp']}'
      ..fields['signature'] = sign['signature'] as String
      ..fields['api_key'] = '${sign['api_key']}'
      ..fields['folder'] = sign['folder'] as String
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final res = await ApiHttp.sendMultipart(request);
    if (res.statusCode != 200)
      throw const CardsException('Image upload failed. Check your connection and try again.');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      url: data['secure_url'] as String,
      publicId: data['public_id'] as String,
    );
  }
}
