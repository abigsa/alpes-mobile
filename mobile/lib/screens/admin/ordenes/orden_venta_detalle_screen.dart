import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class OrdenVentaDetalleScreen extends StatefulWidget {
  final int ordenId;
  const OrdenVentaDetalleScreen({super.key, required this.ordenId});
  @override
  State<OrdenVentaDetalleScreen> createState() => _OrdenVentaDetalleScreenState();
}

// Estados lógicos del flujo de una orden
const _estadosLogicos = [
  {'key': 'INGRESADA',    'label': 'Ingresada',         'icon': Icons.inbox_rounded,              'color': Color(0xFF6B4C9A)},
  {'key': 'PENDIENTE',    'label': 'Pendiente',          'icon': Icons.access_time_rounded,        'color': Color(0xFFB7841B)},
  {'key': 'EN_PROCESO',   'label': 'En proceso',         'icon': Icons.build_rounded,              'color': Color(0xFF2F6FB2)},
  {'key': 'ENTREGADA',    'label': 'Entregada',          'icon': Icons.check_circle_rounded,       'color': Color(0xFF2E7D32)},
  {'key': 'CANCELADA',    'label': 'Cancelada',          'icon': Icons.cancel_rounded,             'color': Color(0xFFB71C1C)},
];

class _OrdenVentaDetalleScreenState extends State<OrdenVentaDetalleScreen> {
  Map<String, dynamic>? _orden;
  List<Map<String, dynamic>> _detalles = [];
  List<Map<String, dynamic>> _estadosOrden = [];
  bool _loading = true;
  bool _guardando = false;

