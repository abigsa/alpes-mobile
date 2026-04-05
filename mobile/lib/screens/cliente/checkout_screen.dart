import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/carrito_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _direccionCtrl = TextEditingController();
  final _cuponCtrl = TextEditingController();
  int? _metodoPagoId;
  List<Map<String, dynamic>> _metodos = [];
  bool _loading = false;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarMetodos();
  }

  Future<void> _cargarMetodos() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.metodoPago}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) setState(() => _metodos = List<Map<String, dynamic>>.from(data['data']));
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _procesarPago() async {
    if (!_formKey.currentState!.validate()) return;
    if (_metodoPagoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un método de pago'), backgroundColor: AlpesColors.aviso));
      return;
    }
    setState(() => _procesando = true);
    final auth = context.read<AuthProvider>();
    final carrito = context.read<CarritoProvider>();
    try {
      // 1. Crear orden de venta
      final ordenRes = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'num_orden': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
          'cli_id': auth.clienteId,
          'estado_orden_id': 1,
          'fecha_orden': DateTime.now().toIso8601String(),
          'subtotal': carrito.total,
          'descuento': 0,
          'impuesto': carrito.total * 0.12,
          'total': carrito.total * 1.12,
          'moneda': 'GTQ',
          'direccion_envio_snapshot': _direccionCtrl.text,
          'observaciones': '',
          'estado': 'PENDIENTE',
        }),
      );
      final ordenData = jsonDecode(ordenRes.body);
      if (ordenData['ok'] != true) throw Exception('Error al crear orden');
      final ordenId = ordenData['data']['orden_venta_id'];

      // 2. Crear detalles de orden
      for (final item in carrito.items) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVentaDet}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'orden_venta_id': ordenId,
            'producto_id': item.productoId,
            'cantidad': item.cantidad,
            'precio_unitario_snapshot': item.precioUnitario,
            'subtotal_linea': item.subtotal,
            'estado': 'ACTIVO',
          }),
        );
      }

      // 3. Registrar pago
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.pago}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orden_venta_id': ordenId,
          'metodo_pago_id': _metodoPagoId,
          'monto': carrito.total * 1.12,
          'estado_pago': 'PENDIENTE',
          'referencia': 'REF-${DateTime.now().millisecondsSinceEpoch}',
          'pago_at': DateTime.now().toIso8601String(),
          'estado': 'ACTIVO',
        }),
      );

      carrito.limpiar();
      if (mounted) {
        context.go('/orden/$ordenId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AlpesColors.rojoColonial));
      }
    }
    setState(() => _procesando = false);
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(title: const Text('CHECKOUT')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dirección de entrega', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _direccionCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Dirección completa',
                        prefixIcon: Icon(Icons.location_on_outlined, color: AlpesColors.nogalMedio),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Ingresa la dirección' : null,
                    ),
                    const SizedBox(height: 24),
                    Text('Método de pago', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ..._metodos.map((m) {
                      final id = m['METODO_PAGO_ID'] ?? m['metodo_pago_id'];
                      final nombre = m['NOMBRE'] ?? m['nombre'] ?? '';
                      return RadioListTile<int>(
                        value: id,
                        groupValue: _metodoPagoId,
                        onChanged: (v) => setState(() => _metodoPagoId = v),
                        title: Text(nombre),
                        activeColor: AlpesColors.cafeOscuro,
                      );
                    }),
                    const SizedBox(height: 24),
                    Text('Cupón de descuento', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cuponCtrl,
                            decoration: const InputDecoration(labelText: 'Código de cupón'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: () {}, child: const Text('Aplicar')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text('Q${carrito.total.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('IVA (12%):'),
                                Text('Q${(carrito.total * 0.12).toStringAsFixed(2)}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total:', style: Theme.of(context).textTheme.titleLarge),
                                Text('Q${(carrito.total * 1.12).toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AlpesColors.cafeOscuro)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _procesando ? null : _procesarPago,
                        child: _procesando
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('CONFIRMAR PEDIDO'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
