import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class OrdenesVentaScreen extends StatefulWidget {
  const OrdenesVentaScreen({super.key});

  @override
  State<OrdenesVentaScreen> createState() => _OrdenesVentaScreenState();
}

class _OrdenesVentaScreenState extends State<OrdenesVentaScreen> {
  List<Map<String, dynamic>> _ordenes = [];
  List<Map<String, dynamic>> _filtradas = [];
  List<Map<String, dynamic>> _detalles = [];
  List<Map<String, dynamic>> _estadosOrden = [];
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _metodosPago = [];
  bool _loading = true;
  String _filtroEstado = 'Todos';
  final _searchCtrl = TextEditingController();

  static const _filtros = [
    {'label': 'Todos', 'color': null},
    {'label': 'Pendiente', 'color': Color(0xFF854F0B)},
    {'label': 'En proceso', 'color': Color(0xFF185FA5)},
    {'label': 'Entregado', 'color': Color(0xFF3B6D11)},
    {'label': 'Cancelado', 'color': Color(0xFFB91C1C)},
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVentaDet}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.estadoOrden}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cliente}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.metodoPago}')),
      ]);
      if (!mounted) return;
      final ordenesData = jsonDecode(responses[0].body);
      final detallesData = jsonDecode(responses[1].body);
      final estadosData = jsonDecode(responses[2].body);
      final clientesData = jsonDecode(responses[3].body);
      final pagosData = jsonDecode(responses[4].body);
      setState(() {
        _ordenes = ordenesData['ok'] == true
            ? List<Map<String, dynamic>>.from(ordenesData['data'])
            : [];
        _detalles = detallesData['ok'] == true
            ? List<Map<String, dynamic>>.from(detallesData['data'])
            : [];
        _estadosOrden = estadosData['ok'] == true
            ? List<Map<String, dynamic>>.from(estadosData['data'])
            : [];
        _clientes = clientesData['ok'] == true
            ? List<Map<String, dynamic>>.from(clientesData['data'])
            : [];
        _metodosPago = pagosData['ok'] == true
            ? List<Map<String, dynamic>>.from(pagosData['data'])
            : [];
      });
      _ordenes.sort((a, b) {
        final bd = _parseFecha(b['FECHA_ORDEN'] ?? b['fecha_orden']);
        final ad = _parseFecha(a['FECHA_ORDEN'] ?? a['fecha_orden']);
        if (ad != null && bd != null) return bd.compareTo(ad);
        final bi = int.tryParse('${b['ORDEN_VENTA_ID'] ?? b['orden_venta_id'] ?? 0}') ?? 0;
        final ai = int.tryParse('${a['ORDEN_VENTA_ID'] ?? a['orden_venta_id'] ?? 0}') ?? 0;
        return bi.compareTo(ai);
      });
      _aplicarFiltros();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime? _parseFecha(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return DateTime.tryParse(value.toString().trim());
  }

  String _normalizarFecha(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '';
    final dt = _parseFecha(value);
    if (dt == null) {
      final raw = value.toString().trim();
      return raw.contains('T') ? raw.split('T').first : raw;
    }
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  String _capitalizar(String value) {
    if (value.trim().isEmpty) return value;
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  String _mapearEstadoVisual(String value) {
    final clean = value.trim().toLowerCase();
    if (clean == 'completada' || clean == 'completado') return 'Entregado';
    if (clean == 'cancelada') return 'Cancelado';
    return _capitalizar(value);
  }

  String _resolverEstadoOrden(dynamic estadoOrdenId) {
    for (final e in _estadosOrden) {
      if ('${e['ESTADO_ORDEN_ID']}' == '$estadoOrdenId') {
        final codigo = '${e['CODIGO'] ?? e['codigo'] ?? ''}'.trim();
        if (codigo.isNotEmpty) return _mapearEstadoVisual(codigo);
      }
    }
    return '';
  }

  String _resolverCliente(dynamic cliId) {
    for (final c in _clientes) {
      final id = c['CLI_ID'] ?? c['cli_id'];
      if ('$id' == '$cliId') {
        final n = '${c['NOMBRES'] ?? c['nombres'] ?? ''}'.trim();
        final a = '${c['APELLIDOS'] ?? c['apellidos'] ?? ''}'.trim();
        return '$n $a'.trim();
      }
    }
    return '';
  }

  String _resolverMetodoPago(dynamic metodoId) {
    for (final m in _metodosPago) {
      final id = m['METODO_PAGO_ID'] ?? m['metodo_pago_id'];
      if ('$id' == '$metodoId') {
        return '${m['NOMBRE'] ?? m['nombre'] ?? ''}'.trim();
      }
    }
    return '';
  }

  Map<String, dynamic> _resumenDetalle(dynamic ordenId) {
    int lineas = 0;
    int cantidadTotal = 0;
    double subtotalDetalle = 0;
    for (final d in _detalles) {
      final detOrdenId = d['ORDEN_VENTA_ID'] ?? d['orden_venta_id'];
      if ('$detOrdenId' == '$ordenId') {
        lineas++;
        cantidadTotal += int.tryParse('${d['CANTIDAD'] ?? d['cantidad'] ?? 0}') ?? 0;
        subtotalDetalle +=
            double.tryParse('${d['SUBTOTAL_LINEA'] ?? d['subtotal_linea'] ?? 0}') ?? 0;
      }
    }
    return {
      'lineas': lineas,
      'cantidad': cantidadTotal,
      'subtotalDetalle': subtotalDetalle,
    };
  }

  void _aplicarFiltros() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtradas = _ordenes.where((o) {
        final num = '${o['NUM_ORDEN'] ?? o['num_orden'] ?? ''}'.toLowerCase();
        final estadoReal = _resolverEstadoOrden(o['ESTADO_ORDEN_ID'] ?? o['estado_orden_id']);
        final estadoTxt = estadoReal.isEmpty ? '' : estadoReal;
        final cliente = _resolverCliente(o['CLI_ID'] ?? o['cli_id']).toLowerCase();
        final metodo = _resolverMetodoPago(o['METODO_PAGO_ID'] ?? o['metodo_pago_id']).toLowerCase();
        final obs = '${o['OBSERVACIONES'] ?? o['observaciones'] ?? ''}'.toLowerCase();
        final direccion = '${o['DIRECCION_ENVIO_SNAPSHOT'] ?? o['direccion_envio_snapshot'] ?? ''}'.toLowerCase();
        final matchQ = q.isEmpty ||
            num.contains(q) ||
            cliente.contains(q) ||
            metodo.contains(q) ||
            obs.contains(q) ||
            direccion.contains(q);
        final matchE = _filtroEstado == 'Todos' || estadoTxt == _filtroEstado;
        return matchQ && matchE;
      }).toList();
    });
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado':
        return const Color(0xFF3B6D11);
      case 'pendiente':
        return const Color(0xFF854F0B);
      case 'en proceso':
        return const Color(0xFF185FA5);
      case 'cancelado':
        return AlpesColors.rojoColonial;
      default:
        return AlpesColors.nogalMedio;
    }
  }

  Color _bgEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado':
        return const Color(0xFFEAF3DE);
      case 'pendiente':
        return const Color(0xFFFAEEDA);
      case 'en proceso':
        return const Color(0xFFE6F1FB);
      case 'cancelado':
        return const Color(0xFFFCEBEB);
      default:
        return AlpesColors.pergamino;
    }
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Map<String, int> get _countsPorEstado {
    final counts = <String, int>{};
    for (final o in _ordenes) {
      final raw = _resolverEstadoOrden(o['ESTADO_ORDEN_ID'] ?? o['estado_orden_id']);
      final e = raw.isEmpty ? 'Sin estado' : raw;
      counts[e] = (counts[e] ?? 0) + 1;
    }
    return counts;
  }

  double get _totalFiltrado => _filtradas.fold<double>(
        0,
        (sum, o) => sum + (double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0),
      );

  int get _pendientes => _filtradas.where((o) {
        final estado = _resolverEstadoOrden(o['ESTADO_ORDEN_ID'] ?? o['estado_orden_id']).toLowerCase();
        return estado == 'pendiente';
      }).length;

  int get _canceladas => _filtradas.where((o) {
        final estado = _resolverEstadoOrden(o['ESTADO_ORDEN_ID'] ?? o['estado_orden_id']).toLowerCase();
        return estado == 'cancelado';
      }).length;

  int get _itemsFiltrados {
    int total = 0;
    for (final o in _filtradas) {
      final resumen = _resumenDetalle(o['ORDEN_VENTA_ID'] ?? o['orden_venta_id']);
      total += resumen['cantidad'] as int;
    }
    return total;
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: AlpesColors.cafeOscuro.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AlpesColors.nogalMedio,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AlpesColors.cafeOscuro,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: RefreshIndicator(
        color: AlpesColors.cafeOscuro,
        onRefresh: _cargar,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: AlpesColors.cafeOscuro,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/admin'),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Órdenes de Venta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (!_loading)
                      Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AlpesColors.oroGuatemalteco.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AlpesColors.oroGuatemalteco.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          '${_ordenes.length}',
                          style: const TextStyle(
                            color: AlpesColors.oroGuatemalteco,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                background: Stack(
                  children: [
                    Container(color: AlpesColors.cafeOscuro),
                    Positioned(
                      top: -35,
                      right: -25,
                      child: _circle(140, AlpesColors.oroGuatemalteco.withOpacity(0.07)),
                    ),
                    Positioned(
                      top: 15,
                      right: 70,
                      child: _circle(60, AlpesColors.oroGuatemalteco.withOpacity(0.05)),
                    ),
                    Positioned(
                      bottom: -15,
                      left: 80,
                      child: _circle(80, AlpesColors.oroGuatemalteco.withOpacity(0.06)),
                    ),
                    Positioned(
                      top: 30,
                      left: -20,
                      child: _circle(65, AlpesColors.oroGuatemalteco.withOpacity(0.04)),
                    ),
                    if (!_loading && _countsPorEstado.isNotEmpty)
                      Positioned(
                        bottom: 44,
                        right: 16,
                        child: Row(
                          children: _countsPorEstado.entries.take(3).map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _bgEstado(e.key).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${e.value} ${e.key}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: _colorEstado(e.key),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AlpesColors.oroGuatemalteco.withOpacity(0.45),
                              AlpesColors.oroGuatemalteco.withOpacity(0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 20,
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 40,
                        color: AlpesColors.oroGuatemalteco.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => _aplicarFiltros(),
                      decoration: InputDecoration(
                        hintText: 'Buscar por orden, cliente, pago u observación…',
                        hintStyle: const TextStyle(
                          color: AlpesColors.arenaCalida,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AlpesColors.nogalMedio,
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: AlpesColors.arenaCalida,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _aplicarFiltros();
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        filled: true,
                        fillColor: AlpesColors.cremaFondo,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: AlpesColors.oroGuatemalteco.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filtros.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final f = _filtros[i];
                          final label = f['label'] as String;
                          final fColor = f['color'] as Color?;
                          final active = _filtroEstado == label;
                          int count = 0;
                          if (label != 'Todos') {
                            count = _ordenes.where((o) {
                              final r = _resolverEstadoOrden(o['ESTADO_ORDEN_ID'] ?? o['estado_orden_id']);
                              return r == label;
                            }).length;
                          }
                          return _FiltroChip(
                            label: label,
                            count: label == 'Todos' ? _ordenes.length : count,
                            active: active,
                            accentColor: fColor,
                            onTap: () {
                              setState(() => _filtroEstado = label);
                              _aplicarFiltros();
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                child: Column(
                  children: [
                    _metricCard(
                      label: 'Ventas filtradas',
                      value: 'Q ${_totalFiltrado.toStringAsFixed(2)}',
                      icon: Icons.payments_outlined,
                      accent: AlpesColors.cafeOscuro,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            label: 'Pendientes',
                            value: '$_pendientes',
                            icon: Icons.hourglass_top_rounded,
                            accent: const Color(0xFF854F0B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _metricCard(
                            label: 'Items visibles',
                            value: '$_itemsFiltrados',
                            icon: Icons.inventory_2_outlined,
                            accent: AlpesColors.oroGuatemalteco,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _metricCard(
                            label: 'Canceladas',
                            value: '$_canceladas',
                            icon: Icons.cancel_outlined,
                            accent: AlpesColors.rojoColonial,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: AlpesColors.cremaFondo,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AlpesColors.oroGuatemalteco,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _loading
                          ? 'Cargando…'
                          : '${_filtradas.length} orden${_filtradas.length != 1 ? 'es' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AlpesColors.nogalMedio,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AlpesColors.cafeOscuro),
                ),
              )
            else if (_filtradas.isEmpty)
              SliverFillRemaining(child: _emptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final o = _filtradas[i];
                      final id = o['ORDEN_VENTA_ID'] ?? o['orden_venta_id'];
                      final num = o['NUM_ORDEN'] ?? o['num_orden'] ?? '#$id';
                      final total = double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0;
                      final subtotal = double.tryParse('${o['SUBTOTAL'] ?? o['subtotal'] ?? 0}') ?? 0;
                      final descuento = double.tryParse('${o['DESCUENTO'] ?? o['descuento'] ?? 0}') ?? 0;
                      final impuesto = double.tryParse('${o['IMPUESTO'] ?? o['impuesto'] ?? 0}') ?? 0;
                      final fecha = _normalizarFecha(o['FECHA_ORDEN'] ?? o['fecha_orden']);
                      final estadoReal = _resolverEstadoOrden(o['ESTADO_ORDEN_ID'] ?? o['estado_orden_id']);
                      final estado = estadoReal.isEmpty ? 'Sin estado' : estadoReal;
                      final cliId = o['CLI_ID'] ?? o['cli_id'];
                      final cliente = _resolverCliente(cliId);
                      final metodoPagoId = o['METODO_PAGO_ID'] ?? o['metodo_pago_id'];
                      final metodoPago = _resolverMetodoPago(metodoPagoId);
                      final observaciones = '${o['OBSERVACIONES'] ?? o['observaciones'] ?? ''}'.trim();
                      final fechaEntrega = _normalizarFecha(o['FECHA_ENTREGA'] ?? o['fecha_entrega']);
                      final moneda = '${o['MONEDA'] ?? o['moneda'] ?? 'GTQ'}'.trim();
                      final direccion = '${o['DIRECCION_ENVIO_SNAPSHOT'] ?? o['direccion_envio_snapshot'] ?? ''}'.trim();
                      final resumen = _resumenDetalle(id);

                      return _HoverOrdenCard(
                        num: '$num',
                        total: total,
                        subtotal: subtotal,
                        descuento: descuento,
                        impuesto: impuesto,
                        fecha: fecha,
                        estado: estado,
                        cliente: cliente,
                        metodoPago: metodoPago,
                        observaciones: observaciones,
                        fechaEntrega: fechaEntrega,
                        moneda: moneda,
                        direccion: direccion,
                        items: resumen['cantidad'] as int,
                        lineas: resumen['lineas'] as int,
                        colorEstado: _colorEstado(estado),
                        bgEstado: _bgEstado(estado),
                        onTap: () async {
                          await context.push('/admin/ordenes/$id');
                          if (mounted) _cargar();
                        },
                      );
                    },
                    childCount: _filtradas.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 38,
                color: AlpesColors.oroGuatemalteco.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Sin órdenes',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AlpesColors.cafeOscuro,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No se encontraron resultados para este filtro',
              style: TextStyle(fontSize: 13, color: AlpesColors.nogalMedio),
            ),
          ],
        ),
      );
}

class _FiltroChip extends StatefulWidget {
  final String label;
  final int count;
  final bool active;
  final Color? accentColor;
  final VoidCallback onTap;
  const _FiltroChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
    this.accentColor,
  });

  @override
  State<_FiltroChip> createState() => _FiltroChipState();
}

class _FiltroChipState extends State<_FiltroChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AlpesColors.cafeOscuro;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.active
                ? accent
                : _hovered
                    ? accent.withOpacity(0.08)
                    : AlpesColors.cremaFondo,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.active
                  ? accent
                  : _hovered
                      ? accent.withOpacity(0.4)
                      : AlpesColors.arenaCalida,
              width: widget.active ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: widget.active ? Colors.white : accent,
                ),
              ),
              if (widget.count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.active
                        ? Colors.white.withOpacity(0.25)
                        : accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: widget.active ? Colors.white : accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverOrdenCard extends StatefulWidget {
  final String num;
  final double total;
  final double subtotal;
  final double descuento;
  final double impuesto;
  final String fecha;
  final String estado;
  final String cliente;
  final String metodoPago;
  final String observaciones;
  final String fechaEntrega;
  final String moneda;
  final String direccion;
  final int items;
  final int lineas;
  final Color colorEstado;
  final Color bgEstado;
  final VoidCallback onTap;
  const _HoverOrdenCard({
    required this.num,
    required this.total,
    required this.subtotal,
    required this.descuento,
    required this.impuesto,
    required this.fecha,
    required this.estado,
    required this.cliente,
    required this.metodoPago,
    required this.observaciones,
    required this.fechaEntrega,
    required this.moneda,
    required this.direccion,
    required this.items,
    required this.lineas,
    required this.colorEstado,
    required this.bgEstado,
    required this.onTap,
  });

  @override
  State<_HoverOrdenCard> createState() => _HoverOrdenCardState();
}

class _HoverOrdenCardState extends State<_HoverOrdenCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final moneyPrefix = widget.moneda.toUpperCase() == 'GTQ' ? 'Q' : widget.moneda;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 10),
          transform: Matrix4.identity()..translate(0.0, _hovered ? -3.0 : 0.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _hovered
                  ? [Colors.white, AlpesColors.oroGuatemalteco.withOpacity(0.06)]
                  : [Colors.white, const Color(0xFFF9F6F2)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? AlpesColors.oroGuatemalteco.withOpacity(0.55)
                  : AlpesColors.pergamino,
              width: _hovered ? 1.5 : 1.0,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AlpesColors.cafeOscuro.withOpacity(0.11),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AlpesColors.oroGuatemalteco.withOpacity(0.07),
                      blurRadius: 6,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AlpesColors.cafeOscuro.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _hovered
                            ? AlpesColors.cafeOscuro.withOpacity(0.12)
                            : AlpesColors.cafeOscuro.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AlpesColors.cafeOscuro,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.num,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _hovered
                                  ? AlpesColors.oroGuatemalteco
                                  : AlpesColors.cafeOscuro,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (widget.cliente.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                widget.cliente,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AlpesColors.nogalMedio,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (widget.fecha.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 10,
                                    color: AlpesColors.arenaCalida,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.fecha,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AlpesColors.nogalMedio,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$moneyPrefix ${widget.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AlpesColors.cafeOscuro,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.bgEstado,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.estado,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: widget.colorEstado,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _hovered ? 1.0 : 0.4,
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AlpesColors.arenaCalida,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (widget.metodoPago.isNotEmpty)
                      _infoChip(Icons.payment_rounded, widget.metodoPago),
                    if (widget.items > 0)
                      _infoChip(
                        Icons.shopping_bag_outlined,
                        '${widget.items} ítem${widget.items == 1 ? '' : 's'}',
                      ),
                    if (widget.lineas > 0)
                      _infoChip(
                        Icons.view_list_rounded,
                        '${widget.lineas} línea${widget.lineas == 1 ? '' : 's'}',
                      ),
                    if (widget.fechaEntrega.isNotEmpty)
                      _infoChip(Icons.local_shipping_outlined, 'Entrega ${widget.fechaEntrega}'),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AlpesColors.cafeOscuro.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _moneyStat('Subtotal', widget.subtotal, moneyPrefix)),
                          Expanded(child: _moneyStat('Impuesto', widget.impuesto, moneyPrefix)),
                          Expanded(child: _moneyStat('Descuento', widget.descuento, moneyPrefix)),
                        ],
                      ),
                      if (widget.observaciones.isNotEmpty || widget.direccion.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        if (widget.observaciones.isNotEmpty)
                          _detalleFila(
                            Icons.notes_rounded,
                            'Nota',
                            widget.observaciones.length > 80
                                ? '${widget.observaciones.substring(0, 80)}…'
                                : widget.observaciones,
                          ),
                        if (widget.direccion.isNotEmpty)
                          _detalleFila(
                            Icons.location_on_outlined,
                            'Envío',
                            widget.direccion.length > 80
                                ? '${widget.direccion.substring(0, 80)}…'
                                : widget.direccion,
                            isLast: true,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AlpesColors.pergamino),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: AlpesColors.arenaCalida),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AlpesColors.cafeOscuro,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _moneyStat(String label, double value, String moneyPrefix) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AlpesColors.arenaCalida,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$moneyPrefix ${value.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11.5,
              color: AlpesColors.cafeOscuro,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );

  Widget _detalleFila(IconData icon, String label, String value, {bool isLast = false}) => Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 12, color: AlpesColors.arenaCalida),
            const SizedBox(width: 6),
            SizedBox(
              width: 50,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AlpesColors.arenaCalida,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  color: AlpesColors.cafeOscuro,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      );
}