  int? _estadoSeleccionadoId;
  int? _estadoOriginalId;
  final _comentarioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}/${widget.ordenId}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVentaDet}/buscar?criterio=orden_venta_id&valor=${widget.ordenId}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.estadoOrden}')),
      ]);

      if (!mounted) return;
      setState(() {
        final od = jsonDecode(responses[0].body);
        final dd = jsonDecode(responses[1].body);
        final ed = jsonDecode(responses[2].body);

        if (od['ok'] == true) {
          _orden = Map<String, dynamic>.from(od['data']);
          _estadoSeleccionadoId = _toInt(_orden!['ESTADO_ORDEN_ID'] ?? _orden!['estado_orden_id']);
          _estadoOriginalId = _estadoSeleccionadoId;
        }
        if (dd['ok'] == true) _detalles = List<Map<String, dynamic>>.from(dd['data']);
        if (ed['ok'] == true) _estadosOrden = List<Map<String, dynamic>>.from(ed['data']);
      });
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  int? _toInt(dynamic v) => v == null ? null : int.tryParse('$v');

  String _normFecha(dynamic v) {
    if (v == null) return '';
    return v.toString().contains('T') ? v.toString().split('T').first : v.toString();
  }

  // Resolver nombre del estado actual desde la BD
  String _nombreEstadoActual() {
    if (_orden == null) return '-';
    final id = _orden!['ESTADO_ORDEN_ID'] ?? _orden!['estado_orden_id'];
    for (final e in _estadosOrden) {
      if ('${e['ESTADO_ORDEN_ID']}' == '$id') {
        return '${e['NOMBRE'] ?? e['CODIGO'] ?? ''}';
      }
    }
    return '-';
  }

  // Mapear el estado actual de BD al estado lógico más cercano
  String _estadoLogicoClave() {
    // Primero: leer el prefijo [CLAVE] guardado en observaciones (más confiable)
    final obs = (_orden?['OBSERVACIONES'] ?? _orden?['observaciones'] ?? '').toString();
    final match = RegExp(r'^\[([A-Z_]+)\]').firstMatch(obs);
    if (match != null) {
      final clave = match.group(1)!;
      if (['INGRESADA','PENDIENTE','EN_PROCESO','ENTREGADA','CANCELADA'].contains(clave)) {
        return clave;
      }
    }

    // Fallback: nombre del estado en la BD
    final nombre = _nombreEstadoActual().toLowerCase().replaceAll('_', ' ');
    if (nombre.contains('cancel')) return 'CANCELADA';
    if (nombre.contains('entrega') || nombre.contains('complet') || nombre.contains('finaliz')) return 'ENTREGADA';
    if (nombre.contains('proceso') || nombre.contains('prepar') || nombre.contains('camino')) return 'EN_PROCESO';
    if (nombre.contains('ingres') || nombre.contains('nueva') || nombre.contains('creada')) return 'INGRESADA';

    return 'PENDIENTE';
  }

  int _indiceEstadoActual() {
    final clave = _estadoLogicoClave();
    return _estadosLogicos.indexWhere((e) => e['key'] == clave);
  }

  // Buscar el estado en BD que corresponde a una clave lógica
  int? _idEstadoParaClave(String clave) {
    final buscar = {
      'INGRESADA':  ['ingres', 'nueva', 'creada'],
      'PENDIENTE':  ['pendiente', 'pend'],
      'EN_PROCESO': ['proceso', 'prepar', 'produccion', 'camino'],
      'ENTREGADA':  ['entrega', 'complet', 'finaliz'],
      'CANCELADA':  ['cancel'],
    }[clave] ?? [];

    for (final e in _estadosOrden) {
      final nombre = '${e['NOMBRE'] ?? e['CODIGO'] ?? ''}'.toLowerCase();
      for (final kw in buscar) {
        if (nombre.contains(kw)) return _toInt(e['ESTADO_ORDEN_ID']);
      }
    }
    // Si no hay match, usar el seleccionado actual
    return _estadoSeleccionadoId;
  }

  Future<void> _cambiarEstado(String nuevaClave) async {
    if (_orden == null) return;

    final estadoLogico = _estadosLogicos.firstWhere((e) => e['key'] == nuevaClave);
    final nuevoLabel = estadoLogico['label'] as String;
    final nuevoId = _idEstadoParaClave(nuevaClave);
    final actualLabel = _estadoLogicoClave();

    if (nuevaClave == actualLabel) return;

    // Sugerir comentario según el estado
    final sugerencias = {
      'INGRESADA':  'Orden registrada en el sistema.',
      'PENDIENTE':  'Orden pendiente de procesamiento.',
      'EN_PROCESO': 'Se está preparando el pedido en bodega.',
      'ENTREGADA':  'Pedido entregado al cliente satisfactoriamente.',
      'CANCELADA':  'Orden cancelada. Especifique el motivo...',
    };
    _comentarioCtrl.text = sugerencias[nuevaClave] ?? '';

    // Mostrar dialog con comentario obligatorio
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogCambioEstado(
        estadoAnterior: _estadoLogicoClave(),
        estadoNuevo: nuevaClave,
        nuevoLabel: nuevoLabel,
        comentarioCtrl: _comentarioCtrl,
        estadosLogicos: _estadosLogicos,
      ),
    );

    if (confirmado != true) return;
    if (_comentarioCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debes agregar un comentario para el cambio de estado'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _guardando = true);
    try {
      final id = _orden!['ORDEN_VENTA_ID'] ?? _orden!['orden_venta_id'];
      final nuevoId = _idEstadoParaClave(nuevaClave);
      final comentario = '[${nuevaClave}] ${_comentarioCtrl.text.trim()}';

      // Usar el endpoint directo que hace UPDATE sin SP
      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}/$id/estado'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'estado_orden_id': nuevoId ?? _estadoSeleccionadoId,
          'observaciones': comentario,
        }),
      );
      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Estado cambiado a "$nuevoLabel"'),
          backgroundColor: AlpesColors.verdeSelva,
        ));
        await _cargar();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['mensaje'] ?? 'Error al actualizar'),
          backgroundColor: AlpesColors.rojoColonial,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AlpesColors.rojoColonial,
      ));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        backgroundColor: AlpesColors.cafeOscuro,
        foregroundColor: Colors.white,
        title: Text('Orden #${widget.ordenId}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_orden != null) ...[
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildTimelineEstados(),
                  const SizedBox(height: 16),
                ],
                _buildProductosSection(),
              ]),
            ),
    );
  }

  // ── Card de información general ──────────────────────
  Widget _buildInfoCard() {
    final num = _orden!['NUM_ORDEN'] ?? _orden!['num_orden'] ?? '-';
    final fecha = _normFecha(_orden!['FECHA_ORDEN'] ?? _orden!['fecha_orden']);
    final total = _orden!['TOTAL'] ?? _orden!['total'] ?? 0;
    final subtotal = _orden!['SUBTOTAL'] ?? _orden!['subtotal'] ?? 0;
    final impuesto = _orden!['IMPUESTO'] ?? _orden!['impuesto'] ?? 0;
    final descuento = _orden!['DESCUENTO'] ?? _orden!['descuento'] ?? 0;
    final dir = _orden!['DIRECCION_ENVIO_SNAPSHOT'] ?? _orden!['direccion_envio_snapshot'] ?? '-';
    final obsRaw = (_orden!['OBSERVACIONES'] ?? _orden!['observaciones'] ?? '').toString();
    final obs = obsRaw.replaceFirst(RegExp(r'^\[[A-Z_]+\]\s*'), '');
    final estadoClave = _estadoLogicoClave();
    final estadoInfo = _estadosLogicos.firstWhere(
      (e) => e['key'] == estadoClave, orElse: () => _estadosLogicos[1]);
    final estadoColor = estadoInfo['color'] as Color;
    final estadoLabel = estadoInfo['label'] as String;
    final estadoIcon = estadoInfo['icon'] as IconData;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AlpesColors.cafeOscuro, AlpesColors.cafeOscuro.withOpacity(0.85)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            const Icon(Icons.receipt_long_rounded, color: AlpesColors.oroGuatemalteco, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(num, style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 15)),
              Text(fecha, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: estadoColor.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(estadoIcon, color: estadoColor, size: 14),
                const SizedBox(width: 5),
                Text(estadoLabel, style: TextStyle(color: estadoColor,
                    fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        // Cuerpo
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Totales
            Row(children: [
              _infoTile('Subtotal', 'Q ${_fmt(subtotal)}', Icons.attach_money_rounded),
              const SizedBox(width: 8),
              _infoTile('Impuesto', 'Q ${_fmt(impuesto)}', Icons.percent_rounded),
              const SizedBox(width: 8),
              _infoTile('Descuento', 'Q ${_fmt(descuento)}', Icons.discount_rounded),
              const SizedBox(width: 8),
              _infoTile('TOTAL', 'Q ${_fmt(total)}', Icons.payments_rounded, highlight: true),
            ]),
            const SizedBox(height: 12),
            // Dirección
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AlpesColors.cremaFondo,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AlpesColors.pergamino),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_on_rounded, color: AlpesColors.nogalMedio, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Dirección de envío', style: TextStyle(
                      fontSize: 11, color: AlpesColors.nogalMedio, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('$dir', style: const TextStyle(fontSize: 13, color: AlpesColors.cafeOscuro)),
                ])),
              ]),
            ),
            // Observaciones/comentario actual
            if (obs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AlpesColors.oroGuatemalteco.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.2)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.comment_rounded, color: AlpesColors.oroGuatemalteco, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Último comentario', style: TextStyle(
                        fontSize: 11, color: AlpesColors.nogalMedio, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('$obs', style: const TextStyle(fontSize: 13, color: AlpesColors.cafeOscuro)),
                  ])),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  String _fmt(dynamic v) {
    final d = double.tryParse('$v') ?? 0.0;
    return d.toStringAsFixed(2);
  }

  Widget _infoTile(String label, String value, IconData icon, {bool highlight = false}) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? AlpesColors.cafeOscuro : AlpesColors.cremaFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? AlpesColors.cafeOscuro : AlpesColors.pergamino),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: highlight ? AlpesColors.oroGuatemalteco : AlpesColors.nogalMedio),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
            color: highlight ? Colors.white.withOpacity(0.7) : AlpesColors.nogalMedio)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
            color: highlight ? Colors.white : AlpesColors.cafeOscuro),
          overflow: TextOverflow.ellipsis),
      ]),
    ));
  }

  // ── Timeline de estados ───────────────────────────────
  Widget _buildTimelineEstados() {
    final currentIdx = _indiceEstadoActual();
    final cancelada = _estadoLogicoClave() == 'CANCELADA';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            const Icon(Icons.timeline_rounded, color: AlpesColors.cafeOscuro, size: 20),
            const SizedBox(width: 8),
            const Text('Gestión del estado', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
            const Spacer(),
            if (_guardando) const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AlpesColors.cafeOscuro)),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Toca un estado para cambiar la orden',
              style: TextStyle(fontSize: 12, color: AlpesColors.nogalMedio)),
        ),
        const SizedBox(height: 14),
        // Timeline horizontal
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: List.generate(_estadosLogicos.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Línea conectora
              final idx = i ~/ 2;
              final done = idx < currentIdx && !cancelada;
              return Expanded(child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 24),
                color: done ? AlpesColors.cafeOscuro : AlpesColors.pergamino,
              ));
            }
            final idx = i ~/ 2;
            final estado = _estadosLogicos[idx];
            final clave = estado['key'] as String;
            final color = estado['color'] as Color;
            final icon = estado['icon'] as IconData;
            final label = estado['label'] as String;

            final isCurrent = idx == currentIdx && !cancelada ||
                (cancelada && clave == 'CANCELADA');
            final isDone = idx < currentIdx && !cancelada;
            final isDisabled = _guardando;

            return GestureDetector(
              onTap: isDisabled ? null : () => _cambiarEstado(clave),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent ? color : isDone ? AlpesColors.cafeOscuro : Colors.white,
                    border: Border.all(
                      color: isCurrent || isDone ? Colors.transparent : AlpesColors.pergamino,
                      width: 2,
                    ),
                    boxShadow: isCurrent ? [BoxShadow(color: color.withOpacity(0.35),
                        blurRadius: 10, offset: const Offset(0, 4))] : null,
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : icon,
                    size: 20,
                    color: isCurrent || isDone ? Colors.white : AlpesColors.arenaCalida,
                  ),
                ),
                const SizedBox(height: 6),
                Text(label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                    color: isCurrent ? color : isDone ? AlpesColors.cafeOscuro : AlpesColors.nogalMedio,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]),
            );
          })),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ── Sección de productos ──────────────────────────────
  Widget _buildProductosSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.shopping_bag_rounded, color: AlpesColors.cafeOscuro, size: 18),
        const SizedBox(width: 8),
        Text('Productos (${_detalles.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: AlpesColors.cafeOscuro)),
      ]),
      const SizedBox(height: 10),
      if (_detalles.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AlpesColors.pergamino)),
          child: const Text('No hay productos en esta orden',
              textAlign: TextAlign.center,
              style: TextStyle(color: AlpesColors.nogalMedio)),
        )
      else
        ..._detalles.map((d) {
          final nombre = d['NOMBRE'] ?? d['nombre'] ?? 'Producto #${d['PRODUCTO_ID'] ?? d['producto_id']}';
          final cantidad = d['CANTIDAD'] ?? d['cantidad'] ?? 0;
          final precio = d['PRECIO_UNITARIO_SNAPSHOT'] ?? d['precio_unitario_snapshot'] ?? 0;
          final subtotal = d['SUBTOTAL_LINEA'] ?? d['subtotal_linea'] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AlpesColors.pergamino),
              boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.04),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AlpesColors.cremaFondo,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.chair_alt_rounded,
                    color: AlpesColors.arenaCalida, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$nombre', style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
                const SizedBox(height: 3),
                Text('Cantidad: $cantidad  ·  Precio unit: Q ${_fmt(precio)}',
                    style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
              ])),
              Text('Q ${_fmt(subtotal)}', style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: AlpesColors.cafeOscuro)),
            ]),
          );
        }),
    ]);
  }
}

