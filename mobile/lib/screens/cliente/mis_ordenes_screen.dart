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

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final auth = context.read<AuthProvider>();
    if (auth.clienteId == null) return;
    try {
      final res = await http.get(Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.ordenVenta}/buscar?criterio=cli_id&valor=${auth.clienteId}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true)
        setState(
            () => _ordenes = List<Map<String, dynamic>>.from(data['data']));
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(title: const Text('MIS ÓRDENES')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : _ordenes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 80, color: AlpesColors.arenaCalida),
                      const SizedBox(height: 16),
                      Text('No tienes órdenes aún',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: () => context.go('/catalogo'),
                          child: const Text('Empezar a comprar')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ordenes.length,
                  itemBuilder: (_, i) {
                    final o = _ordenes[i];
                    final id = o['ORDEN_VENTA_ID'] ?? o['orden_venta_id'];
                    final num = o['NUM_ORDEN'] ?? o['num_orden'] ?? 'N/A';
                    final total = o['TOTAL'] ?? o['total'] ?? 0;
                    final estado = o['ESTADO'] ?? o['estado'] ?? 'PENDIENTE';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AlpesColors.pergamino,
                          child: Icon(Icons.receipt,
                              color: AlpesColors.cafeOscuro),
                        ),
                        title: Text('Orden #$num',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            'Total: Q${double.tryParse('$total')?.toStringAsFixed(2) ?? total}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: estado == 'ENTREGADO'
                                    ? AlpesColors.exito
                                    : AlpesColors.pergamino,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(estado,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: estado == 'ENTREGADO'
                                        ? Colors.white
                                        : AlpesColors.grafito,
                                  )),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => context.go('/orden/$id'),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: const BottomNavCliente(currentIndex: 3),
    );
  }
}
