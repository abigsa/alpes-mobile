import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final _auth = context.read<AuthProvider>();
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.productos),
        headers: _auth.authHeaders,
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _eliminar(int id) async {
    final _auth = context.read<AuthProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AlpesColors.rojoColonial,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}/$id'),
      headers: _auth.authHeaders,
    );

    _cargar();
  }

  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductosForm(
        item: item,
        onGuardado: _cargar,
      ),
    );
  }

  Future<void> _abrirFormConDetalle([Map<String, dynamic>? item]) async {
    final _auth = context.read<AuthProvider>();
    if (item == null) {
      _abrirForm();
      return;
    }

    final dynamic idValue =
        item['PRODUCTO_ID'] ?? item['producto_id'] ?? item['ID'] ?? item['id'];
    final int id = int.tryParse('${idValue ?? 0}') ?? 0;

    if (id <= 0) {
      _abrirForm(item);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}/$id'),
        headers: _auth.authHeaders,
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && data['data'] != null) {
        _abrirForm(Map<String, dynamic>.from(data['data']));
      } else {
        _abrirForm(item);
      }
    } catch (_) {
      _abrirForm(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('PRODUCTOS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _abrirForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 64, color: AlpesColors.arenaCalida),
                      const SizedBox(height: 12),
                      Text('Sin registros',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                        onPressed: () => _abrirForm(),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AlpesColors.cafeOscuro,
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final dynamic idValue = item['PRODUCTO_ID'] ??
                          item['producto_id'] ??
                          item['ID'] ??
                          item['id'];
                      final int id = int.tryParse('${idValue ?? 0}') ?? 0;
                      final nombre = item['NOMBRE'] ??
                          item['nombre'] ??
                          item['REFERENCIA'] ??
                          item['referencia'] ??
                          'Sin nombre';
                      final referencia =
                          item['REFERENCIA'] ?? item['referencia'] ?? '';
                      final imagenUrl =
                          item['IMAGEN_URL'] ?? item['imagen_url'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: imagenUrl.toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imagenUrl.toString(),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AlpesColors.pergamino,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                          Icons.image_not_supported,
                                          color: AlpesColors.arenaCalida),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AlpesColors.pergamino,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image_outlined,
                                      color: AlpesColors.arenaCalida),
                                ),
                          title: Text(nombre.toString(),
                              style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text(
                            referencia.toString().isNotEmpty
                                ? 'ID: $id | Ref: $referencia'
                                : 'ID: $id',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: AlpesColors.nogalMedio),
                                onPressed: () => _abrirFormConDetalle(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AlpesColors.rojoColonial),
                                onPressed: id > 0 ? () => _eliminar(id) : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AlpesColors.cafeOscuro,
        onPressed: () => _abrirForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// FORMULARIO
// ══════════════════════════════════════════════════════════
class _ProductosForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;

  const _ProductosForm({super.key, this.item, required this.onGuardado});

  @override
  State<_ProductosForm> createState() => __ProductosFormState();
}

class __ProductosFormState extends State<_ProductosForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool _guardando = false;
  bool _subiendoImagen = false;

  // Imagen — web usa bytes, móvil usa File
  String? _imagenUrl;
  File? _imagenLocal;       // solo móvil
  Uint8List? _imagenBytes;  // solo web
  final _picker = ImagePicker();

  // Catalogos
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _unidades = [];
  bool _loadingCatalogos = true;
  int? _categoriaId;
  int? _unidadMedidaId;

  @override
  void initState() {
    super.initState();
    controllers['referencia'] = TextEditingController();
    controllers['nombre'] = TextEditingController();
    controllers['descripcion'] = TextEditingController();
    controllers['tipo'] = TextEditingController();
    controllers['material'] = TextEditingController();
    controllers['alto_cm'] = TextEditingController();
    controllers['ancho_cm'] = TextEditingController();
    controllers['profundidad_cm'] = TextEditingController();
    controllers['color'] = TextEditingController();
    controllers['peso_gramos'] = TextEditingController();
    controllers['lote_producto'] = TextEditingController();

    if (widget.item != null) {
      for (final k in controllers.keys) {
        final upper = k.toUpperCase();
        controllers[k]!.text =
            (widget.item![upper] ?? widget.item![k] ?? '').toString();
      }
      _unidadMedidaId = _toInt(
          widget.item!['UNIDAD_MEDIDA_ID'] ?? widget.item!['unidad_medida_id']);
      _categoriaId = _toInt(
          widget.item!['CATEGORIA_ID'] ?? widget.item!['categoria_id']);
      _imagenUrl =
          (widget.item!['IMAGEN_URL'] ?? widget.item!['imagen_url'] ?? '')
              .toString();
      if (_imagenUrl!.isEmpty) _imagenUrl = null;
    }

    _cargarCatalogos();
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  int? _validDropdownValue(int? selectedValue,
      List<Map<String, dynamic>> items, String pk, String sk) {
    if (selectedValue == null) return null;
    final exists =
        items.any((item) => _toInt(item[pk] ?? item[sk]) == selectedValue);
    return exists ? selectedValue : null;
  }

  Future<void> _cargarCatalogos() async {
    setState(() => _loadingCatalogos = true);
    try {
      final unidadesRes = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.unidadMedida}'));
      final categoriasRes = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.categorias}'));

      final unidadesData = jsonDecode(unidadesRes.body);
      final categoriasData = jsonDecode(categoriasRes.body);

      if (unidadesData['ok'] == true)
        _unidades = List<Map<String, dynamic>>.from(unidadesData['data']);
      if (categoriasData['ok'] == true)
        _categorias = List<Map<String, dynamic>>.from(categoriasData['data']);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCatalogos = false);
    }
  }

  // ── Seleccionar imagen ─────────────────────────────────
  Future<void> _seleccionarImagen(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    if (kIsWeb) {
      // Web: leer bytes, NO asignar File
      final bytes = await picked.readAsBytes();
      setState(() {
        _imagenBytes = bytes;
        _imagenLocal = null;
      });
    } else {
      // Móvil: usar File, NO asignar bytes
      setState(() {
        _imagenLocal = File(picked.path);
        _imagenBytes = null;
      });
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AlpesColors.cremaFondo,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: AlpesColors.arenaCalida,
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: AlpesColors.cafeOscuro),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: AlpesColors.cafeOscuro),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            if (_imagenUrl != null || _imagenLocal != null || _imagenBytes != null)
              ListTile(
                leading:
                    const Icon(Icons.delete, color: AlpesColors.rojoColonial),
                title: const Text('Eliminar imagen',
                    style: TextStyle(color: AlpesColors.rojoColonial)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imagenLocal = null;
                    _imagenBytes = null;
                    _imagenUrl = null;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Subir imagen ───────────────────────────────────────
  Future<void> _subirImagen(int productoId) async {    if (_imagenBytes == null && _imagenLocal == null) return;
    setState(() => _subiendoImagen = true);
    try {
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/upload/producto/$productoId');
      final request = http.MultipartRequest('POST', uri);

      if (kIsWeb && _imagenBytes != null) {
        // Web: subir desde bytes
        request.files.add(http.MultipartFile.fromBytes(
          'imagen',
          _imagenBytes!,
          filename: 'producto_$productoId.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (!kIsWeb && _imagenLocal != null) {
        // Móvil: subir desde File
        request.files.add(await http.MultipartFile.fromPath(
          'imagen',
          _imagenLocal!.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        _imagenUrl = data['url'];
      }
    } catch (_) {
    } finally {
      setState(() => _subiendoImagen = false);
    }
  }

  // ── Guardar ────────────────────────────────────────────
  Future<void> _guardar() async {
    final _auth = context.read<AuthProvider>();
    if (!_formKey.currentState!.validate()) return;
    if (_unidadMedidaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione la unidad de medida')));
      return;
    }
    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione la categoría')));
      return;
    }

    setState(() => _guardando = true);
    try {
      final body = <String, dynamic>{
        'referencia': controllers['referencia']!.text.trim(),
        'nombre': controllers['nombre']!.text.trim(),
        'descripcion': controllers['descripcion']!.text.trim(),
        'tipo': controllers['tipo']!.text.trim().toUpperCase(),
        'material': controllers['material']!.text.trim(),
        'alto_cm': double.tryParse(controllers['alto_cm']!.text.trim()) ?? 0,
        'ancho_cm': double.tryParse(controllers['ancho_cm']!.text.trim()) ?? 0,
        'profundidad_cm':
            double.tryParse(controllers['profundidad_cm']!.text.trim()) ?? 0,
        'color': controllers['color']!.text.trim(),
        'peso_gramos':
            int.tryParse(controllers['peso_gramos']!.text.trim()) ?? 0,
        'unidad_medida_id': _unidadMedidaId,
        'categoria_id': _categoriaId,
        'lote_producto': controllers['lote_producto']!.text.trim(),
      };

      final id = widget.item?['PRODUCTO_ID'] ??
          widget.item?['producto_id'] ??
          widget.item?['ID'] ??
          widget.item?['id'];

      http.Response res;
      if (id != null) {
        res = await http.put(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}/$id'),
          headers: _auth.authHeaders,
          body: jsonEncode(body),
        );
      } else {
        res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}'),
          headers: _auth.authHeaders,
          body: jsonEncode(body),
        );
      }

      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final productoId = id ??
            _toInt(data['data']?['PRODUCTO_ID'] ??
                data['data']?['producto_id']);

        if (productoId != null &&
            (_imagenBytes != null || _imagenLocal != null)) {
          await _subirImagen(productoId);
        }

        widget.onGuardado();
        if (context.mounted) Navigator.pop(context);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['mensaje'] ?? 'Error'),
            backgroundColor: AlpesColors.rojoColonial,
          ));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AlpesColors.rojoColonial,
        ));
      }
    } finally {
      setState(() => _guardando = false);
    }
  }

  Widget _campo(String label, String key,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controllers[key],
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in controllers.values) c.dispose();
    super.dispose();
  }

  // ── Preview de imagen ──────────────────────────────────
  Widget _buildImagePreview() {
    if (_subiendoImagen) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AlpesColors.cafeOscuro),
            SizedBox(height: 8),
            Text('Subiendo imagen...',
                style: TextStyle(color: AlpesColors.nogalMedio)),
          ],
        ),
      );
    }

    // Web: mostrar desde bytes
    if (kIsWeb && _imagenBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _imagenBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    }

    // Móvil: mostrar desde File
    if (!kIsWeb && _imagenLocal != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _imagenLocal!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    }

    // Imagen desde Cloudinary (URL en Oracle)
    if (_imagenUrl != null && _imagenUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _imagenUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 48, color: AlpesColors.arenaCalida),
        SizedBox(height: 8),
        Text('Toca para agregar imagen',
            style: TextStyle(color: AlpesColors.nogalMedio, fontSize: 13)),
        SizedBox(height: 4),
        Text('Galería o cámara',
            style: TextStyle(color: AlpesColors.arenaCalida, fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.item == null ? 'Nuevo producto' : 'Editar producto',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // ── Selector de imagen ──────────────────
                GestureDetector(
                  onTap: _mostrarOpcionesImagen,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AlpesColors.pergamino,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AlpesColors.arenaCalida),
                    ),
                    child: _buildImagePreview(),
                  ),
                ),
                TextButton.icon(
                  onPressed: _mostrarOpcionesImagen,
                  icon: const Icon(Icons.add_photo_alternate,
                      color: AlpesColors.cafeOscuro),
                  label: Text(
                    (_imagenBytes != null || _imagenLocal != null) ||
                            (_imagenUrl != null && _imagenUrl!.isNotEmpty)
                        ? 'Cambiar imagen'
                        : 'Agregar imagen',
                    style: const TextStyle(color: AlpesColors.cafeOscuro),
                  ),
                ),

                const Divider(),
                const SizedBox(height: 8),

                // ── Campos ──────────────────────────────
                _campo('Referencia', 'referencia'),
                _campo('Nombre', 'nombre',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null),
                _campo('Descripcion', 'descripcion'),
                _campo('Tipo (INTERIOR o EXTERIOR)', 'tipo', validator: (v) {
                  final val = v?.trim().toUpperCase() ?? '';
                  if (val.isEmpty) return 'Requerido';
                  if (val != 'INTERIOR' && val != 'EXTERIOR')
                    return 'Debe ser INTERIOR o EXTERIOR';
                  return null;
                }),
                _campo('Material', 'material'),
                _campo('Alto cm', 'alto_cm',
                    keyboardType: TextInputType.number, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (double.tryParse(v.trim()) == null)
                    return 'Número inválido';
                  return null;
                }),
                _campo('Ancho cm', 'ancho_cm',
                    keyboardType: TextInputType.number, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (double.tryParse(v.trim()) == null)
                    return 'Número inválido';
                  return null;
                }),
                _campo('Profundidad cm', 'profundidad_cm',
                    keyboardType: TextInputType.number, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (double.tryParse(v.trim()) == null)
                    return 'Número inválido';
                  return null;
                }),
                _campo('Color', 'color'),
                _campo('Peso gramos', 'peso_gramos',
                    keyboardType: TextInputType.number, validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (int.tryParse(v.trim()) == null) return 'Número inválido';
                  return null;
                }),

                // ── Dropdowns ───────────────────────────
                _loadingCatalogos
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AlpesColors.cafeOscuro)),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DropdownButtonFormField<int>(
                              value: _validDropdownValue(
                                  _unidadMedidaId,
                                  _unidades,
                                  'UNIDAD_MEDIDA_ID',
                                  'unidad_medida_id'),
                              decoration: const InputDecoration(
                                  labelText: 'Unidad de Medida'),
                              items: _unidades.map((u) {
                                final id = _toInt(u['UNIDAD_MEDIDA_ID'] ??
                                    u['unidad_medida_id']);
                                final nombre =
                                    (u['NOMBRE'] ?? u['nombre'] ?? '')
                                        .toString();
                                if (id == null || nombre.isEmpty) return null;
                                return DropdownMenuItem<int>(
                                    value: id, child: Text(nombre));
                              }).whereType<DropdownMenuItem<int>>().toList(),
                              onChanged: (v) =>
                                  setState(() => _unidadMedidaId = v),
                              validator: (v) => v == null
                                  ? 'Seleccione unidad de medida'
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DropdownButtonFormField<int>(
                              value: _validDropdownValue(_categoriaId,
                                  _categorias, 'CATEGORIA_ID', 'categoria_id'),
                              decoration: const InputDecoration(
                                  labelText: 'Categoría'),
                              items: _categorias.map((c) {
                                final id = _toInt(
                                    c['CATEGORIA_ID'] ?? c['categoria_id']);
                                final nombre =
                                    (c['NOMBRE'] ?? c['nombre'] ?? '')
                                        .toString();
                                if (id == null || nombre.isEmpty) return null;
                                return DropdownMenuItem<int>(
                                    value: id, child: Text(nombre));
                              }).whereType<DropdownMenuItem<int>>().toList(),
                              onChanged: (v) =>
                                  setState(() => _categoriaId = v),
                              validator: (v) =>
                                  v == null ? 'Seleccione categoría' : null,
                            ),
                          ),
                        ],
                      ),

                _campo('Lote Producto', 'lote_producto'),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _guardando || _subiendoImagen ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AlpesColors.cafeOscuro,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('GUARDAR',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}