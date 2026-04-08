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
  List<Map<String, dynamic>> _estadosOrden = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _filtroEstado = 'Todos';

  static const _estados = ['Todos', 'Pendiente', 'Completada'];

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
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.estadoOrden}')),
      ]);

      final ordenesData = jsonDecode(responses[0].body);
      final estadosData = jsonDecode(responses[1].body);

      if (!mounted) return;

      setState(() {
        _ordenes = ordenesData['ok'] == true
            ? List<Map<String, dynamic>>.from(ordenesData['data'])
            : [];
        _estadosOrden = estadosData['ok'] == true
            ? List<Map<String, dynamic>>.from(estadosData['data'])
            : [];
      });

      _aplicarFiltros();
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _resolverEstadoOrden(dynamic estadoOrdenId) {
    for (final estado in _estadosOrden) {
      if ('${estado['ESTADO_ORDEN_ID']}' == '$estadoOrdenId') {
        return '${estado['CODIGO'] ?? ''}'.trim();
      }
    }
    return '';
  }

  String _normalizarFecha(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '';
    final raw = value.toString().trim();
    if (raw.contains('T')) return raw.split('T').first;
    return raw;
  }

  String _capitalizar(String value) {
    if (value.trim().isEmpty) return value;
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  void _aplicarFiltros() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtradas = _ordenes.where((o) {
        final num =
            (o['NUM_ORDEN'] ?? o['num_orden'] ?? '').toString().toLowerCase();
        final estadoReal = _resolverEstadoOrden(
          o['ESTADO_ORDEN_ID'] ?? o['estado_orden_id'],
        );
        final estadoTexto = estadoReal.isEmpty ? '' : _capitalizar(estadoReal);

        final matchQ = q.isEmpty || num.contains(q);
        final matchE = _filtroEstado == 'Todos' || estadoTexto == _filtroEstado;

        return matchQ && matchE;
      }).toList();
    });
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
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
      case 'completada':
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('ÓRDENES DE VENTA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin'),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _aplicarFiltros(),
                  decoration: InputDecoration(
                    hintText: 'Buscar por número de orden…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _aplicarFiltros();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: AlpesColors.cremaFondo,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _estados.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final e = _estados[i];
                      final active = _filtroEstado == e;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _filtroEstado = e);
                          _aplicarFiltros();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AlpesColors.cafeOscuro
                                : AlpesColors.cremaFondo,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? AlpesColors.cafeOscuro
                                  : AlpesColors.arenaCalida,
                            ),
                          ),
                          child: Text(
                            e,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : AlpesColors.grafito,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AlpesColors.cafeOscuro,
                    ),
                  )
                : _filtradas.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AlpesColors.cafeOscuro,
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtradas.length,
                          itemBuilder: (_, i) => _buildOrdenCard(_filtradas[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdenCard(Map<String, dynamic> o) {
    final id = o['ORDEN_VENTA_ID'] ?? o['orden_venta_id'];
    final num = o['NUM_ORDEN'] ?? o['num_orden'] ?? '#$id';
    final total = double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0;
    final fecha = _normalizarFecha(o['FECHA_ORDEN'] ?? o['fecha_orden']);
    final estadoReal = _resolverEstadoOrden(
      o['ESTADO_ORDEN_ID'] ?? o['estado_orden_id'],
    );
    final estado = estadoReal.isEmpty ? 'Sin estado' : _capitalizar(estadoReal);

    return GestureDetector(
      onTap: () async {
        await context.push('/admin/ordenes/$id');
        if (mounted) {
          await _cargar();
        }
      },
      child: Container(
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
                  color: AlpesColors.cafeOscuro.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AlpesColors.cafeOscuro,
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
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: AlpesColors.arenaCalida,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fecha,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AlpesColors.nogalMedio,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Q ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AlpesColors.cafeOscuro,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _bgEstado(estado),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      estado,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _colorEstado(estado),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AlpesColors.arenaCalida,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AlpesColors.arenaCalida.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sin órdenes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AlpesColors.nogalMedio,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'No se encontraron resultados',
              style: TextStyle(fontSize: 12, color: AlpesColors.arenaCalida),
            ),
          ],
        ),
      );
}