import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../models/user.dart';

/// Persists the JWT in the platform keystore (Android Keystore / iOS Keychain).
///
/// Versions up to 1.2.1 kept the token in plain SharedPreferences; [get]
/// migrates such a token into secure storage on first read so users stay
/// logged in after updating.
class TokenStorage {
  static const _secure = FlutterSecureStorage();

  static Future<void> save(String token) async {
    await _secure.write(key: AppConstants.tokenKey, value: token);
    await _removeLegacy();
  }

  static Future<String?> get() async {
    try {
      final stored = await _secure.read(key: AppConstants.tokenKey);
      if (stored != null && stored.isNotEmpty) return stored;
    } catch (_) {
      // Keystore data became unreadable (e.g. restored from a backup onto a
      // new device). Treat as logged out rather than crashing.
      await _secure.deleteAll();
    }

    // One-time migration from the old plain-text location.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(AppConstants.tokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secure.write(key: AppConstants.tokenKey, value: legacy);
      await prefs.remove(AppConstants.tokenKey);
      return legacy;
    }
    return null;
  }

  static Future<void> clear() async {
    await _secure.delete(key: AppConstants.tokenKey);
    await _removeLegacy();
  }

  static Future<bool> hasToken() async {
    final token = await get();
    return token != null && token.isNotEmpty;
  }

  static Future<void> _removeLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
  }
}

/// Last known profile, so the app can stay signed in (and show the user's
/// name/avatar) when the server can't be reached. Holds no credentials.
class UserCache {
  static const _key = 'dr_cached_user';

  static Future<void> save(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }

  static Future<AppUser?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
