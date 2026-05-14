import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class FavoritosProvider extends ChangeNotifier {
  final Set<int> _favoritosIds = {};
  bool _loading = false;
  String? _token; // ✅ token para autenticar requests

  Set<int> get favoritosIds => _favoritosIds;
  bool get loading => _loading;
  bool esFavorito(int productoId) => _favoritosIds.contains(productoId);

  // ✅ llamado automáticamente por ProxyProvider en main.dart
  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Map<String, String> get _getHeaders => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<void> cargarFavoritos(int clienteId) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.listaDeseseos}/buscar?criterio=cli_id&valor=$clienteId'),
        headers: _getHeaders, // ✅
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        _favoritosIds.clear();
        for (final f in data['data']) {
          final pid = f['PRODUCTO_ID'] ?? f['producto_id'];
          if (pid != null) _favoritosIds.add(pid);
        }
      }
    } catch (_) {} finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorito({
    required int clienteId,
    required int productoId,
  }) async {
    if (_favoritosIds.contains(productoId)) {
      _favoritosIds.remove(productoId);
      notifyListeners();
      await _eliminarFavorito(clienteId, productoId);
    } else {
      _favoritosIds.add(productoId);
      notifyListeners();
      await _agregarFavorito(clienteId, productoId);
    }
  }

  Future<void> _agregarFavorito(int clienteId, int productoId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.listaDeseseos}'),
        headers: _headers, // ✅
        body: jsonEncode({
          'cli_id': clienteId,
          'producto_id': productoId,
          'nota': '',
        }),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] != true) {
        _favoritosIds.remove(productoId);
        notifyListeners();
      }
    } catch (_) {
      _favoritosIds.remove(productoId);
      notifyListeners();
    }
  }

  Future<void> _eliminarFavorito(int clienteId, int productoId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.listaDeseseos}/buscar?criterio=cli_id&valor=$clienteId'),
        headers: _getHeaders, // ✅
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final lista = data['data'] as List;
        Map<String, dynamic>? favorito;
        for (final f in lista) {
          if ((f['PRODUCTO_ID'] ?? f['producto_id']) == productoId) {
            favorito = f as Map<String, dynamic>;
            break;
          }
        }
        if (favorito != null) {
          final id = favorito['LISTA_DESEOS_ID'] ?? favorito['lista_deseos_id'];
          await http.delete(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.listaDeseseos}/$id'),
            headers: _getHeaders, // ✅
          );
        } else {
          _favoritosIds.add(productoId);
          notifyListeners();
        }
      }
    } catch (_) {
      _favoritosIds.add(productoId);
      notifyListeners();
    }
  }
}
