import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Cliente HTTP global — agrega JWT + x-api-key en cada request automáticamente.
/// Usar siempre ApiClient.get/post/put/patch/delete en lugar de http directo.
class ApiClient {
  static String? _token;

  static void setToken(String? token) => _token = token;

  // Headers para POST / PUT / PATCH
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': ApiConfig.apiKey,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // Headers para GET / DELETE (sin Content-Type)
  static Map<String, String> get _getHeaders => {
        'x-api-key': ApiConfig.apiKey,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<http.Response> get(String url) =>
      http.get(Uri.parse(url), headers: _getHeaders);

  static Future<http.Response> post(String url, {Object? body}) =>
      http.post(
        Uri.parse(url),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

  static Future<http.Response> put(String url, {Object? body}) =>
      http.put(
        Uri.parse(url),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

  static Future<http.Response> patch(String url, {Object? body}) =>
      http.patch(
        Uri.parse(url),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

  static Future<http.Response> delete(String url) =>
      http.delete(Uri.parse(url), headers: _getHeaders);
}
