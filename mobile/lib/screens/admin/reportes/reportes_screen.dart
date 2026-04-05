import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});
  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  List<Map<String, dynamic>> _ordenes    = [];
  bool _loading = true;

  // Métricas calculadas
  double _totalVentas   = 0;
  int    _totalOrdenes  = 0;
  int    _entregadas    = 0;
  int    _pendientes    = 0;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res  = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        _ordenes = List<Map<String, dynamic>>.from(data['data']);
        _calcularMetricas();
      }
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  void _calcularMetricas() {
    _totalOrdenes = _ordenes.length;
    _totalVentas  = _ordenes.fold(0, (sum, o) =>
        sum + (double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0));
    _entregadas   = _ordenes.where((o) =>
        (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase() == 'entregado').length;
    _pendientes   = _ordenes.where((o) {
      final e = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
      return e == 'pendiente' || e == 'en proceso';
    }).length;
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado' : return const Color(0xFF3B6D11);
      case 'pendiente' : return const Color(0xFF854F0B);
      case 'en proceso': return const Color(0xFF185FA5);
      case 'cancelado' : return AlpesColors.rojoColonial;
      default          : return AlpesColors.nogalMedio;
    }
  }

  Color _bgEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado' : return const Color(0xFFEAF3DE);
      case 'pendiente' : return const Color(0xFFFAEEDA);
      case 'en proceso': return const Color(0xFFE6F1FB);
      case 'cancelado' : return const Color(0xFFFCEBEB);
      default          : return AlpesColors.pergamino;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('REPORTES'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : RefreshIndicator(
              color: AlpesColors.cafeOscuro,
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  // ── KPIs ──
                  _sectionLabel('Resumen de ventas'),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.0,
                    children: [
                      _metricCard('Total ventas',
                          'Q ${_totalVentas.toStringAsFixed(2)}',
                          Icons.trending_up_rounded, AlpesColors.cafeOscuro),
                      _metricCard('Total órdenes',
                          '$_totalOrdenes',
                          Icons.receipt_long_rounded, AlpesColors.oroGuatemalteco),
                      _metricCard('Entregadas',
                          '$_entregadas',
                          Icons.check_circle_rounded, const Color(0xFF3B6D11)),
                      _metricCard('Pendientes',
                          '$_pendientes',
                          Icons.pending_rounded, const Color(0xFF854F0B)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Accesos directos ──
                  _sectionLabel('Reportes por módulo'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: _cardDeco(),
                    child: Column(children: [
                      _reportLink(Icons.receipt_long_rounded, 'Órdenes de venta',
                          'Ver todas las transacciones', '/admin/ordenes'),
                      _div(),
                      _reportLink(Icons.warehouse_rounded, 'Inventario',
                          'Estado actual del stock', '/admin/inventario'),
                      _div(),
                      _reportLink(Icons.people_alt_rounded, 'Clientes',
                          'Base de datos de clientes', '/admin/clientes'),
                      _div(),
                      _reportLink(Icons.payments_rounded, 'Nómina',
                          'Pagos y salarios del personal', '/admin/nomina'),
                      _div(),
                      _reportLink(Icons.factory_rounded, 'Producción',
                          'Órdenes y planes de producción', '/admin/produccion'),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Últimas órdenes ──
                  _sectionLabel('Últimas órdenes'),
                  const SizedBox(height: 10),
                  if (_ordenes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _cardDeco(),
                      child: const Center(
                        child: Text('Sin datos disponibles',
                            style: TextStyle(color: AlpesColors.nogalMedio)),
                      ),
                    )
                  else
                    Container(
                      decoration: _cardDeco(),
                      child: Column(
                        children: List.generate(
                          (_ordenes.length > 10 ? 10 : _ordenes.length) * 2 - 1,
                          (i) {
                            if (i.isOdd) return _div();
                            final o      = _ordenes[i ~/ 2];
                            final num    = o['NUM_ORDEN'] ?? o['num_orden'] ?? '#${o['ORDEN_VENTA_ID'] ?? ''}';
                            final total  = double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0;
                            final estado = (o['ESTADO'] ?? o['estado'] ?? '-').toString();
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                    color: AlpesColors.cafeOscuro.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(9)),
                                child: const Icon(Icons.receipt_long_rounded,
                                    color: AlpesColors.cafeOscuro, size: 18),
                              ),
                              title: Text('$num',
                                  style: const TextStyle(fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text('Q ${total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12,
                                      color: AlpesColors.nogalMedio)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: _bgEstado(estado),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(estado,
                                    style: TextStyle(fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _colorEstado(estado))),
                              ),
                              onTap: () {
                                final id = o['ORDEN_VENTA_ID'] ?? o['orden_venta_id'];
                                if (id != null) context.push('/admin/ordenes/$id');
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String label) => Row(children: [
    Container(width: 3, height: 15,
        decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
        color: AlpesColors.cafeOscuro)),
  ]);

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AlpesColors.pergamino),
    boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
        blurRadius: 8, offset: const Offset(0, 2))],
  );

  Widget _div() => const Divider(height: 1, indent: 16, endIndent: 16,
      color: AlpesColors.pergamino);

  Widget _metricCard(String label, String value, IconData icon, Color accent) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AlpesColors.pergamino),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.07),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 34, height: 34,
              decoration: BoxDecoration(color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 16, color: accent)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: AlpesColors.cafeOscuro),
                  overflow: TextOverflow.ellipsis),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: AlpesColors.nogalMedio),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      );

  Widget _reportLink(IconData icon, String title, String subtitle, String route) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.07),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: AlpesColors.cafeOscuro)),
        title: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AlpesColors.arenaCalida),
        onTap: () => context.go(route),
      );
}
