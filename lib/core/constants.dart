/// Application-wide constants for DigiRoutes.
class AppConstants {
  AppConstants._();

  // ─── API ────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://digiroutes.vercel.app';

  static const String loginEndpoint   = '/api/auth/login';
  static const String signupEndpoint  = '/api/auth/signup';
  static const String logoutEndpoint  = '/api/auth/logout';
  static const String meEndpoint      = '/api/auth/me';
  static const String cardsEndpoint   = '/api/cards';
  static const String digipinEncode   = '/api/digipin/encode';
  static const String digipinDecode   = '/api/digipin/decode';
  static const String uploadEndpoint  = '/api/upload';

  // ─── Local Storage Keys ─────────────────────────────────────────────────
  static const String tokenKey      = 'dr_auth_token';
  static const String themeModeKey  = 'dr_theme_mode';

  // ─── Google Maps ─────────────────────────────────────────────────────────
  static const String mapsApiKey = 'AIzaSyCUIiQzaKZJ2VR8wRifGqEkxvkfhvsPRl4';

  // ─── Map defaults (India centre) ─────────────────────────────────────────
  static const double defaultLat = 20.5937;
  static const double defaultLng = 78.9629;
  static const double defaultZoom = 5.0;
  static const double detailZoom  = 17.0;

  // ─── App Info ─────────────────────────────────────────────────────────────
  static const String appName    = 'DigiRoutes';
  static const String appTagline = 'Share your exact doorstep';
  static const String cardShareBase = '$baseUrl/card';
}
