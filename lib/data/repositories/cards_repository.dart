import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/api_http.dart';
import '../models/address_card.dart';
import '../models/cards_page.dart';
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

  /// Fetch one page of the user's cards (cursor pagination, newest first).
  /// [q] searches title / address / DIGIPIN; [filter] is 'all', 'fav' or a
  /// category id — both are applied on the server so they cover every page.
  Future<CardsPage> getCards({
    String? cursor,
    int limit = 12,
    String q = '',
    String filter = 'all',
  }) async {
    final headers = await _authHeaders();
    final uri = _base.replace(
      path: AppConstants.cardsEndpoint,
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': '$limit',
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (filter == 'fav') 'favorite': 'true',
        if (filter != 'all' && filter != 'fav') 'category': filter,
      },
    );
    final res = await ApiHttp.get(uri, headers: headers);

    if (res.statusCode == 401) {
      throw const CardsException('Please log in first.');
    }
    if (res.statusCode != 200) {
      throw CardsException(ApiHttp.errorMessage(res, 'Failed to load cards.'));
    }
    return CardsPage.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Best-effort: delete photos that were uploaded but never attached to a card
  /// or profile (the save failed afterwards). The server only deletes ids in
  /// the caller's own folder that are not in use, so this is safe to call.
  Future<void> discardUploads(Iterable<String> publicIds) async {
    final ids = publicIds.where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return;
    try {
      await ApiHttp.post(
        _base.replace(path: '${AppConstants.uploadEndpoint}/cleanup'),
        headers: await _authHeaders(),
        body: jsonEncode({'publicIds': ids}),
      );
    } catch (_) {/* nothing more we can do; never mask the original error */}
  }

  /// One of the signed-in user's own cards, with its sharing settings.
  Future<AddressCard?> getOwnCard(String id) async {
    final res = await ApiHttp.get(
      _base.replace(path: '${AppConstants.cardsEndpoint}/$id'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 404 || res.statusCode == 401) return null;
    if (res.statusCode != 200) {
      throw CardsException(ApiHttp.errorMessage(res, 'Failed to load card.'));
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AddressCard.fromJson(data['card'] as Map<String, dynamic>);
  }

  /// The card behind a private share link (no login needed). Null when the
  /// link is switched off, expired, reset or unknown.
  Future<AddressCard?> getSharedCard(String token) async {
    final res = await ApiHttp.get(
      _base.replace(path: '${AppConstants.cardsEndpoint}/shared/$token'),
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw CardsException(ApiHttp.errorMessage(res, 'Failed to load card.'));
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AddressCard.fromJson(data['card'] as Map<String, dynamic>);
  }

  /// Fetch a single card by [digipin]. The server only returns it to its
  /// signed-in owner, or for older cards whose link hasn't been reset yet.
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
    bool? sharingEnabled,
    bool? hidePhone,
    String? shareExpiry, // 'none' | '24h' | '7d'
    bool resetShareLink = false,
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
        if (sharingEnabled != null) 'sharingEnabled': sharingEnabled,
        if (hidePhone != null) 'hidePhone': hidePhone,
        if (shareExpiry != null) 'shareExpiry': shareExpiry,
        if (resetShareLink) 'resetShareLink': true,
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
