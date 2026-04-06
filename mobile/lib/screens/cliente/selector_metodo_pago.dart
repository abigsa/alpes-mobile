import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';

class SelectorMetodoPago extends StatefulWidget {
  final Function(Map<String, dynamic> seleccion) onSeleccionado;
  const SelectorMetodoPago({super.key, required this.onSeleccionado});

  @override
  State<SelectorMetodoPago> createState() => _SelectorMetodoPagoState();
}

class _SelectorMetodoPagoState extends State<SelectorMetodoPago> {
  List<Map<String, dynamic>> _tarjetas = [];
  List<Map<String, dynamic>> _metodos = [];
  bool _loading = true;
  int _tabSeleccionada = 0; // 0 = tarjetas, 1 = otros métodos
  dynamic _tarjetaSeleccionadaId;
  dynamic _metodoPagoId;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final auth = context.read<AuthProvider>();
    try {
      final futures = await Future.wait([
        if (auth.clienteId != null)
          http.get(Uri.parse('${ApiConfig.baseUrl}/tarjetacliente/cliente/${auth.clienteId}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.metodoPago}')),
      ]);

      if (auth.clienteId != null) {
        final t = jsonDecode(futures[0].body);
        if (t['ok'] == true) _tarjetas = List<Map<String, dynamic>>.from(t['data']);
        final m = jsonDecode(futures[1].body);
        if (m['ok'] == true) _metodos = List<Map<String, dynamic>>.from(m['data']);
      } else {
        final m = jsonDecode(futures[0].body);
        if (m['ok'] == true) _metodos = List<Map<String, dynamic>>.from(m['data']);
      }

      // Preseleccionar tarjeta predeterminada
      final pred = _tarjetas.where((t) => (t['PREDETERMINADA'] ?? t['predeterminada'] ?? 0) == 1);
      if (pred.isNotEmpty) {
        _tarjetaSeleccionadaId = pred.first['TARJETA_CLIENTE_ID'] ?? pred.first['tarjeta_cliente_id'];
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _confirmar() {
    if (_tabSeleccionada == 0 && _tarjetaSeleccionadaId != null) {
      final tarjeta = _tarjetas.firstWhere(
        (t) => (t['TARJETA_CLIENTE_ID'] ?? t['tarjeta_cliente_id']) == _tarjetaSeleccionadaId,
      );
      widget.onSeleccionado({
        'tipo': 'tarjeta',
        'tarjeta': tarjeta,
        'label': '**** ${tarjeta['ULTIMOS_4'] ?? tarjeta['ultimos_4']}',
      });
    } else if (_tabSeleccionada == 1 && _metodoPagoId != null) {
      final metodo = _metodos.firstWhere(
        (m) => (m['METODO_PAGO_ID'] ?? m['metodo_pago_id']) == _metodoPagoId,
      );
      widget.onSeleccionado({
        'tipo': 'otro',
        'metodo': metodo,
        'label': metodo['NOMBRE'] ?? metodo['nombre'],
        'metodo_pago_id': _metodoPagoId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AlpesColors.cremaFondo,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AlpesColors.arenaCalida, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Método de pago', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          // Tabs
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabSeleccionada = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _tabSeleccionada == 0 ? AlpesColors.cafeOscuro : AlpesColors.pergamino,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Mis tarjetas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _tabSeleccionada == 0 ? Colors.white : AlpesColors.grafito,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabSeleccionada = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _tabSeleccionada == 1 ? AlpesColors.cafeOscuro : AlpesColors.pergamino,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Otros métodos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _tabSeleccionada == 1 ? Colors.white : AlpesColors.grafito,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _loading
              ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
              : _tabSeleccionada == 0
                  ? _buildTarjetas()
                  : _buildMetodos(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_tabSeleccionada == 0 && _tarjetaSeleccionadaId != null) ||
                      (_tabSeleccionada == 1 && _metodoPagoId != null)
                  ? () { _confirmar(); Navigator.pop(context); }
                  : null,
              child: const Text('CONFIRMAR'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetas() {
    if (_tarjetas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.credit_card_off, size: 48, color: AlpesColors.arenaCalida),
            SizedBox(height: 8),
            Text('No tienes tarjetas guardadas', style: TextStyle(color: AlpesColors.nogalMedio)),
          ],
        ),
      );
    }
    return Column(
      children: _tarjetas.map((t) {
        final id = t['TARJETA_CLIENTE_ID'] ?? t['tarjeta_cliente_id'];
        final ultimos4 = t['ULTIMOS_4'] ?? t['ultimos_4'] ?? '****';
        final marca = t['MARCA'] ?? t['marca'] ?? '';
        final titular = t['TITULAR'] ?? t['titular'] ?? '';
        final seleccionada = _tarjetaSeleccionadaId == id;
        return GestureDetector(
          onTap: () => setState(() => _tarjetaSeleccionadaId = id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: seleccionada ? AlpesColors.cafeOscuro : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: seleccionada ? AlpesColors.cafeOscuro : AlpesColors.arenaCalida,
                width: seleccionada ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.credit_card,
                    color: seleccionada ? AlpesColors.oroGuatemalteco : AlpesColors.nogalMedio),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$marca **** $ultimos4',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: seleccionada ? Colors.white : AlpesColors.cafeOscuro,
                          )),
                      Text(titular,
                          style: TextStyle(
                            fontSize: 12,
                            color: seleccionada ? AlpesColors.arenaCalida : AlpesColors.nogalMedio,
                          )),
                    ],
                  ),
                ),
                if (seleccionada)
                  const Icon(Icons.check_circle, color: AlpesColors.oroGuatemalteco),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetodos() {
    if (_metodos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Sin métodos disponibles', style: TextStyle(color: AlpesColors.nogalMedio)),
      );
    }
    return Column(
      children: _metodos.map((m) {
        final id = m['METODO_PAGO_ID'] ?? m['metodo_pago_id'];
        final nombre = m['NOMBRE'] ?? m['nombre'] ?? '';
        final seleccionado = _metodoPagoId == id;
        return GestureDetector(
          onTap: () => setState(() => _metodoPagoId = id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: seleccionado ? AlpesColors.cafeOscuro : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: seleccionado ? AlpesColors.cafeOscuro : AlpesColors.arenaCalida,
                width: seleccionado ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.payment,
                    color: seleccionado ? AlpesColors.oroGuatemalteco : AlpesColors.nogalMedio),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: seleccionado ? Colors.white : AlpesColors.cafeOscuro,
                      )),
                ),
                if (seleccionado)
                  const Icon(Icons.check_circle, color: AlpesColors.oroGuatemalteco),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
