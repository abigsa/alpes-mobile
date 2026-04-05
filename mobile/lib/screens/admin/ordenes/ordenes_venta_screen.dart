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
  bool _loading = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) setState(() => _ordenes = List<Map<String, dynamic>>.from(data['data']));
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('ORDENES DE VENTA'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : RefreshIndicator(
              color: AlpesColors.cafeOscuro,
              onRefresh: _cargar,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _ordenes.length,
                itemBuilder: (_, i) {
                  final o = _ordenes[i];
                  final id = o['ORDEN_VENTA_ID'] ?? o['orden_venta_id'];
                  final num = o['NUM_ORDEN'] ?? o['num_orden'] ?? '#$id';
                  final total = o['TOTAL'] ?? o['total'] ?? 0;
                  final estado = o['ESTADO'] ?? o['estado'] ?? '-';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long, color: AlpesColors.cafeOscuro),
                      title: Text('$num'),
                      subtitle: Text('Q ${double.tryParse('$total')?.toStringAsFixed(2) ?? total}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AlpesColors.nogalMedio.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AlpesColors.nogalMedio),
                        ),
                        child: Text('$estado', style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
                      ),
                      onTap: () => context.push('/admin/ordenes/$id'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
