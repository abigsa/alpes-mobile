import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';

class MisResenasScreen extends StatefulWidget {
  const MisResenasScreen({super.key});

  @override
  State<MisResenasScreen> createState() => _MisResenasScreenState();
}

class _MisResenasScreenState extends State<MisResenasScreen> {
  List<Map<String, dynamic>> _resenas = [];
  List<Map<String, dynamic>> _productosComprados = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthProvider>();
    final clienteId = auth.clienteId;
    if (clienteId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Cargar reseñas del cliente
      final resRes = await http.get(Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.resenas}/buscar?criterio=cli_id&valor=$clienteId'));
      final resData = jsonDecode(resRes.body);
      List<Map<String, dynamic>> resenas = [];
      if (resData['ok'] == true) {
        resenas = List<Map<String, dynamic>>.from(resData['data'] ?? []);
      }

      // Cargar productos comprados de órdenes (sin restricción de estado)
      final ordRes = await http.get(Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.ordenVenta}/buscar?criterio=cli_id&valor=$clienteId'));
      final ordData = jsonDecode(ordRes.body);
      List<Map<String, dynamic>> productosComprados = [];
      final idsYaReseniados = resenas
          .map((r) => (r['PRODUCTO_ID'] ?? r['producto_id'])?.toString())
          .toSet();

      if (ordData['ok'] == true) {
        final ordenes = List<Map<String, dynamic>>.from(ordData['data'] ?? []);
        
        for (final orden in ordenes) {
          final ordenId = orden['ORDEN_VENTA_ID'] ?? orden['orden_venta_id'];
          if (ordenId == null) continue;

          try {
            final detRes = await http.get(Uri.parse(
                '${ApiConfig.baseUrl}${ApiConfig.ordenVentaDet}/buscar?criterio=orden_venta_id&valor=$ordenId'));
            final detData = jsonDecode(detRes.body);
            if (detData['ok'] == true) {
              final detalles = List<Map<String, dynamic>>.from(detData['data'] ?? []);
              for (final det in detalles) {
                final prodId = (det['PRODUCTO_ID'] ?? det['producto_id'])?.toString();
                if (prodId != null && !idsYaReseniados.contains(prodId)) {
                  productosComprados.add({
                    'producto_id': prodId,
                    'nombre': det['PRODUCTO_NOMBRE'] ?? det['nombre'] ?? 'Producto',
                    'imagen': det['IMAGEN'] ?? det['imagen'],
                  });
                  idsYaReseniados.add(prodId);
                }
              }
            }
          } catch (_) {}
        }
      }

      // Si no hay productos comprados, cargar todo el catálogo
      if (productosComprados.isEmpty) {
        try {
          final catRes = await http.get(Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.productos}/listar'));
          final catData = jsonDecode(catRes.body);
          if (catData['ok'] == true) {
            final productos = List<Map<String, dynamic>>.from(catData['data'] ?? []);
            for (final prod in productos) {
              final prodId = (prod['PRODUCTO_ID'] ?? prod['producto_id'])?.toString();
              if (prodId != null && !idsYaReseniados.contains(prodId)) {
                productosComprados.add({
                  'producto_id': prodId,
                  'nombre': prod['NOMBRE'] ?? prod['nombre'] ?? 'Producto',
                  'imagen': prod['IMAGEN'] ?? prod['imagen'],
                });
              }
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _resenas = resenas;
          _productosComprados = productosComprados;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _mostrarFormulario({Map<String, dynamic>? resenaExistente}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioResena(
        productosDisponibles: resenaExistente != null ? [] : _productosComprados,
        resenaExistente: resenaExistente,
        clienteId: context.read<AuthProvider>().clienteId ?? 0,
        onGuardado: () {
          Navigator.pop(context);
          _cargarDatos();
        },
      ),
    );
  }

  Future<void> _eliminarResena(dynamic resenaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar reseña',
            style: TextStyle(fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
        content: const Text('¿Estás segura de que deseas eliminar esta reseña?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AlpesColors.nogalMedio))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AlpesColors.rojoColonial,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await http.delete(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resenas}/$resenaId'));
      _cargarDatos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AlpesColors.rojoColonial));
      }
    }
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '';
    try {
      final dt = DateTime.parse(fecha.toString());
      const meses = [
        'Ene','Feb','Mar','Abr','May','Jun',
        'Jul','Ago','Sep','Oct','Nov','Dic'
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${meses[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return fecha.toString().split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        backgroundColor: AlpesColors.cafeOscuro,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 16),
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mis Reseñas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: 0.3)),
          if (!_loading)
            Text('${_resenas.length} reseña${_resenas.length != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 11,
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w400)),
        ]),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () => _mostrarFormulario(),
                icon: const Icon(Icons.add_rounded,
                    color: AlpesColors.oroGuatemalteco, size: 18),
                label: const Text('Nueva',
                    style: TextStyle(color: AlpesColors.oroGuatemalteco,
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : _error != null
              ? Center(
                  child: Text('Error: $_error',
                      style: const TextStyle(color: AlpesColors.rojoColonial)))
              : _resenas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 64, color: AlpesColors.pergamino),
                          const SizedBox(height: 16),
                          const Text('No tienes reseñas aún',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AlpesColors.cafeOscuro)),
                          const SizedBox(height: 8),
                          Text('Comparte tu experiencia con nuestros productos',
                              style: TextStyle(fontSize: 13,
                                  color: AlpesColors.arenaCalida),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _mostrarFormulario(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Escribir reseña',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AlpesColors.cafeOscuro,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarDatos,
                      color: AlpesColors.cafeOscuro,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 12, bottom: 24),
                        itemCount: _resenas.length,
                        itemBuilder: (_, i) {
                          final r = _resenas[i];
                          final nombreProducto = r['PRODUCTO_NOMBRE'] ??
                              r['nombre_producto'] ??
                              'Producto';
                          final calificacion =
                              int.tryParse((r['CALIFICACION'] ??
                                      r['calificacion'] ??
                                      5)
                                  .toString()) ??
                                  5;
                          final comentario =
                              (r['COMENTARIO'] ?? r['comentario'] ?? '').toString();
                          final fecha = _formatFecha(r['RESENA_AT'] ?? r['resena_at']);
                          final resenaId =
                              r['RESENA_ID'] ?? r['resena_id'];

                          return _buildResenaCard(
                            nombreProducto,
                            calificacion,
                            comentario,
                            fecha,
                            resenaId,
                            r,
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildResenaCard(String nombreProducto, int calificacion,
      String comentario, String fecha, dynamic resenaId,
      Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AlpesColors.pergamino)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombreProducto,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AlpesColors.cafeOscuro),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < calificacion ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14,
                    color: AlpesColors.oroGuatemalteco,
                  ),
                ),
                const SizedBox(width: 6),
                Text('$calificacion/5',
                    style: const TextStyle(fontSize: 11,
                        color: AlpesColors.arenaCalida, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Text(fecha,
                  style: const TextStyle(fontSize: 11,
                      color: AlpesColors.arenaCalida, fontWeight: FontWeight.w400)),
            ]),
          ),
          Row(children: [
            GestureDetector(
              onTap: () => _mostrarFormulario(resenaExistente: r),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: AlpesColors.oroGuatemalteco.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.edit_rounded,
                    size: 14, color: AlpesColors.oroGuatemalteco),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _eliminarResena(resenaId),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: AlpesColors.rojoColonial.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 14, color: AlpesColors.rojoColonial),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 12),
        const Divider(color: AlpesColors.pergamino, height: 1),
        const SizedBox(height: 12),
        Text(comentario,
            style: const TextStyle(
                fontSize: 13, color: AlpesColors.grafito, height: 1.5)),
      ]),
    );
  }
}

