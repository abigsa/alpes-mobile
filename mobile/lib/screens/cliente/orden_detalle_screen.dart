import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../config/theme.dart';
import '../../config/api_config.dart';

class OrdenDetalleScreen extends StatefulWidget {
  final int ordenId;
  const OrdenDetalleScreen({super.key, required this.ordenId});
  @override
  State<OrdenDetalleScreen> createState() => _OrdenDetalleScreenState();
}

class _OrdenDetalleScreenState extends State<OrdenDetalleScreen> {
  Map<String, dynamic>? _orden;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final ordenRes = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}/${widget.ordenId}'));
      final ordenData = jsonDecode(ordenRes.body);
      if (ordenData['ok'] == true) _orden = ordenData['data'];

      final detRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVentaDet}/buscar?criterio=orden_venta_id&valor=${widget.ordenId}'));
      final detData = jsonDecode(detRes.body);
      if (detData['ok'] == true) _items = List<Map<String, dynamic>>.from(detData['data']);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(title: const Text('DETALLE DE ORDEN')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : _orden == null
              ? const Center(child: Text('Orden no encontrada'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Orden #${_orden!['NUM_ORDEN'] ?? _orden!['num_orden']}',
                                  style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              _row('Estado', '${_orden!['ESTADO'] ?? _orden!['estado']}'),
                              _row('Total', 'Q${_orden!['TOTAL'] ?? _orden!['total']}'),
                              _row('Dirección', '${_orden!['DIRECCION_ENVIO_SNAPSHOT'] ?? _orden!['direccion_envio_snapshot'] ?? 'N/A'}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Productos', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ..._items.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('Producto #${item['PRODUCTO_ID'] ?? item['producto_id']}'),
                          subtitle: Text('Cantidad: ${item['CANTIDAD'] ?? item['cantidad']}'),
                          trailing: Text('Q${item['SUBTOTAL_LINEA'] ?? item['subtotal_linea'] ?? 0}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
                        ),
                      )),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.local_shipping_outlined),
                          label: const Text('Ver seguimiento'),
                          onPressed: () => context.go('/seguimiento/${widget.ordenId}'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: AlpesColors.nogalMedio)),
      Expanded(child: Text(value)),
    ]),
  );
}
