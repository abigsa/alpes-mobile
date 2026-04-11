import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

enum UserRole { cliente, admin, none }

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  UserRole _role = UserRole.none;
  Map<String, dynamic>? _usuario;
  String? _token;
  bool _loading = false;

  bool get isLoggedIn => _isLoggedIn;
  UserRole get role => _role;
  Map<String, dynamic>? get usuario => _usuario;
  String? get token => _token;
  bool get loading => _loading;
  bool get isAdmin => _role == UserRole.admin;
  bool get isCliente => _role == UserRole.cliente;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('usuario');
    final role = prefs.getString('role');
    if (userData != null && role != null) {
      _usuario = jsonDecode(userData);
      _role = role == 'admin' ? UserRole.admin : UserRole.cliente;
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarios}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['ok'] == true) {
        _usuario = data['data'];
        // Determinar rol: si rol_id == 1 o tiene flag de admin
        final rolId = _usuario?['rol_id'] ?? _usuario?['ROL_ID'];
        _role = (rolId != null && rolId != 3) ? UserRole.admin : UserRole.cliente;
        _isLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario', jsonEncode(_usuario));
        await prefs.setString('role', _role == UserRole.admin ? 'admin' : 'cliente');
        notifyListeners();
        return {'ok': true, 'role': _role};
      }
      return {'ok': false, 'mensaje': data['mensaje'] ?? 'Credenciales incorrectas'};
    } catch (e) {
      return {'ok': false, 'mensaje': 'Error de conexión: $e'};
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> registrar(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarios}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      final res = jsonDecode(response.body);
      if (response.statusCode == 201 && res['ok'] == true) {
        return {'ok': true};
      }
      return {'ok': false, 'mensaje': res['mensaje'] ?? 'Error al registrar'};
    } catch (e) {
      return {'ok': false, 'mensaje': 'Error de conexión: $e'};
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _role = UserRole.none;
    _usuario = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  int? get usuarioId {
    if (_usuario == null) return null;
    return _usuario!['usu_id'] ?? _usuario!['USU_ID'];
  }

  int? get clienteId {
    if (_usuario == null) return null;
    return _usuario!['cli_id'] ?? _usuario!['CLI_ID'];
  }

  // Nombre para mostrar: nombre + apellido si existen, sino username
  String get nombreCompleto {
    if (_usuario == null) return 'Administrador';
    final nombre   = _usuario!['nombre']   ?? _usuario!['NOMBRE']   ?? '';
    final apellido = _usuario!['apellido'] ?? _usuario!['APELLIDO'] ?? '';
    final full = '$nombre $apellido'.trim();
    if (full.isNotEmpty) return full;
    return _usuario!['USERNAME'] ?? _usuario!['username'] ?? 'Administrador';
  }

  // Actualiza nombre/apellido/email en memoria y SharedPreferences
  Future<void> updatePerfil({
    required String nombre,
    required String apellido,
    required String email,
  }) async {
    if (_usuario == null) return;
    _usuario!['nombre']   = nombre;
    _usuario!['NOMBRE']   = nombre;
    _usuario!['apellido'] = apellido;
    _usuario!['APELLIDO'] = apellido;
    _usuario!['email']    = email;
    _usuario!['EMAIL']    = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(_usuario));
    notifyListeners();
  }
}
