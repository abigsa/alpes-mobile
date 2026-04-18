import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_nav_cliente.dart';

class MisOrdenesScreen extends StatefulWidget {
  const MisOrdenesScreen({super.key});
  @override
  State<MisOrdenesScreen> createState() => _MisOrdenesScreenState();
}

class _MisOrdenesScreenState extends State<MisOrdenesScreen> {
  List<Map<String, dynamic>> _ordenes = [];
  bool _loading = true;
  String _filtro = 'Todos';
  final _filtros = [
    'Todos',
    'Pendiente',
    'En proceso',
    'Entregado',
    'Cancelado'
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    if (auth.clienteId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await http.get(Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.ordenVenta}/buscar?criterio=cli_id&valor=${auth.clienteId}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        setState(
            () => _ordenes = List<Map<String, dynamic>>.from(data['data']));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Color _colorEstado(String e) {
    switch (e.toLowerCase()) {
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

  Color _bgEstado(String e) {
    switch (e.toLowerCase()) {
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

  IconData _iconEstado(String e) {
    switch (e.toLowerCase()) {
      case 'entregado':
        return Icons.check_circle_rounded;
      case 'pendiente':
        return Icons.access_time_rounded;
      case 'en proceso':
        return Icons.local_shipping_rounded;
      case 'cancelado':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    var filtradas = _filtro == 'Todos'
        ? _ordenes
        : _ordenes
            .where((o) =>
                (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase() ==
                _filtro.toLowerCase())
            .toList();

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        backgroundColor: AlpesColors.cafeOscuro,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 16),
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mis Órdenes',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3)),
            Text('${_ordenes.length} pedido${_ordenes.length != 1 ? 's' : ''}',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white, size: 20),
            onPressed: _cargar,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        // Filtros
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _filtros.length,
              itemBuilder: (_, i) {
                final f = _filtros[i];
                final active = _filtro == f;
                return GestureDetector(
                  onTap: () => setState(() => _filtro = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? AlpesColors.cafeOscuro
                          : AlpesColors.cremaFondo,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active
                              ? AlpesColors.cafeOscuro
                              : AlpesColors.arenaCalida),
                    ),
                    child: Text(f,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                active ? Colors.white : AlpesColors.grafito)),
                  ),
                );
              },
            ),
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AlpesColors.cafeOscuro))
              : filtradas.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: AlpesColors.cafeOscuro,
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                        itemCount: filtradas.length,
                        itemBuilder: (_, i) => _buildCard(filtradas[i]),
                      ),
                    ),
        ),
      ]),
      bottomNavigationBar: const BottomNavCliente(currentIndex: 3),
    );
  }

  Widget _buildCard(Map<String, dynamic> o) {
    final id = o['ORDEN_VENTA_ID'] ?? o['orden_venta_id'];
    final num = o['NUM_ORDEN'] ?? o['num_orden'] ?? '#$id';
    final total = double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0;
    final estado = (o['ESTADO'] ?? o['estado'] ?? 'Pendiente').toString();
    final fecha = o['FECHA_ORDEN'] ?? o['fecha_orden'] ?? '';

    return GestureDetector(
      onTap: () => context.go('/orden/$id'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AlpesColors.pergamino),
          boxShadow: [
            BoxShadow(
                color: AlpesColors.cafeOscuro.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _bgEstado(estado),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconEstado(estado),
                    color: _colorEstado(estado), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Orden $num',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AlpesColors.cafeOscuro)),
                    if (fecha.isNotEmpty)
                      Text(fecha.toString().split('T').first,
                          style: const TextStyle(
                              fontSize: 11, color: AlpesColors.nogalMedio)),
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Q ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AlpesColors.cafeOscuro)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: _bgEstado(estado),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(estado,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _colorEstado(estado))),
                ),
              ]),
            ]),
            const SizedBox(height: 12),
            // Mini timeline
            _buildMiniTimeline(estado),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Text('Ver detalles →',
                  style: TextStyle(
                      fontSize: 12,
                      color: AlpesColors.nogalMedio,
                      fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildMiniTimeline(String estado) {
    final pasos = ['Pendiente', 'En proceso', 'Entregado'];
    int currentIdx =
        pasos.indexWhere((p) => p.toLowerCase() == estado.toLowerCase());
    if (currentIdx == -1)
      currentIdx = estado.toLowerCase() == 'cancelado' ? -1 : 0;

    if (estado.toLowerCase() == 'cancelado') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AlpesColors.rojoColonial.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(children: [
          Icon(Icons.cancel_rounded, size: 14, color: AlpesColors.rojoColonial),
          SizedBox(width: 6),
          Text('Orden cancelada',
              style: TextStyle(
                  fontSize: 11,
                  color: AlpesColors.rojoColonial,
                  fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return Row(
        children: List.generate(pasos.length * 2 - 1, (i) {
      if (i.isOdd) {
        final done = (i ~/ 2) < currentIdx;
        return Expanded(
            child: Container(
                height: 2,
                color: done ? AlpesColors.cafeOscuro : AlpesColors.pergamino));
      }
      final idx = i ~/ 2;
      final done = idx <= currentIdx;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: done ? AlpesColors.cafeOscuro : AlpesColors.pergamino,
            shape: BoxShape.circle,
          ),
          child: Icon(done ? Icons.check_rounded : Icons.circle,
              size: 10, color: done ? Colors.white : AlpesColors.arenaCalida),
        ),
        const SizedBox(height: 3),
        Text(pasos[idx],
            style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
                color:
                    done ? AlpesColors.cafeOscuro : AlpesColors.arenaCalida)),
      ]);
    }));
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
                color: AlpesColors.pergamino,
                borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.receipt_long_outlined,
                size: 44, color: AlpesColors.arenaCalida),
          ),
          const SizedBox(height: 16),
          const Text('Sin órdenes',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AlpesColors.cafeOscuro)),
          const SizedBox(height: 6),
          Text(
              _filtro == 'Todos'
                  ? 'Aún no has realizado ningún pedido'
                  : 'No tienes órdenes con estado "$_filtro"',
              style:
                  const TextStyle(fontSize: 13, color: AlpesColors.nogalMedio)),
          const SizedBox(height: 20),
          if (_filtro == 'Todos')
            ElevatedButton.icon(
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Ir al catálogo'),
              onPressed: () => context.go('/catalogo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AlpesColors.cafeOscuro,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ]),
      );
}
