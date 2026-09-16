import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

/// Manages JWT token persistence in SharedPreferences.
class TokenStorage {
  static Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await get();
    return token != null && token.isNotEmpty;
  }
}
