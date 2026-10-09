import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../data/repositories/auth_repository.dart' show AuthException;
import '../data/repositories/cards_repository.dart' show CardsException;

/// Thrown when the server can't be reached (offline, DNS, timeout).
/// Implements both repository exceptions so existing
/// `on AuthException` / `on CardsException` handlers show its message.
class NetworkException implements AuthException, CardsException {
  @override
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => message;
}

/// Thin wrapper around `package:http` that adds a timeout and turns
/// low-level failures into [NetworkException]s with readable messages.
class ApiHttp {
  ApiHttp._();

  static const _timeout = Duration(seconds: 15);
  static const _uploadTimeout = Duration(seconds: 90);

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      _run(() => http.get(url, headers: headers), _timeout);

  static Future<http.Response> post(Uri url,
          {Map<String, String>? headers, Object? body}) =>
      _run(() => http.post(url, headers: headers, body: body), _timeout);

  static Future<http.Response> put(Uri url,
          {Map<String, String>? headers, Object? body}) =>
      _run(() => http.put(url, headers: headers, body: body), _timeout);

  static Future<http.Response> delete(Uri url,
          {Map<String, String>? headers, Object? body}) =>
      _run(() => http.delete(url, headers: headers, body: body), _timeout);

  /// Sends a multipart request (image upload) with a longer timeout.
  static Future<http.Response> sendMultipart(http.MultipartRequest request) =>
      _run(() async => http.Response.fromStream(await request.send()),
          _uploadTimeout);

  /// Best human-readable message for a failed response: the server's own
  /// `error` field when present, otherwise something sensible for the status.
  static String errorMessage(http.Response res, String fallback) {
    try {
      final b = jsonDecode(res.body);
      if (b is Map && b['error'] is String) return b['error'] as String;
    } catch (_) {/* non-JSON body (proxy/HTML error page) */}
    if (res.statusCode == 429) {
      return 'Too many attempts. Please wait a bit and try again.';
    }
    if (res.statusCode >= 500) {
      return 'Server error. Please try again shortly.';
    }
    return fallback;
  }

  static Future<http.Response> _run(
      Future<http.Response> Function() call, Duration timeout) async {
    try {
      return await call().timeout(timeout);
    } on TimeoutException {
      throw const NetworkException(
          'The server is taking too long to respond. Please try again.');
    } on SocketException {
      throw const NetworkException(
          'No internet connection. Check your network and try again.');
    } on http.ClientException {
      throw const NetworkException(
          'Could not reach the server. Please try again.');
    }
  }
}
