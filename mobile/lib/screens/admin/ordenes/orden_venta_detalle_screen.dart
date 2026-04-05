
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

class _OrdenVentaDetalleScreenState extends State<OrdenVentaDetalleScreen> {
  Map<String, dynamic>? _orden;
  List<Map<String, dynamic>> _detalles = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}/${widget.ordenId}'));
      final detRes = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVentaDet}/buscar?criterio=orden_venta_id&valor=${widget.ordenId}'));
      final data = jsonDecode(res.body);
      final detData = jsonDecode(detRes.body);
      setState(() {
        if (data['ok'] == true) _orden = data['data'];
        if (detData['ok'] == true) _detalles = List<Map<String, dynamic>>.from(detData['data']);
      });
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: Text('ORDEN #${widget.ordenId}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_orden != null) Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Información', style: Theme.of(context).textTheme.titleLarge),
                        const Divider(),
                        Text('Orden: ${_orden!['NUM_ORDEN'] ?? _orden!['num_orden'] ?? '-'}'),
                        Text('Estado: ${_orden!['ESTADO'] ?? _orden!['estado'] ?? '-'}'),
                        Text('Total: Q ${_orden!['TOTAL'] ?? _orden!['total'] ?? 0}'),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Productos', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ..._detalles.map((d) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.chair_alt, color: AlpesColors.nogalMedio),
                      title: Text('Producto #${d['PRODUCTO_ID'] ?? d['producto_id']}'),
                      subtitle: Text('Cantidad: ${d['CANTIDAD'] ?? d['cantidad']}'),
                      trailing: Text('Q ${d['SUBTOTAL_LINEA'] ?? d['subtotal_linea'] ?? 0}'),
                    ),
                  )),
                ],
              ),
            ),
    );
  }
}
