import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class ProduccionScreen extends StatefulWidget {
  const ProduccionScreen({super.key});

  @override
  State<ProduccionScreen> createState() => _ProduccionScreenState();
}

class _ProduccionScreenState extends State<ProduccionScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _estadosProduccion = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.ordenProduccion)),
        http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.productos)),
        http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.estadoProduccion)),
      ]);

      final ordenesData = jsonDecode(responses[0].body);
      final productosData = jsonDecode(responses[1].body);
      final estadosData = jsonDecode(responses[2].body);

      if (!mounted) return;

      setState(() {
        _items = ordenesData['ok'] == true
            ? List<Map<String, dynamic>>.from(ordenesData['data'])
            : [];
        _productos = productosData['ok'] == true
            ? List<Map<String, dynamic>>.from(productosData['data'])
            : [];
        _estadosProduccion = estadosData['ok'] == true
            ? List<Map<String, dynamic>>.from(estadosData['data'])
            : [];
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _eliminar(dynamic id) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      title: const Text('Eliminar orden de producción'),
      content: const Text('¿Estás seguro?'),
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
    Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenProduccion}/$id'),
  );
  _cargar();
}

  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProduccionForm(
        item: item,
        productos: _productos,
        estadosProduccion: _estadosProduccion,
        onGuardado: _cargar,
      ),
    );
  }

  String _formatearFecha(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '';
    final raw = value.toString().trim();
    if (raw.contains('T')) return raw.split('T').first;
    return raw;
  }

  String _nombreProducto(dynamic productoId) {
    Map<String, dynamic>? producto;
    for (final p in _productos) {
      if ('${p['PRODUCTO_ID']}' == '$productoId') {
        producto = p;
        break;
      }
    }

    if (producto == null) return 'Producto #$productoId';

    final nombre = '${producto['NOMBRE'] ?? ''}'.trim();
    final referencia = '${producto['REFERENCIA'] ?? ''}'.trim();

    if (nombre.isEmpty && referencia.isEmpty) {
      return 'Producto #$productoId';
    }

    if (referencia.isEmpty) return nombre;
    if (nombre.isEmpty) return referencia;

    return '$nombre ($referencia)';
  }

  String _codigoEstado(dynamic estadoId) {
    Map<String, dynamic>? estado;
    for (final e in _estadosProduccion) {
      if ('${e['ESTADO_PRODUCCION_ID']}' == '$estadoId') {
        estado = e;
        break;
      }
    }

    if (estado == null) return '';
    return '${estado['CODIGO'] ?? ''}'.trim();
  }

  Color _colorEstado(String e) {
    switch (e.toLowerCase()) {
      case 'completada':
        return const Color(0xFF3B6D11);
      case 'en proceso':
        return const Color(0xFF185FA5);
      case 'planificada':
        return const Color(0xFF854F0B);
      case 'enviada':
        return const Color(0xFF185FA5);
      case 'cancelada':
        return AlpesColors.rojoColonial;
      case 'activo':
        return AlpesColors.nogalMedio;
      default:
        return AlpesColors.nogalMedio;
    }
  }

  Color _bgEstado(String e) {
    switch (e.toLowerCase()) {
      case 'completada':
        return const Color(0xFFEAF3DE);
      case 'en proceso':
        return const Color(0xFFE6F1FB);
      case 'planificada':
        return const Color(0xFFFAEEDA);
      case 'enviada':
        return const Color(0xFFE6F1FB);
      case 'cancelada':
        return const Color(0xFFFCEBEB);
      case 'activo':
        return AlpesColors.pergamino;
      default:
        return AlpesColors.pergamino;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enProceso = _items.where((o) {
      final codigo = _codigoEstado(
        o['ESTADO_PRODUCCION_ID'] ?? o['estado_produccion_id'],
      ).toLowerCase();
      return codigo == 'en proceso';
    }).length;

    final completadas = _items.where((o) {
      final codigo = _codigoEstado(
        o['ESTADO_PRODUCCION_ID'] ?? o['estado_produccion_id'],
      ).toLowerCase();
      return codigo == 'completada';
    }).length;

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('PRODUCCIÓN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AlpesColors.cafeOscuro),
            )
          : RefreshIndicator(
              color: AlpesColors.cafeOscuro,
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  if (_items.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Total órdenes',
                            '${_items.length}',
                            Icons.factory_rounded,
                            AlpesColors.cafeOscuro,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            'En proceso',
                            '$enProceso',
                            Icons.loop_rounded,
                            const Color(0xFF185FA5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            'Completadas',
                            '$completadas',
                            Icons.check_circle_rounded,
                            const Color(0xFF3B6D11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  ..._items.map((o) {
                    final id = o['ORDEN_PRODUCCION_ID'] ??
                        o['orden_produccion_id'] ??
                        o['ID'] ??
                        o['id'];
                    final num = o['NUM_OP'] ?? o['num_op'] ?? '#$id';
                    final prodId = o['PRODUCTO_ID'] ?? o['producto_id'] ?? '-';
                    final cantidad =
                        o['CANTIDAD_PLANIFICADA'] ?? o['cantidad_planificada'] ?? 0;
                    final estadoTexto = _codigoEstado(
                      o['ESTADO_PRODUCCION_ID'] ?? o['estado_produccion_id'],
                    ).isNotEmpty
                        ? _codigoEstado(
                            o['ESTADO_PRODUCCION_ID'] ?? o['estado_produccion_id'],
                          )
                        : (o['ESTADO'] ?? o['estado'] ?? '-').toString();
                    final inicio = _formatearFecha(
                      o['INICIO_ESTIMADO'] ?? o['inicio_estimado'],
                    );
                    final fin = _formatearFecha(
                      o['FIN_ESTIMADO'] ?? o['fin_estimado'],
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AlpesColors.pergamino),
                        boxShadow: [
                          BoxShadow(
                            color: AlpesColors.cafeOscuro.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AlpesColors.verdeSelva.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.factory_rounded,
                                color: AlpesColors.verdeSelva,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$num',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AlpesColors.cafeOscuro,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${_nombreProducto(prodId)}  ·  Cant: $cantidad',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AlpesColors.nogalMedio,
                                    ),
                                  ),
                                  if (inicio.isNotEmpty)
                                    Text(
                                      '$inicio → $fin',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AlpesColors.arenaCalida,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _bgEstado(estadoTexto),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    estadoTexto,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _colorEstado(estadoTexto),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _iBtn(
                                      Icons.edit_outlined,
                                      AlpesColors.nogalMedio,
                                      () => _abrirForm(o),
                                    ),
                                    const SizedBox(width: 4),
                                    _iBtn(
                                      Icons.delete_outline,
                                      AlpesColors.rojoColonial,
                                      () => _eliminar(id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AlpesColors.cafeOscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva orden',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        onPressed: () => _abrirForm(),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AlpesColors.cafeOscuro,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: AlpesColors.nogalMedio),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _iBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

class _ProduccionForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final List<Map<String, dynamic>> productos;
  final List<Map<String, dynamic>> estadosProduccion;
  final VoidCallback onGuardado;

  const _ProduccionForm({
    this.item,
    required this.productos,
    required this.estadosProduccion,
    required this.onGuardado,
  });

  @override
  State<_ProduccionForm> createState() => __ProduccionFormState();
}

class __ProduccionFormState extends State<_ProduccionForm> {
  final _fk = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  bool _g = false;

  int? _productoIdSeleccionado;
  int? _estadoProduccionIdSeleccionado;

  @override
  void initState() {
    super.initState();

    _c = {
      'num_op': TextEditingController(),
      'cantidad_planificada': TextEditingController(),
      'inicio_estimado': TextEditingController(),
      'fin_estimado': TextEditingController(),
      'estado': TextEditingController(text: 'ACTIVO'),
    };

    if (widget.item != null) {
      _c['num_op']!.text = '${widget.item!['NUM_OP'] ?? widget.item!['num_op'] ?? ''}';
      _c['cantidad_planificada']!.text =
          '${widget.item!['CANTIDAD_PLANIFICADA'] ?? widget.item!['cantidad_planificada'] ?? ''}';
      _c['inicio_estimado']!.text = _normalizarFecha(
        widget.item!['INICIO_ESTIMADO'] ?? widget.item!['inicio_estimado'],
      );
      _c['fin_estimado']!.text = _normalizarFecha(
        widget.item!['FIN_ESTIMADO'] ?? widget.item!['fin_estimado'],
      );
      _c['estado']!.text =
          '${widget.item!['ESTADO'] ?? widget.item!['estado'] ?? 'ACTIVO'}';

      _productoIdSeleccionado = _toInt(
        widget.item!['PRODUCTO_ID'] ?? widget.item!['producto_id'],
      );
      _estadoProduccionIdSeleccionado = _toInt(
        widget.item!['ESTADO_PRODUCCION_ID'] ?? widget.item!['estado_produccion_id'],
      );
    }

    _productoIdSeleccionado = _validIntDropdownValue(
      _productoIdSeleccionado,
      _productosActivos
          .map((e) => _toInt(e['PRODUCTO_ID']))
          .whereType<int>()
          .toList(),
    );

    _estadoProduccionIdSeleccionado = _validIntDropdownValue(
      _estadoProduccionIdSeleccionado,
      _estadosActivos
          .map((e) => _toInt(e['ESTADO_PRODUCCION_ID']))
          .whereType<int>()
          .toList(),
    );
  }

  List<Map<String, dynamic>> get _productosActivos => widget.productos
      .where((e) => '${e['ESTADO'] ?? ''}'.toUpperCase() == 'ACTIVO')
      .toList();

  List<Map<String, dynamic>> get _estadosActivos => widget.estadosProduccion
      .where((e) => '${e['ESTADO'] ?? ''}'.toUpperCase() == 'ACTIVO')
      .toList();

  int? _validIntDropdownValue(int? value, List<int> items) {
    if (value == null) return null;
    return items.contains(value) ? value : null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse('$value');
  }

  String _normalizarFecha(dynamic value) {
    if (value == null) return '';
    final raw = value.toString().trim();
    if (raw.isEmpty) return '';
    if (raw.contains('T')) return raw.split('T').first;
    return raw;
  }

  DateTime _parseFecha(String text) {
    try {
      return DateTime.parse(text);
    } catch (_) {
      return DateTime.now();
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _seleccionarFecha(String key) async {
    final inicial = _c[key]!.text.trim().isNotEmpty
        ? _parseFecha(_c[key]!.text.trim())
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _c[key]!.text = _formatDate(picked);
      });
    }
  }

  bool _fechasValidas() {
    final inicioTxt = _c['inicio_estimado']!.text.trim();
    final finTxt = _c['fin_estimado']!.text.trim();

    if (inicioTxt.isEmpty || finTxt.isEmpty) return true;

    final inicio = _parseFecha(inicioTxt);
    final fin = _parseFecha(finTxt);

    if (fin.isBefore(inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha fin no puede ser menor que la fecha inicio'),
          backgroundColor: AlpesColors.rojoColonial,
        ),
      );
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_fk.currentState!.validate()) return;
    if (!_fechasValidas()) return;

    setState(() => _g = true);
    try {
      final body = {
        'num_op': _c['num_op']!.text.trim(),
        'producto_id': _productoIdSeleccionado,
        'cantidad_planificada': _c['cantidad_planificada']!.text.trim(),
        'estado_produccion_id': _estadoProduccionIdSeleccionado,
        'inicio_estimado': _c['inicio_estimado']!.text.trim(),
        'fin_estimado': _c['fin_estimado']!.text.trim(),
        'inicio_real': null,
        'fin_real': null,
        'estado': _c['estado']!.text.trim().isEmpty ? 'ACTIVO' : _c['estado']!.text.trim(),
      };

      final id = widget.item?['ORDEN_PRODUCCION_ID'] ??
          widget.item?['orden_produccion_id'] ??
          widget.item?['ID'] ??
          widget.item?['id'];

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.ordenProduccion}${id != null ? '/$id' : ''}',
      );

      final res = id != null
          ? await http.put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
          : await http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            );

      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        widget.onGuardado();
        if (context.mounted) Navigator.pop(context);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['mensaje'] ?? 'Error'),
            backgroundColor: AlpesColors.rojoColonial,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AlpesColors.rojoColonial,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _g = false);
      }
    }
  }

  Widget _campoTexto(String label, String key, {bool req = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[key],
        decoration: InputDecoration(labelText: label),
        validator: req
            ? (v) => v == null || v.trim().isEmpty ? 'Requerido' : null
            : null,
      ),
    );
  }

  Widget _campoNumero(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Requerido';
          if (double.tryParse(v.trim()) == null) return 'Ingresa un número válido';
          return null;
        },
      ),
    );
  }

  Widget _campoFecha(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[key],
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        onTap: () => _seleccionarFecha(key),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Requerido';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productosDropdown = _productosActivos
        .map<DropdownMenuItem<int>?>((p) {
          final productoId = _toInt(p['PRODUCTO_ID']);
          if (productoId == null) return null;

          final nombre = '${p['NOMBRE'] ?? ''}'.trim();
          final referencia = '${p['REFERENCIA'] ?? ''}'.trim();
          final label = nombre.isEmpty && referencia.isEmpty
              ? 'Producto #$productoId'
              : referencia.isEmpty
                  ? nombre
                  : '$nombre ($referencia)';

          return DropdownMenuItem<int>(
            value: productoId,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          );
        })
        .whereType<DropdownMenuItem<int>>()
        .toList();

    final estadosDropdown = _estadosActivos
        .map<DropdownMenuItem<int>?>((e) {
          final estadoId = _toInt(e['ESTADO_PRODUCCION_ID']);
          if (estadoId == null) return null;

          final codigo = '${e['CODIGO'] ?? ''}'.trim();
          return DropdownMenuItem<int>(
            value: estadoId,
            child: Text(
              codigo.isEmpty ? 'Estado #$estadoId' : codigo,
              overflow: TextOverflow.ellipsis,
            ),
          );
        })
        .whereType<DropdownMenuItem<int>>()
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Form(
          key: _fk,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AlpesColors.pergamino,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  widget.item == null
                      ? 'Nueva orden de producción'
                      : 'Editar orden',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AlpesColors.cafeOscuro,
                  ),
                ),
                const SizedBox(height: 16),
                _campoTexto('No. OP', 'num_op', req: true),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<int>(
                    value: _productoIdSeleccionado,
                    decoration: const InputDecoration(labelText: 'Producto'),
                    items: productosDropdown,
                    onChanged: (value) {
                      setState(() => _productoIdSeleccionado = value);
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona un producto' : null,
                  ),
                ),
                _campoNumero('Cantidad planificada', 'cantidad_planificada'),
                Row(
                  children: [
                    Expanded(
                      child: _campoFecha('Inicio estimado', 'inicio_estimado'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _campoFecha('Fin estimado', 'fin_estimado'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<int>(
                    value: _estadoProduccionIdSeleccionado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: estadosDropdown,
                    onChanged: (value) {
                      setState(() => _estadoProduccionIdSeleccionado = value);
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona un estado' : null,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _g ? null : _guardar,
                  child: _g
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('GUARDAR'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}