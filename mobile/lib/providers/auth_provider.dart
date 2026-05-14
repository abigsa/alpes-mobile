import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

enum UserRole { cliente, admin, none }

/// ✅ FIX PRINCIPAL: el getter clienteId ahora lee 'clienteId' (= CLI_ID del backend)
/// en lugar de 'usuarioId' (= USU_ID). Esto hace que favoritos, reseñas y perfil
/// funcionen correctamente porque todos filtran por CLI_ID.
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  UserRole _role = UserRole.none;
  Map<String, dynamic>? _usuario;
  String? _token;
  String? _refreshToken;
  bool _loading = false;

  bool get isLoggedIn => _isLoggedIn;
  UserRole get role => _role;
  Map<String, dynamic>? get usuario => _usuario;
  String? get token => _token;
  bool get loading => _loading;
  bool get isAdmin => _role == UserRole.admin;
  bool get isCliente => _role == UserRole.cliente;

  // ✅ FIX 1 & 4: clienteId ahora es el CLI_ID real, no el USU_ID
  int? get clienteId => _usuario?['clienteId'] as int?;
  String get nombreCompleto => _usuario?['nombre'] ?? 'Usuario';
  String? get email => _usuario?['email'] as String?;

  Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('usuario');
    final token = prefs.getString('token');
    final refreshToken = prefs.getString('refreshToken');

    if (userData != null && token != null) {
      _usuario = jsonDecode(userData);
      _token = token;
      _refreshToken = refreshToken;

      final rolNombre =
          (_usuario?['rol'] ?? '').toString().toUpperCase().trim();
      if (rolNombre == 'ADMIN' || rolNombre == 'ADMINISTRADOR') {
        _role = UserRole.admin;
      } else if (rolNombre.isNotEmpty) {
        _role = UserRole.cliente;
      } else {
        await prefs.clear();
        return;
      }
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(
      String username, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'contrasena': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['ok'] == true) {
        final userData = data['data'];

        _token = userData['accessToken'] ?? userData['token'];
        _refreshToken = userData['refreshToken'];

        // ✅ FIX: guardar cli_id como 'clienteId' separado de usuarioId
        _usuario = {
          'usuarioId': userData['usuarioId'],   // USU_ID (para operaciones de usuario)
          'clienteId': userData['cli_id'],       // CLI_ID (para filtros de cliente)
          'nombre': userData['nombre'],
          'email': userData['email'],
          'rol': userData['rol'],
          'USERNAME': username,
        };

        final rolNombre =
            (_usuario?['rol'] ?? '').toString().toUpperCase().trim();
        _role = (rolNombre == 'ADMINISTRADOR' || rolNombre == 'ADMIN')
            ? UserRole.admin
            : UserRole.cliente;

        _isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario', jsonEncode(_usuario));
        await prefs.setString('token', _token ?? '');
        await prefs.setString('refreshToken', _refreshToken ?? '');

        notifyListeners();
        return {'ok': true, 'role': _role};
      }

      return {
        'ok': false,
        'mensaje': data['message'] ?? 'Credenciales incorrectas'
      };
    } catch (e) {
      return {'ok': false, 'mensaje': 'Error de conexión: $e'};
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> registrar(
      Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registro}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      final res = jsonDecode(response.body);
      if (response.statusCode == 201) return {'ok': true};
      return {
        'ok': false,
        'mensaje': res['message'] ?? 'Error al registrar'
      };
    } catch (e) {
      return {'ok': false, 'mensaje': 'Error de conexión: $e'};
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updatePerfil({
    String? nombre,
    String? apellido,
    String? email,
    String? telefono,
    Map<String, dynamic>? data,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final updateData = data ?? {};
      if (nombre != null) updateData['nombre'] = nombre;
      if (apellido != null) updateData['apellido'] = apellido;
      if (email != null) updateData['email'] = email;
      if (telefono != null) updateData['telefono'] = telefono;

      // ✅ Usa usuarioId para actualizar datos de usuario
      final response = await http.put(
        Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.usuarios}/${_usuario?['usuarioId']}'),
        headers: authHeaders,
        body: jsonEncode(updateData),
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (nombre != null) _usuario?['nombre'] = nombre;
        if (email != null) _usuario?['email'] = email;
        if (telefono != null) _usuario?['telefono'] = telefono;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario', jsonEncode(_usuario));

        notifyListeners();
        return {'ok': true};
      }
      return {
        'ok': false,
        'mensaje': res['message'] ?? 'Error al actualizar'
      };
    } catch (e) {
      return {'ok': false, 'mensaje': 'Error de conexión: $e'};
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshToken}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token =
            data['data']['accessToken'] ?? data['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token ?? '');
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logout}'),
        headers: authHeaders,
      );
    } catch (_) {}

    _isLoggedIn = false;
    _role = UserRole.none;
    _token = null;
    _refreshToken = null;
    _usuario = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }
}
