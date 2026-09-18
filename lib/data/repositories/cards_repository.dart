import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 401) throw CardsException('Please log in first.');
    if (res.statusCode != 200) throw CardsException('Failed to load cards.');

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = data['cards'] as List? ?? [];
    return (
      cards:      raw.map((j) => AddressCard.fromJson(j as Map<String, dynamic>)).toList(),
      nextCursor: data['nextCursor'] as String?,
      hasMore:    data['hasMore'] as bool? ?? false,
    );
  }

  /// Fetch a single public card by [digipin].
  Future<AddressCard?> getCardByDigipin(String digipin) async {
    final res = await http.get(
      _base.replace(path: '${AppConstants.cardsEndpoint}/digipin/$digipin'),
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw CardsException('Failed to load card.');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AddressCard.fromJson(data['card'] as Map<String, dynamic>);
  }

  /// Create a new address card.
  Future<AddressCard> createCard({
    required String digipin,
    required String title,
    String humanAddress = '',
    List<String> photoUrls = const [],
    List<String> photoIds  = const [],
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      _base.replace(path: AppConstants.cardsEndpoint),
      headers: headers,
      body: jsonEncode({
        'digipin':      digipin,
        'title':        title,
        'humanAddress': humanAddress,
        'photoUrls':    photoUrls,
        'photoIds':     photoIds,
      }),
    );

    if (res.statusCode == 401) throw CardsException('Please log in first.');
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw CardsException(body['error'] as String? ?? 'Failed to create card.');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AddressCard.fromJson(data['card'] as Map<String, dynamic>);
  }

  /// Delete a card by [id].
  Future<void> deleteCard(String id) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      _base.replace(path: '${AppConstants.cardsEndpoint}/$id'),
      headers: headers,
    );
    if (res.statusCode != 200) throw CardsException('Failed to delete card.');
  }

  /// Upload an image file to Cloudinary via the backend.
  /// Returns the Cloudinary `{ url, publicId }`.
  Future<({String url, String publicId})> uploadImage(File imageFile) async {
    final token = await TokenStorage.get();
    final request = http.MultipartRequest(
      'POST',
      _base.replace(path: AppConstants.uploadEndpoint),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) throw CardsException('Image upload failed.');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      url:      data['url'] as String,
      publicId: data['publicId'] as String,
    );
  }
}
