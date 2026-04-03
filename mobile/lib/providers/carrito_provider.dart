import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CarritoItem {
  final int carritoDetId;
  final int productoId;
  final String nombre;
  final String? imagenUrl;
  int cantidad;
  final double precioUnitario;

  CarritoItem({
    required this.carritoDetId,
    required this.productoId,
    required this.nombre,
    this.imagenUrl,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;
}

class CarritoProvider extends ChangeNotifier {
  final List<CarritoItem> _items = [];
  int? _carritoId;
  bool _loading = false;

  List<CarritoItem> get items => _items;
  int? get carritoId => _carritoId;
  bool get loading => _loading;
  int get totalItems => _items.fold(0, (sum, i) => sum + i.cantidad);
  double get total => _items.fold(0.0, (sum, i) => sum + i.subtotal);
  bool get isEmpty => _items.isEmpty;

  Future<void> cargarCarrito(int clienteId) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.carrito}/buscar?criterio=cli_id&valor=$clienteId'),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && data['data'] != null && (data['data'] as List).isNotEmpty) {
        final carrito = data['data'][0];
        _carritoId = carrito['CARRITO_ID'] ?? carrito['carrito_id'];
        await _cargarDetalle();
      }
    } catch (_) {} finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarDetalle() async {
    if (_carritoId == null) return;
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.carritoDetalle}/buscar?criterio=carrito_id&valor=$_carritoId'),
    );
    final data = jsonDecode(res.body);
    if (data['ok'] == true) {
      _items.clear();
      for (final item in data['data']) {
        _items.add(CarritoItem(
          carritoDetId: item['CARRITO_DET_ID'] ?? item['carrito_det_id'],
          productoId: item['PRODUCTO_ID'] ?? item['producto_id'],
          nombre: item['NOMBRE'] ?? item['nombre'] ?? 'Producto',
          imagenUrl: item['IMAGEN_URL'] ?? item['imagen_url'],
          cantidad: item['CANTIDAD'] ?? item['cantidad'],
          precioUnitario: double.tryParse('${item['PRECIO_UNITARIO_SNAPSHOT'] ?? item['precio_unitario_snapshot'] ?? 0}') ?? 0,
        ));
      }
    }
  }

  Future<void> agregarItem({
    required int clienteId,
    required int productoId,
    required String nombre,
    required double precio,
    String? imagenUrl,
    int cantidad = 1,
  }) async {
    if (_carritoId == null) await _crearCarrito(clienteId);
    if (_carritoId == null) return;

    final existente = _items.where((i) => i.productoId == productoId);
    if (existente.isNotEmpty) {
      await actualizarCantidad(existente.first.carritoDetId, existente.first.cantidad + cantidad);
      return;
    }

    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.carritoDetalle}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'carrito_id': _carritoId,
        'producto_id': productoId,
        'cantidad': cantidad,
        'precio_unitario_snapshot': precio,
      }),
    );
    final data = jsonDecode(res.body);
    if (data['ok'] == true) {
      _items.add(CarritoItem(
        carritoDetId: data['data']['carrito_det_id'] ?? 0,
        productoId: productoId,
        nombre: nombre,
        imagenUrl: imagenUrl,
        cantidad: cantidad,
        precioUnitario: precio,
      ));
      notifyListeners();
    }
  }

  Future<void> _crearCarrito(int clienteId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.carrito}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'cli_id': clienteId,
        'estado_carrito': 'ACTIVO',
        'ultimo_calculo_at': DateTime.now().toIso8601String(),
      }),
    );
    final data = jsonDecode(res.body);
    if (data['ok'] == true) {
      _carritoId = data['data']['carrito_id'];
    }
  }

  Future<void> actualizarCantidad(int detId, int nuevaCantidad) async {
    final item = _items.firstWhere((i) => i.carritoDetId == detId);
    await http.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.carritoDetalle}/$detId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'carrito_det_id': detId,
        'carrito_id': _carritoId,
        'producto_id': item.productoId,
        'cantidad': nuevaCantidad,
        'precio_unitario_snapshot': item.precioUnitario,
      }),
    );
    item.cantidad = nuevaCantidad;
    notifyListeners();
  }

  Future<void> eliminarItem(int detId) async {
    await http.delete(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.carritoDetalle}/$detId'));
    _items.removeWhere((i) => i.carritoDetId == detId);
    notifyListeners();
  }

  void limpiar() {
    _items.clear();
    _carritoId = null;
    notifyListeners();
  }
}
