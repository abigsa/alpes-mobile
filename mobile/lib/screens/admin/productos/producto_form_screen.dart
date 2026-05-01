import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
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
  final _nombreCtrl    = TextEditingController();
  final _descCtrl      = TextEditingController();
  final _tipoCtrl      = TextEditingController();
  final _materialCtrl  = TextEditingController();
  final _colorCtrl     = TextEditingController();
  final _precioCtrl    = TextEditingController();

  bool _guardando      = false;
  bool _subiendoImagen = false;
  String? _imagenUrl;
  File?   _imagenLocal;
  int?    _productoIdGuardado;
  Map<String, dynamic>? _producto;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.productoId != null) {
      _productoIdGuardado = widget.productoId;
      _cargar();
    }
  }

  Future<void> _cargar() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}/${widget.productoId}'),
    );
    final data = jsonDecode(res.body);
    if (data['ok'] == true) {
      _producto = data['data'];
      _nombreCtrl.text   = _producto!['NOMBRE']       ?? _producto!['nombre']       ?? '';
      _descCtrl.text     = _producto!['DESCRIPCION']  ?? _producto!['descripcion']  ?? '';
      _tipoCtrl.text     = _producto!['TIPO']         ?? _producto!['tipo']         ?? '';
      _materialCtrl.text = _producto!['MATERIAL']     ?? _producto!['material']     ?? '';
      _colorCtrl.text    = _producto!['COLOR']        ?? _producto!['color']        ?? '';
      _imagenUrl         = _producto!['IMAGEN_URL']   ?? _producto!['imagen_url'];
      setState(() {});
    }
  }

  // ── Seleccionar imagen de galería o cámara ──────────────────
  Future<void> _seleccionarImagen(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() => _imagenLocal = File(picked.path));
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AlpesColors.cremaFondo,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AlpesColors.arenaCalida,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AlpesColors.cafeOscuro),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AlpesColors.cafeOscuro),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            if (_imagenUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AlpesColors.rojoColonial),
                title: const Text('Eliminar imagen', style: TextStyle(color: AlpesColors.rojoColonial)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imagenLocal = null;
                    _imagenUrl   = null;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Subir imagen al backend → Cloudinary ───────────────────
  Future<void> _subirImagen(int productoId) async {
    if (_imagenLocal == null) return;
    setState(() => _subiendoImagen = true);
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/upload/producto/$productoId');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'imagen',
        _imagenLocal!.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      final streamed = await request.send();
      final res      = await http.Response.fromStream(streamed);
      final data     = jsonDecode(res.body);
      if (data['ok'] == true) {
        setState(() => _imagenUrl = data['url']);
      } else {
        _mostrarError('Error al subir imagen: ${data['mensaje']}');
      }
    } catch (e) {
      _mostrarError('Error al subir imagen: $e');
    } finally {
      setState(() => _subiendoImagen = false);
    }
  }

  // ── Guardar producto ───────────────────────────────────────
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = {
        'nombre':          _nombreCtrl.text,
        'descripcion':     _descCtrl.text,
        'tipo':            _tipoCtrl.text,
        'material':        _materialCtrl.text,
        'color':           _colorCtrl.text,
        'unidad_medida_id': 1,
        'categoria_id':    1,
        'lote_producto':   'LOTE-001',
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
        // Obtener el ID del producto guardado
        final id = widget.productoId ?? data['data']?['PRODUCTO_ID'] ?? data['data']?['producto_id'];
        if (id != null) {
          _productoIdGuardado = id;
          // Si hay imagen local pendiente, subirla ahora
          if (_imagenLocal != null) {
            await _subirImagen(id);
          }
        }
        if (context.mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto guardado'),
              backgroundColor: AlpesColors.exito,
            ),
          );
        }
      } else {
        _mostrarError(data['mensaje'] ?? 'Error al guardar');
      }
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      setState(() => _guardando = false);
    }
  }

  void _mostrarError(String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AlpesColors.rojoColonial),
      );
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _tipoCtrl.dispose();
    _materialCtrl.dispose();
    _colorCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: Text(widget.productoId == null ? 'NUEVO PRODUCTO' : 'EDITAR PRODUCTO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Selector de imagen ──────────────────────────
              GestureDetector(
                onTap: _mostrarOpcionesImagen,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AlpesColors.pergamino,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AlpesColors.arenaCalida),
                  ),
                  child: _subiendoImagen
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: AlpesColors.cafeOscuro),
                              SizedBox(height: 12),
                              Text('Subiendo imagen...', style: TextStyle(color: AlpesColors.nogalMedio)),
                            ],
                          ),
                        )
                      : _imagenLocal != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_imagenLocal!, fit: BoxFit.cover, width: double.infinity),
                            )
                          : _imagenUrl != null && _imagenUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _imagenUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => _placeholderImagen(),
                                  ),
                                )
                              : _placeholderImagen(),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _mostrarOpcionesImagen,
                icon: const Icon(Icons.add_photo_alternate, color: AlpesColors.cafeOscuro),
                label: Text(
                  _imagenLocal != null || (_imagenUrl != null && _imagenUrl!.isNotEmpty)
                      ? 'Cambiar imagen'
                      : 'Agregar imagen',
                  style: const TextStyle(color: AlpesColors.cafeOscuro),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // ── Campos del formulario ───────────────────────
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tipoCtrl,
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _materialCtrl,
                decoration: const InputDecoration(labelText: 'Material'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorCtrl,
                decoration: const InputDecoration(labelText: 'Color'),
              ),

              const SizedBox(height: 32),

              // ── Botón guardar ───────────────────────────────
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AlpesColors.cafeOscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _guardando || _subiendoImagen ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('GUARDAR PRODUCTO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImagen() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 48, color: AlpesColors.arenaCalida),
        SizedBox(height: 8),
        Text('Toca para agregar imagen', style: TextStyle(color: AlpesColors.nogalMedio, fontSize: 13)),
        SizedBox(height: 4),
        Text('Galería o cámara', style: TextStyle(color: AlpesColors.arenaCalida, fontSize: 11)),
      ],
    );
  }
}