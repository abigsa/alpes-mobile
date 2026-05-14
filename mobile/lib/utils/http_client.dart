import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente HTTP global que agrega el token JWT automáticamente.
/// Uso: ApiClient.get(url) en lugar de http.get(Uri.parse(url))
class ApiClient {
  static String? _token;

  /// Llamar después del login con auth.token
  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Map<String, String> get _getHeaders => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<http.Response> get(String url) =>
      http.get(Uri.parse(url), headers: _getHeaders);

  static Future<http.Response> post(String url, {Object? body}) =>
      http.post(Uri.parse(url), headers: _headers, body: body != null ? jsonEncode(body) : null);

  static Future<http.Response> put(String url, {Object? body}) =>
      http.put(Uri.parse(url), headers: _headers, body: body != null ? jsonEncode(body) : null);

  static Future<http.Response> delete(String url) =>
      http.delete(Uri.parse(url), headers: _getHeaders);
}
