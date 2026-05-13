import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/carrito_provider.dart';
import '../../providers/cupon_provider.dart';

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
  String? _metodoPagoNombre;
  List<Map<String, dynamic>> _metodos = [];

  List<Map<String, dynamic>> _tarjetas = [];
  int? _tarjetaSeleccionadaId;
  bool _mostrarFormTarjeta = false;

  final _tarjetaFormKey = GlobalKey<FormState>();
  final _titularCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _mesCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();
  String _marcaSeleccionada = 'VISA';

  bool _loading = false;
  bool _procesando = false;
  bool _guardandoTarjeta = false;

  static const List<String> _marcas = ['VISA', 'MASTERCARD', 'AMEX', 'OTRO'];

  bool get _esTarjeta =>
      _metodoPagoNombre?.toLowerCase().contains('tarjeta') == true ||
      _metodoPagoNombre?.toLowerCase().contains('credit') == true ||
      _metodoPagoNombre?.toLowerCase().contains('debito') == true ||
      _metodoPagoNombre?.toLowerCase().contains('débito') == true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    await Future.wait([_cargarMetodos(), _cargarTarjetas()]);
    setState(() => _loading = false);
  }

  Future<void> _cargarMetodos() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.metodoPago}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true)
        setState(() => _metodos = List<Map<String, dynamic>>.from(data['data']));
    } catch (_) {}
  }

  Future<void> _cargarTarjetas() async {
    final auth = context.read<AuthProvider>();
    if (auth.clienteId == null) return;
    try {
      final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/tarjetas-cliente/cliente/${auth.clienteId}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true)
        setState(() => _tarjetas = List<Map<String, dynamic>>.from(data['data']));
    } catch (_) {}
  }

  Future<void> _validarCupon(BuildContext context) async {
    final codigo = _cuponCtrl.text.trim();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ingresa un código de cupón'),
          backgroundColor: AlpesColors.aviso));
      return;
    }

    final carrito = context.read<CarritoProvider>();
    final cupon = context.read<CuponProvider>();
    
    final resultado = await cupon.validarCupon(codigo, carrito.total);
    if (!resultado && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(cupon.mensajeCupon ?? 'Error al validar cupón'),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _guardarNuevaTarjeta() async {
    if (!_tarjetaFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() => _guardandoTarjeta = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tarjetas-cliente'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cli_id': auth.clienteId,
          'titular': _titularCtrl.text.trim(),
          'ultimos_4': _numeroCtrl.text.replaceAll(' ', '').trim().length >= 4
              ? _numeroCtrl.text.replaceAll(' ', '').trim().substring(_numeroCtrl.text.replaceAll(' ', '').trim().length - 4)
              : _numeroCtrl.text.replaceAll(' ', '').trim(),
          'marca': _marcaSeleccionada,
          'mes_vencimiento': int.tryParse(_mesCtrl.text.trim()),
          'anio_vencimiento': int.tryParse(_anioCtrl.text.trim()),
          'alias_tarjeta': _aliasCtrl.text.trim().isEmpty ? null : _aliasCtrl.text.trim(),
          'predeterminada': 0,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true || res.statusCode == 201) {
        _titularCtrl.clear(); _numeroCtrl.clear();
        _mesCtrl.clear(); _anioCtrl.clear(); _aliasCtrl.clear();
        setState(() { _mostrarFormTarjeta = false; _marcaSeleccionada = 'VISA'; });
        await _cargarTarjetas();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Tarjeta guardada exitosamente'),
              backgroundColor: Colors.green));
      } else {
        throw Exception(data['mensaje'] ?? 'Error al guardar tarjeta');
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AlpesColors.rojoColonial));
    }
    setState(() => _guardandoTarjeta = false);
  }

  Future<void> _procesarPago() async {
    if (!_formKey.currentState!.validate()) return;
    if (_metodoPagoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona un método de pago'),
          backgroundColor: AlpesColors.aviso));
      return;
    }
    if (_esTarjeta && _tarjetaSeleccionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona o registra una tarjeta'),
          backgroundColor: AlpesColors.aviso));
      return;
    }
    final auth = context.read<AuthProvider>();
    final carrito = context.read<CarritoProvider>();
    final cupon = context.read<CuponProvider>();
    
    if (auth.clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sesión inválida. Vuelve a iniciar sesión.'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _procesando = true);
    try {
      // Calcular totales con descuento
      final subtotal = carrito.total;
      final descuento = cupon.descuentoAplicado;
      final subtotalConDescuento = subtotal - descuento;
      final impuesto = subtotalConDescuento * 0.12;
      final totalFinal = subtotalConDescuento + impuesto;

      final ordenRes = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'num_orden': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
          'cli_id': auth.clienteId,
          'estado_orden_id': 30,
          'fecha_orden': DateTime.now().toIso8601String(),
          'subtotal': subtotal,
          'descuento': descuento, // Ahora incluye el descuento del cupón
          'impuesto': impuesto,
          'total': totalFinal,
          'moneda': 'GTQ',
          'direccion_envio_snapshot': _direccionCtrl.text,
          'observaciones': cupon.cuponAplicado != null ? 'Cupón aplicado: ${cupon.cuponAplicado!['codigo']}' : '',
          'estado': 'ACTIVO',
        }),
      );
      final ordenData = jsonDecode(ordenRes.body);
      if (ordenData['ok'] != true) throw Exception('Error al crear orden');
      final ordenId = ordenData['data']['orden_venta_id'];

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

      await carrito.limpiarEnBD();
      if (mounted) context.go('/orden/$ordenId');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AlpesColors.rojoColonial));
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
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
          ),
          onPressed: () => context.canPop() ? context.pop() : context.go('/carrito'),
        ),
        title: const Text('Checkout',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: 0.3)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          prefixIcon: Icon(Icons.location_on_outlined, color: AlpesColors.nogalMedio),
                          filled: false,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Ingresa la dirección' : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _sectionLabel(Icons.payment_rounded, 'Método de pago'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: _cardDeco(),
                      child: Column(children: _metodos.map((m) {
                        final id = m['METODO_PAGO_ID'] ?? m['metodo_pago_id'];
                        final nombre = m['NOMBRE'] ?? m['nombre'] ?? '';
                        final sel = _metodoPagoId == id;
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
                            onChanged: (v) => setState(() {
                              _metodoPagoId = v;
                              _metodoPagoNombre = nombre;
                              _tarjetaSeleccionadaId = null;
                              _mostrarFormTarjeta = false;
                            }),
                            activeColor: AlpesColors.cafeOscuro,
                          ),
                          onTap: () => setState(() {
                            _metodoPagoId = id;
                            _metodoPagoNombre = nombre;
                            _tarjetaSeleccionadaId = null;
                            _mostrarFormTarjeta = false;
                          }),
                        );
                      }).toList()),
                    ),

                    if (_esTarjeta) ...[
                      const SizedBox(height: 20),
                      _sectionLabel(Icons.credit_card_rounded, 'Selecciona una tarjeta'),
                      const SizedBox(height: 10),
                      Container(
                        decoration: _cardDeco(),
                        child: Column(children: [
                          if (_tarjetas.isEmpty && !_mostrarFormTarjeta)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('No tienes tarjetas registradas.',
                                  style: TextStyle(color: AlpesColors.nogalMedio, fontSize: 13)),
                            )
                          else ..._tarjetas.map((t) {
                            final id = t['TARJETA_CLIENTE_ID'] ?? t['tarjeta_cliente_id'];
                            final marca = t['MARCA'] ?? t['marca'] ?? '';
                            final ultimos4 = t['ULTIMOS_4'] ?? t['ultimos_4'] ?? '****';
                            final alias = t['ALIAS_TARJETA'] ?? t['alias_tarjeta'];
                            final titular = t['TITULAR'] ?? t['titular'] ?? '';
                            final sel = _tarjetaSeleccionadaId == id;
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
                              title: Text(
                                alias != null && alias.toString().isNotEmpty
                                    ? alias.toString()
                                    : '$marca •••• $ultimos4',
                                style: TextStyle(fontSize: 14,
                                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                    color: AlpesColors.cafeOscuro),
                              ),
                              subtitle: Text(titular,
                                  style: const TextStyle(fontSize: 12, color: AlpesColors.nogalMedio)),
                              trailing: Radio<int>(
                                value: id,
                                groupValue: _tarjetaSeleccionadaId,
                                onChanged: (v) => setState(() {
                                  _tarjetaSeleccionadaId = v;
                                  _mostrarFormTarjeta = false;
                                }),
                                activeColor: AlpesColors.cafeOscuro,
                              ),
                              onTap: () => setState(() {
                                _tarjetaSeleccionadaId = id;
                                _mostrarFormTarjeta = false;
                              }),
                            );
                          }),
                          if (_tarjetas.isNotEmpty)
                            const Divider(height: 1, color: AlpesColors.pergamino),
                          ListTile(
                            leading: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: _mostrarFormTarjeta ? AlpesColors.cafeOscuro : AlpesColors.cremaFondo,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _mostrarFormTarjeta ? Icons.close_rounded : Icons.add_rounded,
                                size: 17,
                                color: _mostrarFormTarjeta ? Colors.white : AlpesColors.nogalMedio,
                              ),
                            ),
                            title: Text(
                              _mostrarFormTarjeta ? 'Cancelar' : 'Agregar nueva tarjeta',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: AlpesColors.cafeOscuro),
                            ),
                            onTap: () => setState(() {
                              _mostrarFormTarjeta = !_mostrarFormTarjeta;
                              if (_mostrarFormTarjeta) _tarjetaSeleccionadaId = null;
                            }),
                          ),
                          if (_mostrarFormTarjeta)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Form(
                                key: _tarjetaFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(color: AlpesColors.pergamino),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _marcaSeleccionada,
                                      decoration: _inputDeco('Marca'),
                                      items: _marcas.map((m) => DropdownMenuItem(
                                          value: m, child: Text(m))).toList(),
                                      onChanged: (v) => setState(() => _marcaSeleccionada = v!),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _titularCtrl,
                                      decoration: _inputDeco('Nombre del titular'),
                                      textCapitalization: TextCapitalization.words,
                                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _numeroCtrl,
                                      decoration: _inputDeco('Número de tarjeta').copyWith(counterText: ''),
                                      keyboardType: TextInputType.number,
                                      maxLength: 19,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(16),
                                        _CardNumberFormatter(),
                                      ],
                                      validator: (v) {
                                        final digits = (v ?? '').replaceAll(' ', '');
                                        if (digits.isEmpty) return 'Requerido';
                                        if (digits.length != 16) return 'Ingresa los 16 dígitos';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Row(children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _mesCtrl,
                                          decoration: _inputDeco('Mes (MM)'),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(2),
                                          ],
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return 'Requerido';
                                            final n = int.tryParse(v);
                                            if (n == null || n < 1 || n > 12) return 'Inválido';
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _anioCtrl,
                                          decoration: _inputDeco('Año (YYYY)'),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(4),
                                          ],
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return 'Requerido';
                                            final n = int.tryParse(v);
                                            if (n == null || n < DateTime.now().year) return 'Inválido';
                                            return null;
                                          },
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _aliasCtrl,
                                      decoration: _inputDeco('Alias (opcional, ej: Mi Visa)'),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _guardandoTarjeta ? null : _guardarNuevaTarjeta,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AlpesColors.cafeOscuro,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        child: _guardandoTarjeta
                                            ? const SizedBox(width: 18, height: 18,
                                                child: CircularProgressIndicator(
                                                    color: Colors.white, strokeWidth: 2))
                                            : const Text('Guardar tarjeta',
                                                style: TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 20),
                    _sectionLabel(Icons.discount_rounded, 'Cupón de descuento'),
                    const SizedBox(height: 10),
                    Consumer<CuponProvider>(
                      builder: (context, cupon, _) {
                        final tieneCupon = cupon.cuponAplicado != null;
                        return Column(
                          children: [
                            if (!tieneCupon)
                              Container(
                                decoration: _cardDeco(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                child: Row(children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cuponCtrl,
                                      enabled: !cupon.cargando,
                                      decoration: const InputDecoration(
                                        hintText: 'Código de cupón',
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        prefixIcon: Icon(Icons.local_offer_rounded,
                                            color: AlpesColors.nogalMedio, size: 18),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: cupon.cargando
                                        ? null
                                        : () => _validarCupon(context),
                                    child: cupon.cargando
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                AlpesColors.cafeOscuro,
                                              ),
                                            ),
                                          )
                                        : const Text('Aplicar',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AlpesColors.cafeOscuro)),
                                  ),
                                ]),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cupón aplicado: ${cupon.cuponAplicado!['codigo']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            'Descuento: Q ${cupon.descuentoAplicado.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        context
                                            .read<CuponProvider>()
                                            .limpiarCupon();
                                        _cuponCtrl.clear();
                                      },
                                      icon: const Icon(Icons.close,
                                          color: Colors.grey),
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                              ),
                            if (cupon.mensajeCupon != null &&
                                cupon.cuponAplicado == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  cupon.mensajeCupon!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    _sectionLabel(Icons.receipt_rounded, 'Resumen del pedido'),
                    const SizedBox(height: 10),
                    Consumer<CuponProvider>(
                      builder: (context, cupon, _) {
                        final subtotal = carrito.total;
                        final descuento = cupon.descuentoAplicado;
                        final subtotalConDescuento = subtotal - descuento;
                        final impuesto = subtotalConDescuento * 0.12;
                        final total = subtotalConDescuento + impuesto;

                        return Container(
                          decoration: _cardDeco(),
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            _resumenRow('Subtotal',
                                'Q ${subtotal.toStringAsFixed(2)}', false),
                            if (descuento > 0) ...[
                              const SizedBox(height: 10),
                              _resumenRow('Descuento cupón',
                                  '- Q ${descuento.toStringAsFixed(2)}', false),
                            ],
                            const SizedBox(height: 10),
                            _resumenRow('IVA (12%)', 'Q ${impuesto.toStringAsFixed(2)}',
                                false),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: AlpesColors.pergamino),
                            ),
                            _resumenRow('Total',
                                'Q ${total.toStringAsFixed(2)}', true),
                          ]),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _procesando ? null : _procesarPago,
                        icon: _procesando
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(_procesando ? 'Procesando...' : 'Confirmar pedido',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AlpesColors.cafeOscuro,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AlpesColors.nogalMedio, fontSize: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AlpesColors.pergamino)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AlpesColors.pergamino)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AlpesColors.cafeOscuro)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

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
          fontWeight: FontWeight.w800, color: AlpesColors.cafeOscuro)),
    ],
  );

  @override
  void dispose() {
    _direccionCtrl.dispose(); _cuponCtrl.dispose();
    _titularCtrl.dispose(); _numeroCtrl.dispose();
    _mesCtrl.dispose(); _anioCtrl.dispose(); _aliasCtrl.dispose();
    super.dispose();
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

