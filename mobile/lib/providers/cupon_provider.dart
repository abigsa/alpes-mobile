import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CuponProvider extends ChangeNotifier {
  // Estado
  Map<String, dynamic>? _cuponAplicado;
  double _descuentoAplicado = 0;
  String? _mensajeCupon;
  bool _cargando = false;
  List<Map<String, dynamic>> _cupones = [];

  // Getters
  Map<String, dynamic>? get cuponAplicado => _cuponAplicado;
  double get descuentoAplicado => _descuentoAplicado;
  String? get mensajeCupon => _mensajeCupon;
  bool get cargando => _cargando;
  List<Map<String, dynamic>> get cupones => _cupones;

  // Validar cupón en checkout
  Future<bool> validarCupon(String codigo, double montoTotal) async {
    _cargando = true;
    _mensajeCupon = null;
    _cuponAplicado = null;
    _descuentoAplicado = 0;
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cupon}/validar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'codigo': codigo.trim().toUpperCase()}),
      );

      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        _cuponAplicado = data['data'];

        // Calcular descuento (podrá ser fijo o porcentaje)
        final tipo = data['data']['tipo_descuento'] ??
            'porcentaje'; // 'porcentaje' o 'fijo'
        final valor = (data['data']['valor_descuento'] ?? 0).toDouble();

        if (tipo == 'porcentaje') {
          _descuentoAplicado = (montoTotal * valor) / 100;
        } else {
          _descuentoAplicado = valor;
        }

        _mensajeCupon =
            'Cupón aplicado: ${(_descuentoAplicado).toStringAsFixed(2)} de descuento';
        notifyListeners();
        return true;
      } else {
        _mensajeCupon = data['mensaje'] ?? 'Cupón inválido o expirado';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _mensajeCupon = 'Error al validar cupón: $e';
      notifyListeners();
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // Limpiar cupón aplicado
  void limpiarCupon() {
    _cuponAplicado = null;
    _descuentoAplicado = 0;
    _mensajeCupon = null;
    notifyListeners();
  }

  // Admin: Obtener lista de cupones
  Future<void> cargarCupones() async {
    _cargando = true;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cupon}'),
      );

      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        _cupones = List<Map<String, dynamic>>.from(
          (data['data'] as List).map((item) {
            // Normalizar claves a minúsculas y formatear fechas
            return {
              'cupon_id': item['CUPON_ID'] ?? item['cupon_id'],
              'codigo': item['CODIGO'] ?? item['codigo'],
              'descripcion': item['DESCRIPCION'] ??
                  item['descripcion'] ??
                  'Sin descripción',
              'vigencia_inicio': _formatearFechaProvider(
                  item['VIGENCIA_INICIO'] ?? item['vigencia_inicio']),
              'vigencia_fin': _formatearFechaProvider(
                  item['VIGENCIA_FIN'] ?? item['vigencia_fin']),
              'limite_uso_total':
                  item['LIMITE_USO_TOTAL'] ?? item['limite_uso_total'],
              'limite_uso_por_cliente': item['LIMITE_USO_POR_CLIENTE'] ??
                  item['limite_uso_por_cliente'],
              'usos_actuales':
                  item['USOS_ACTUALES'] ?? item['usos_actuales'] ?? 0,
            };
          }),
        );
      }
    } catch (e) {
      _mensajeCupon = 'Error al cargar cupones: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  String _formatearFechaProvider(dynamic fecha) {
    if (fecha == null) return '';
    try {
      if (fecha is num) {
        // Si es timestamp
        final dt = DateTime.fromMillisecondsSinceEpoch(fecha.toInt());
        return dt.toIso8601String().split('T').first;
      } else {
        // Si es string
        final fechaStr = fecha.toString();
        if (fechaStr.contains('T')) {
          return fechaStr.split('T').first;
        }
        return fechaStr;
      }
    } catch (e) {
      return '';
    }
  }

  // Admin: Crear cupón
  Future<bool> crearCupon({
    required String codigo,
    required String descripcion,
    required String tipoDescuento, // 'porcentaje' o 'fijo'
    required double valorDescuento,
    required DateTime vigenciaInicio,
    required DateTime vigenciaFin,
    required int limiteUsoTotal,
    required int limiteUsoPorCliente,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cupon}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo': codigo.trim().toUpperCase(),
          'descripcion': descripcion.trim(),
          'tipo_descuento': tipoDescuento,
          'valor_descuento': valorDescuento,
          'vigencia_inicio': vigenciaInicio.toIso8601String(),
          'vigencia_fin': vigenciaFin.toIso8601String(),
          'limite_uso_total': limiteUsoTotal,
          'limite_uso_por_cliente': limiteUsoPorCliente,
          'usos_actuales': 0,
        }),
      );

      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        await cargarCupones();
        return true;
      } else {
        _mensajeCupon = data['mensaje'] ?? 'Error al crear cupón';
        return false;
      }
    } catch (e) {
      _mensajeCupon = 'Error: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Admin: Actualizar cupón
  Future<bool> actualizarCupon({
    required int cuponId,
    required String codigo,
    required String descripcion,
    required String tipoDescuento,
    required double valorDescuento,
    required DateTime vigenciaInicio,
    required DateTime vigenciaFin,
    required int limiteUsoTotal,
    required int limiteUsoPorCliente,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cupon}/$cuponId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo': codigo.trim().toUpperCase(),
          'descripcion': descripcion.trim(),
          'tipo_descuento': tipoDescuento,
          'valor_descuento': valorDescuento,
          'vigencia_inicio': vigenciaInicio.toIso8601String(),
          'vigencia_fin': vigenciaFin.toIso8601String(),
          'limite_uso_total': limiteUsoTotal,
          'limite_uso_por_cliente': limiteUsoPorCliente,
        }),
      );

      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        await cargarCupones();
        return true;
      } else {
        _mensajeCupon = data['mensaje'] ?? 'Error al actualizar cupón';
        return false;
      }
    } catch (e) {
      _mensajeCupon = 'Error: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Admin: Eliminar cupón
  Future<bool> eliminarCupon(int cuponId) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cupon}/$cuponId'),
      );

      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        await cargarCupones();
        return true;
      } else {
        _mensajeCupon = data['mensaje'] ?? 'Error al eliminar cupón';
        return false;
      }
    } catch (e) {
      _mensajeCupon = 'Error: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }
}