// ── Formulario agregar / editar reseña ───────────────────────────────────────
class _FormularioResena extends StatefulWidget {
  final List<Map<String, dynamic>> productosDisponibles;
  final Map<String, dynamic>? resenaExistente;
  final int clienteId;
  final VoidCallback onGuardado;

  const _FormularioResena({
    required this.productosDisponibles,
    required this.clienteId,
    required this.onGuardado,
    this.resenaExistente,
  });

  @override
  State<_FormularioResena> createState() => _FormularioResenaState();
}

class _FormularioResenaState extends State<_FormularioResena> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioCtrl = TextEditingController();
  final _nombreProductoCtrl = TextEditingController();
  int _calificacion = 5;
  String? _productoSeleccionadoId;
  bool _guardando = false;

  bool get _esEdicion => widget.resenaExistente != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final r = widget.resenaExistente!;
      _calificacion =
          int.tryParse((r['CALIFICACION'] ?? r['calificacion'] ?? 5).toString()) ?? 5;
      _comentarioCtrl.text = (r['COMENTARIO'] ?? r['comentario'] ?? '').toString();
    } else if (widget.productosDisponibles.isNotEmpty) {
      _productoSeleccionadoId =
          widget.productosDisponibles.first['producto_id']?.toString();
    }
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    _nombreProductoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final now = DateTime.now().toIso8601String();
      
      // Determine product ID for new review
      int? productoId;
      if (_esEdicion) {
        productoId = int.tryParse(
            ((widget.resenaExistente!['PRODUCTO_ID'] ?? 
              widget.resenaExistente!['producto_id']).toString())) ?? 0;
      } else {
        // If we have a selected product from dropdown, use it
        if (_productoSeleccionadoId != null && _productoSeleccionadoId!.isNotEmpty) {
          productoId = int.tryParse(_productoSeleccionadoId!) ?? 0;
        } else {
          // Otherwise, try to parse manual product name as ID if it's numeric
          final nombreInput = _nombreProductoCtrl.text.trim();
          if (nombreInput.isNotEmpty) {
            productoId = int.tryParse(nombreInput) ?? 999;
          }
        }
      }

      if (_esEdicion) {
        final r = widget.resenaExistente!;
        final resenaId = r['RESENA_ID'] ?? r['resena_id'];
        await http.put(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resenas}/$resenaId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'cli_id': widget.clienteId,
            'producto_id': productoId,
            'calificacion': _calificacion,
            'comentario': _comentarioCtrl.text.trim(),
            'resena_at': now,
          }),
        );
      } else {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resenas}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'cli_id': widget.clienteId,
            'producto_id': productoId ?? 0,
            'calificacion': _calificacion,
            'comentario': _comentarioCtrl.text.trim(),
            'resena_at': now,
          }),
        );
      }
      widget.onGuardado();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AlpesColors.rojoColonial));
      }
    }
    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                  width: 36, height: 3,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: AlpesColors.pergamino,
                      borderRadius: BorderRadius.circular(2))),
            ),
            Text(_esEdicion ? 'Editar reseña' : 'Nueva reseña',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: AlpesColors.cafeOscuro)),
            const SizedBox(height: 4),
            Text(
              _esEdicion
                  ? (widget.resenaExistente!['PRODUCTO_NOMBRE'] ??
                      widget.resenaExistente!['nombre_producto'] ?? '').toString()
                  : 'Comparte tu experiencia con el producto',
              style: const TextStyle(fontSize: 13, color: AlpesColors.arenaCalida),
            ),
            const SizedBox(height: 20),

            // Selector producto (solo en creación)
            if (!_esEdicion) ...[
              const Text('Producto',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: AlpesColors.nogalMedio)),
              const SizedBox(height: 8),
              if (widget.productosDisponibles.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: AlpesColors.pergamino),
                      borderRadius: BorderRadius.circular(12)),
                  child: DropdownButton<String>(
                    value: _productoSeleccionadoId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: widget.productosDisponibles
                        .map((p) => DropdownMenuItem<String>(
                              value: p['producto_id']?.toString(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(children: [
                                  // Foto del producto
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: AlpesColors.pergamino),
                                    child: (p['imagen'] != null && 
                                        p['imagen'].toString().isNotEmpty)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              p['imagen'].toString(),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => 
                                                const Icon(Icons.image_not_supported_rounded,
                                                  color: AlpesColors.arenaCalida),
                                            ),
                                          )
                                        : const Icon(Icons.image_not_supported_rounded,
                                            color: AlpesColors.arenaCalida),
                                  ),
                                  const SizedBox(width: 12),
                                  // Nombre del producto
                                  Expanded(
                                    child: Text(
                                      p['nombre']?.toString() ?? 'Producto',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13, color: AlpesColors.cafeOscuro),
                                    ),
                                  ),
                                ]),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _productoSeleccionadoId = v),
                  ),
                )
              else
                TextFormField(
                  controller: _nombreProductoCtrl,
                  decoration: InputDecoration(
                    hintText: 'Escribe el nombre del producto',
                    hintStyle: const TextStyle(
                        color: AlpesColors.arenaCalida, fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AlpesColors.pergamino)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AlpesColors.pergamino)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AlpesColors.cafeOscuro)),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Escribe el nombre del producto' : null,
                ),
              const SizedBox(height: 20),
            ],

            // Estrellas
            const Text('Calificación',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AlpesColors.nogalMedio)),
            const SizedBox(height: 10),
            Row(children: [
              ...List.generate(5, (i) => GestureDetector(
                    onTap: () => setState(() => _calificacion = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        i < _calificacion
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 36, color: AlpesColors.oroGuatemalteco,
                      ),
                    ),
                  )),
              const SizedBox(width: 8),
              Text('$_calificacion / 5',
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
            ]),
            const SizedBox(height: 20),

            // Comentario
            const Text('Comentario',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AlpesColors.nogalMedio)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _comentarioCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Cuéntanos tu experiencia con el producto...',
                hintStyle: const TextStyle(
                    color: AlpesColors.arenaCalida, fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AlpesColors.pergamino)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AlpesColors.pergamino)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AlpesColors.cafeOscuro)),
                contentPadding: const EdgeInsets.all(14),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Escribe un comentario' : null,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AlpesColors.cafeOscuro,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AlpesColors.nogalMedio,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _guardando
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        _esEdicion ? 'Guardar cambios' : 'Publicar reseña',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
