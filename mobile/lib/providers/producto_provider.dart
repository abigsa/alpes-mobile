import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class Producto {
  final int productoId;
  final String nombre;
  final String? descripcion;
  final String? tipo;
  final String? material;
  final String? color;
  final double? precio;
  final String? imagenUrl;
  final int? categoriaId;
  final String? categoriaNombre;

  Producto({
    required this.productoId,
    required this.nombre,
    this.descripcion,
    this.tipo,
    this.material,
    this.color,
    this.precio,
    this.imagenUrl,
    this.categoriaId,
    this.categoriaNombre,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      productoId: json['PRODUCTO_ID'] ?? json['producto_id'] ?? 0,
      nombre: json['NOMBRE'] ?? json['nombre'] ?? '',
      descripcion: json['DESCRIPCION'] ?? json['descripcion'],
      tipo: json['TIPO'] ?? json['tipo'],
      material: json['MATERIAL'] ?? json['material'],
      color: json['COLOR'] ?? json['color'],
      precio: double.tryParse('${json['PRECIO'] ?? json['precio'] ?? 0}'),
      imagenUrl: json['IMAGEN_URL'] ?? json['imagen_url'],
      categoriaId: json['CATEGORIA_ID'] ?? json['categoria_id'],
      categoriaNombre: json['CATEGORIA_NOMBRE'] ?? json['categoria_nombre'],
    );
  }
}

class ProductoProvider extends ChangeNotifier {
  List<Producto> _productos = [];
  List<Producto> _recomendados = [];
  List<Producto> _resultadosBusqueda = [];
  bool _loading = false;
  String _busqueda = '';

  // Historial para algoritmo de recomendaciones
  final List<int> _categoriasVistas = [];
  final List<String> _tiposVistos = [];

  List<Producto> get productos => _productos;
  List<Producto> get recomendados => _recomendados;
  List<Producto> get resultadosBusqueda => _resultadosBusqueda;
  bool get loading => _loading;
  String get busqueda => _busqueda;

  Future<void> cargarProductos() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        _productos = (data['data'] as List).map((p) => Producto.fromJson(p)).toList();
      }
    } catch (_) {} finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<Producto>> buscar(String criterio) async {
    _busqueda = criterio;
    if (criterio.isEmpty) {
      _resultadosBusqueda = [];
      notifyListeners();
      return [];
    }
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}/buscar?criterio=nombre&valor=$criterio'),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        _resultadosBusqueda = (data['data'] as List).map((p) => Producto.fromJson(p)).toList();
        notifyListeners();
        return _resultadosBusqueda;
      }
    } catch (_) {}
    return [];
  }

  Future<Producto?> obtenerProducto(int id) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}/$id'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true && data['data'] != null) {
        final p = Producto.fromJson(data['data']);
        // Registrar para algoritmo de recomendaciones
        if (p.categoriaId != null) _registrarVistaCategoria(p.categoriaId!);
        if (p.tipo != null) _registrarVistaTipo(p.tipo!);
        return p;
      }
    } catch (_) {}
    return null;
  }

  void _registrarVistaCategoria(int catId) {
    _categoriasVistas.remove(catId);
    _categoriasVistas.insert(0, catId);
    if (_categoriasVistas.length > 10) _categoriasVistas.removeLast();
    _calcularRecomendaciones();
  }

  void _registrarVistaTipo(String tipo) {
    _tiposVistos.remove(tipo);
    _tiposVistos.insert(0, tipo);
    if (_tiposVistos.length > 5) _tiposVistos.removeLast();
    _calcularRecomendaciones();
  }

  void registrarFavorito(int productoId) {
    final p = _productos.firstWhere((p) => p.productoId == productoId, orElse: () => _productos.first);
    if (p.categoriaId != null) _registrarVistaCategoria(p.categoriaId!);
    if (p.tipo != null) _registrarVistaTipo(p.tipo!);
  }

  void _calcularRecomendaciones() {
    if (_productos.isEmpty) return;
    
    // Score por categoría y tipo vistos
    final scored = <Producto, int>{};
    for (final p in _productos) {
      int score = 0;
      if (p.categoriaId != null && _categoriasVistas.contains(p.categoriaId)) {
        score += (10 - _categoriasVistas.indexOf(p.categoriaId!));
      }
      if (p.tipo != null && _tiposVistos.contains(p.tipo)) {
        score += (5 - _tiposVistos.indexOf(p.tipo!));
      }
      if (score > 0) scored[p] = score;
    }

    final sorted = scored.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    _recomendados = sorted.take(10).map((e) => e.key).toList();
    
    // Si no hay suficientes recomendados, llenar con productos al azar
    if (_recomendados.length < 6) {
      final resto = _productos.where((p) => !_recomendados.contains(p)).take(6 - _recomendados.length);
      _recomendados.addAll(resto);
    }
    notifyListeners();
  }

  List<Producto> porCategoria(int categoriaId) {
    return _productos.where((p) => p.categoriaId == categoriaId).toList();
  }
}