// ── Dialog de cambio de estado ───────────────────────────
class _DialogCambioEstado extends StatefulWidget {
  final String estadoAnterior;
  final String estadoNuevo;
  final String nuevoLabel;
  final TextEditingController comentarioCtrl;
  final List<Map<String, Object>> estadosLogicos;

  const _DialogCambioEstado({
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.nuevoLabel,
    required this.comentarioCtrl,
    required this.estadosLogicos,
  });

  @override
  State<_DialogCambioEstado> createState() => _DialogCambioEstadoState();
}

class _DialogCambioEstadoState extends State<_DialogCambioEstado> {
  @override
  Widget build(BuildContext context) {
    final nuevoInfo = widget.estadosLogicos.firstWhere(
      (e) => e['key'] == widget.estadoNuevo, orElse: () => widget.estadosLogicos[1]);
    final nuevoColor = nuevoInfo['color'] as Color;
    final nuevoIcon = nuevoInfo['icon'] as IconData;
    final anteriorInfo = widget.estadosLogicos.firstWhere(
      (e) => e['key'] == widget.estadoAnterior, orElse: () => widget.estadosLogicos[1]);
    final anteriorLabel = anteriorInfo['label'] as String;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: nuevoColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(nuevoIcon, color: nuevoColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Cambiar estado', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: AlpesColors.cafeOscuro)),
              Text('"$anteriorLabel" → "${widget.nuevoLabel}"',
                  style: const TextStyle(fontSize: 12, color: AlpesColors.nogalMedio)),
            ])),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          // Comentario
          const Text('Comentario *', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
          const SizedBox(height: 4),
          Text('Describe el motivo del cambio de estado. Este comentario quedará registrado en la orden.',
              style: TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
          const SizedBox(height: 10),
          TextField(
            controller: widget.comentarioCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ej: Se inicia la preparación del pedido en bodega...',
              hintStyle: TextStyle(color: AlpesColors.nogalMedio.withOpacity(0.6), fontSize: 12),
              filled: true,
              fillColor: AlpesColors.cremaFondo,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AlpesColors.pergamino),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AlpesColors.pergamino),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: nuevoColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // Botones
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: AlpesColors.pergamino),
              ),
              child: const Text('Cancelar', style: TextStyle(color: AlpesColors.nogalMedio)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: widget.comentarioCtrl.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: nuevoColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: AlpesColors.pergamino,
              ),
              child: Text('Confirmar', style: const TextStyle(fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
    );
  }
}
