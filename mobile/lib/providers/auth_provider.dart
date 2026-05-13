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

  // ── Obtiene o crea el perfil de cliente y devuelve NOMBRES + APELLIDOS ──
  Future<void> _sincronizarPerfilCliente({
    String nombres = '',
    String apellidos = '',
  }) async {
    if (_usuario == null) return;

    int? cliId = _usuario!['CLI_ID'] ?? _usuario!['cli_id'];

    // Si no tiene cli_id: crear el perfil de cliente
    if (cliId == null) {
      try {
        final email    = (_usuario!['EMAIL']    ?? _usuario!['email']    ?? '').toString().trim();
        final username = (_usuario!['USERNAME'] ?? _usuario!['username'] ?? '').toString().trim();

        final res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cliente}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombres':        nombres.isNotEmpty ? nombres : username,
            'apellidos':      apellidos,
            'email':          email,
            'tipo_documento': null,
            'num_documento':  null,
            'nit':            null,
            'tel_residencia': null,
            'tel_celular':    null,
            'direccion':      null,
            'ciudad':         null,
            'departamento':   null,
            'pais':           null,
            'profesion':      null,
          }),
        );

        final resData = jsonDecode(res.body);
        if (res.statusCode == 201 && resData['ok'] == true) {
          cliId = resData['data']?['cli_id'] ?? resData['data']?['CLI_ID'];

          // Vincular cli_id en el usuario del backend
          if (cliId != null) {
            final usuId = _usuario!['USU_ID'] ?? _usuario!['usu_id'];
            await http.put(
              Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarios}/$usuId'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                ..._usuario!,
                'cli_id': cliId,
              }),
            );
            _usuario!['CLI_ID'] = cliId;
            _usuario!['cli_id'] = cliId;
          }
        }
      } catch (_) {}
    }

    // Si tiene cli_id (propio o recién creado): obtener nombre real del cliente
    if (cliId != null) {
      try {
        final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cliente}/$cliId'),
        );
        final resData = jsonDecode(res.body);
        if (res.statusCode == 200 && resData['ok'] == true) {
          final cli = resData['data'] is List
              ? (resData['data'] as List).first
              : resData['data'];
          if (cli != null) {
            final n = (cli['NOMBRES']   ?? cli['nombres']   ?? '').toString().trim();
            final a = (cli['APELLIDOS'] ?? cli['apellidos'] ?? '').toString().trim();

            // Si el perfil está vacío (usuario antiguo), actualizarlo con el username
            if (n.isEmpty) {
              final username = (_usuario!['USERNAME'] ?? _usuario!['username'] ?? '').toString().trim();
              await http.put(
                Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cliente}/$cliId'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  ...cli,
                  'nombres':   nombres.isNotEmpty ? nombres : username,
                  'apellidos': apellidos,
                }),
              );
              _usuario!['NOMBRES']   = nombres.isNotEmpty ? nombres : username;
              _usuario!['APELLIDOS'] = apellidos;
            } else {
              _usuario!['NOMBRES']   = n;
              _usuario!['APELLIDOS'] = a;
            }
          }
        }
      } catch (_) {}
    }

    // Persistir en SharedPreferences con los nombres actualizados
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(_usuario));
    notifyListeners();
  }
  // ─────────────────────────────────────────────────────────────────────────

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
        final rolId = _usuario?['rol_id'] ?? _usuario?['ROL_ID'];
        _role = (rolId == 27 || rolId == 28) ? UserRole.admin : UserRole.cliente;
        _isLoggedIn = true;

        // Guardar sesión base primero
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario', jsonEncode(_usuario));
        await prefs.setString('role', _role == UserRole.admin ? 'admin' : 'cliente');
        notifyListeners();

        // Sincronizar perfil de cliente en segundo plano (no bloquea el login)
        if (_role == UserRole.cliente) {
          _sincronizarPerfilCliente();
        }

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

  // Nombre para mostrar: cubre variantes singular/plural y mayúsculas del backend
  String get nombreCompleto {
    if (_usuario == null) return 'Administrador';
    final nombre = (_usuario!['NOMBRES']   ?? _usuario!['nombres']   ??
                    _usuario!['NOMBRE']    ?? _usuario!['nombre']    ?? '').toString().trim();
    final apellido = (_usuario!['APELLIDOS'] ?? _usuario!['apellidos'] ??
                      _usuario!['APELLIDO']  ?? _usuario!['apellido']  ?? '').toString().trim();
    final full = '$nombre $apellido'.trim();
    if (full.isNotEmpty) return full;
    return (_usuario!['USERNAME'] ?? _usuario!['username'] ?? 'Administrador').toString();
  }

  // Actualiza nombre/apellido/email en memoria y SharedPreferences
  Future<void> updatePerfil({
    required String nombre,
    required String apellido,
    required String email,
  }) async {
    if (_usuario == null) return;
    _usuario!['NOMBRES']   = nombre;
    _usuario!['nombres']   = nombre;
    _usuario!['APELLIDOS'] = apellido;
    _usuario!['apellidos'] = apellido;
    _usuario!['email']     = email;
    _usuario!['EMAIL']     = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(_usuario));
    notifyListeners();
  }
}
