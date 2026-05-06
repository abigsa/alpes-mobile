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
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.metodoPago}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true)
        setState(
            () => _metodos = List<Map<String, dynamic>>.from(data['data']));
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _procesarPago() async {
    if (!_formKey.currentState!.validate()) return;
    if (_metodoPagoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona un método de pago'),
          backgroundColor: AlpesColors.aviso));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AlpesColors.rojoColonial));
      }
    }
    setState(() => _procesando = false);
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
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
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 16),
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/carrito'),
        ),
        title: const Text('Checkout',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Dirección ──
                    _sectionLabel(Icons.location_on_rounded, 'Dirección de entrega'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: _cardDeco(),
                      padding: const EdgeInsets.all(14),
                      child: TextFormField(
                        controller: _direccionCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Dirección completa',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          prefixIcon: Icon(Icons.location_on_outlined,
                              color: AlpesColors.nogalMedio),
                          filled: false,
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Ingresa la dirección'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Método de pago ──
                    _sectionLabel(Icons.payment_rounded, 'Método de pago'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: _cardDeco(),
                      child: Column(children: _metodos.map((m) {
                        final id     = m['METODO_PAGO_ID'] ?? m['metodo_pago_id'];
                        final nombre = m['NOMBRE'] ?? m['nombre'] ?? '';
                        final sel    = _metodoPagoId == id;
                        return ListTile(
                          leading: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: sel ? AlpesColors.cafeOscuro : AlpesColors.cremaFondo,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.credit_card_rounded, size: 17,
                              color: sel ? Colors.white : AlpesColors.nogalMedio),
                          ),
                          title: Text(nombre, style: TextStyle(fontSize: 14,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color: AlpesColors.cafeOscuro)),
                          trailing: Radio<int>(
                            value: id,
                            groupValue: _metodoPagoId,
                            onChanged: (v) => setState(() => _metodoPagoId = v),
                            activeColor: AlpesColors.cafeOscuro,
                          ),
                          onTap: () => setState(() => _metodoPagoId = id),
                        );
                      }).toList()),
                    ),
                    const SizedBox(height: 20),

                    // ── Cupón ──
                    _sectionLabel(Icons.discount_rounded, 'Cupón de descuento'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: _cardDeco(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Row(children: [
                        Expanded(child: TextFormField(
                          controller: _cuponCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Código de cupón',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            prefixIcon: Icon(Icons.local_offer_rounded,
                                color: AlpesColors.nogalMedio, size: 18),
                          ),
                        )),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Aplicar',
                              style: TextStyle(fontWeight: FontWeight.w700,
                                  color: AlpesColors.cafeOscuro)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ── Resumen ──
                    _sectionLabel(Icons.receipt_rounded, 'Resumen del pedido'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: _cardDeco(),
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _resumenRow('Subtotal',
                            'Q ${carrito.total.toStringAsFixed(2)}', false),
                        const SizedBox(height: 10),
                        _resumenRow('IVA (12%)',
                            'Q ${(carrito.total * 0.12).toStringAsFixed(2)}', false),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: AlpesColors.pergamino),
                        ),
                        _resumenRow('Total',
                            'Q ${(carrito.total * 1.12).toStringAsFixed(2)}', true),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // ── Botón confirmar ──
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _procesando ? null : _procesarPago,
                        icon: _procesando
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(_procesando ? 'Procesando...' : 'Confirmar pedido',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AlpesColors.cafeOscuro,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  // ── Helpers de diseño ──
  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AlpesColors.pergamino),
    boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
        blurRadius: 10, offset: const Offset(0, 3))],
  );

  Widget _sectionLabel(IconData icon, String label) => Row(children: [
    Container(width: 32, height: 32,
        decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 15, color: AlpesColors.cafeOscuro)),
    const SizedBox(width: 10),
    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
        color: AlpesColors.cafeOscuro)),
  ]);

  Widget _resumenRow(String label, String value, bool highlight) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: highlight ? 15 : 13,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
          color: highlight ? AlpesColors.cafeOscuro : AlpesColors.nogalMedio)),
      Text(value, style: TextStyle(fontSize: highlight ? 18 : 13,
          fontWeight: FontWeight.w800,
          color: AlpesColors.cafeOscuro)),
    ],
  );

}
