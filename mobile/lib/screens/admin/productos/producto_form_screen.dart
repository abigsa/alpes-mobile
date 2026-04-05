import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class ProductoFormScreen extends StatefulWidget {
  final int? productoId;
  const ProductoFormScreen({super.key, this.productoId});
  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tipoCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _imagenCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  bool _guardando = false;
  Map<String, dynamic>? _producto;

  @override
  void initState() {
    super.initState();
    if (widget.productoId != null) _cargar();
  }

  Future<void> _cargar() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}/${widget.productoId}'));
    final data = jsonDecode(res.body);
    if (data['ok'] == true) {
      _producto = data['data'];
      _nombreCtrl.text = _producto!['NOMBRE'] ?? _producto!['nombre'] ?? '';
      _descCtrl.text = _producto!['DESCRIPCION'] ?? _producto!['descripcion'] ?? '';
      _tipoCtrl.text = _producto!['TIPO'] ?? _producto!['tipo'] ?? '';
      _materialCtrl.text = _producto!['MATERIAL'] ?? _producto!['material'] ?? '';
      _colorCtrl.text = _producto!['COLOR'] ?? _producto!['color'] ?? '';
      _imagenCtrl.text = _producto!['IMAGEN_URL'] ?? _producto!['imagen_url'] ?? '';
      setState(() {});
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = {
        'nombre': _nombreCtrl.text,
        'descripcion': _descCtrl.text,
        'tipo': _tipoCtrl.text,
        'material': _materialCtrl.text,
        'color': _colorCtrl.text,
        'imagen_url': _imagenCtrl.text,
        'unidad_medida_id': 1,
        'categoria_id': 1,
        'lote_producto': 'LOTE-001',
      };
      http.Response res;
      if (widget.productoId != null) {
        body['producto_id'] = widget.productoId!;
        res = await http.put(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}/${widget.productoId}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } else {
        res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      }
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        if (context.mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto guardado'), backgroundColor: AlpesColors.exito),
          );
        }
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AlpesColors.rojoColonial),
      );
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _descCtrl.dispose(); _tipoCtrl.dispose();
    _materialCtrl.dispose(); _colorCtrl.dispose(); _imagenCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: Text(widget.productoId == null ? 'NUEVO PRODUCTO' : 'EDITAR PRODUCTO'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 3),
              const SizedBox(height: 12),
              TextFormField(controller: _tipoCtrl, decoration: const InputDecoration(labelText: 'Tipo')),
              const SizedBox(height: 12),
              TextFormField(controller: _materialCtrl, decoration: const InputDecoration(labelText: 'Material')),
              const SizedBox(height: 12),
              TextFormField(controller: _colorCtrl, decoration: const InputDecoration(labelText: 'Color')),
              const SizedBox(height: 12),
              TextFormField(controller: _imagenCtrl, decoration: const InputDecoration(labelText: 'URL de imagen')),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('GUARDAR PRODUCTO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
