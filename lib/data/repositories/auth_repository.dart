import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../local/token_storage.dart';
import '../../core/constants.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

/// Repository for all authentication API calls.
class AuthRepository {
  static final _base = Uri.parse(AppConstants.baseUrl);

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.get();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Login with [email] and [password].
  /// Returns [AppUser] and saves the token locally.
  Future<AppUser> login(String email, String password) async {
    final res = await http.post(
      _base.replace(path: AppConstants.loginEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw AuthException(body['error'] as String? ?? 'Login failed.');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    // Save token if returned by the API (Phase 2 backend change)
    if (data['token'] != null) {
      await TokenStorage.save(data['token'] as String);
    }

    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Sign up with [name], [email], and [password].
  Future<AppUser> signup(String name, String email, String password) async {
    final res = await http.post(
      _base.replace(path: AppConstants.signupEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw AuthException(body['error'] as String? ?? 'Signup failed.');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (data['token'] != null) {
      await TokenStorage.save(data['token'] as String);
    }

    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Fetch the currently authenticated user.
  Future<AppUser?> getMe() async {
    final headers = await _authHeaders();
    final res = await http.get(
      _base.replace(path: AppConstants.meEndpoint),
      headers: headers,
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    return AppUser.fromJson(userJson);
  }

  /// Logout — clears local token.
  Future<void> logout() async {
    await TokenStorage.clear();
  }
}
