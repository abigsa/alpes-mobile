import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';

class MisTarjetasScreen extends StatefulWidget {
  const MisTarjetasScreen({super.key});
  @override
  State<MisTarjetasScreen> createState() => _MisTarjetasScreenState();
}

class _MisTarjetasScreenState extends State<MisTarjetasScreen> {
  List<Map<String, dynamic>> _tarjetas = [];
  bool _loading = true;

  // URL correcta según app.js
  static const String _endpoint = '/tarjetas-cliente';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final auth = context.read<AuthProvider>();
    if (auth.clienteId == null) return;
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/cliente/${auth.clienteId}'),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        setState(() => _tarjetas = List<Map<String, dynamic>>.from(data['data']));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _marcarPredeterminada(dynamic tarjetaId) async {
    final auth = context.read<AuthProvider>();
    try {
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$tarjetaId/predeterminada'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cli_id': auth.clienteId}),
      );
      _cargar();
    } catch (_) {}
  }

  Future<void> _eliminar(dynamic tarjetaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: const Text('¿Deseas eliminar esta tarjeta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AlpesColors.rojoColonial)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await http.delete(Uri.parse('${ApiConfig.baseUrl}$_endpoint/$tarjetaId'));
      _cargar();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(title: const Text('MIS TARJETAS')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AlpesColors.cafeOscuro,
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : _tarjetas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.credit_card_off, size: 80, color: AlpesColors.arenaCalida),
                      const SizedBox(height: 16),
                      Text('No tienes tarjetas registradas',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Agrega una tarjeta para facilitar tus pagos',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('AGREGAR TARJETA'),
                        onPressed: () => _mostrarFormulario(),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tarjetas.length,
                    itemBuilder: (_, i) {
                      final t = _tarjetas[i];
                      final id = t['TARJETA_CLIENTE_ID'] ?? t['tarjeta_cliente_id'];
                      final titular = t['TITULAR'] ?? t['titular'] ?? '';
                      final ultimos4 = t['ULTIMOS_4'] ?? t['ultimos_4'] ?? '****';
                      final marca = t['MARCA'] ?? t['marca'] ?? '';
                      final alias = t['ALIAS_TARJETA'] ?? t['alias_tarjeta'] ?? '';
                      final mes = t['MES_VENCIMIENTO'] ?? t['mes_vencimiento'] ?? '';
                      final anio = t['ANIO_VENCIMIENTO'] ?? t['anio_vencimiento'] ?? '';
                      final esPredeterminada = (t['PREDETERMINADA'] ?? t['predeterminada'] ?? 0) == 1;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: esPredeterminada
                                  ? [AlpesColors.cafeOscuro, AlpesColors.nogalMedio]
                                  : [AlpesColors.pergamino, Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header marca + badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.credit_card,
                                          color: esPredeterminada
                                              ? AlpesColors.oroGuatemalteco
                                              : AlpesColors.cafeOscuro,
                                          size: 28),
                                      const SizedBox(width: 8),
                                      Text(marca.toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: esPredeterminada ? Colors.white : AlpesColors.cafeOscuro,
                                          )),
                                    ],
                                  ),
                                  if (esPredeterminada)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AlpesColors.oroGuatemalteco,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text('Predeterminada',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AlpesColors.cafeOscuro,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Número enmascarado
                              Text(
                                '**** **** **** $ultimos4',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 3,
                                  fontFamily: 'monospace',
                                  color: esPredeterminada ? Colors.white : AlpesColors.cafeOscuro,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Titular y vencimiento
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('TITULAR',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: esPredeterminada
                                                  ? AlpesColors.arenaCalida
                                                  : AlpesColors.nogalMedio)),
                                      Text(titular,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: esPredeterminada
                                                  ? Colors.white
                                                  : AlpesColors.cafeOscuro)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('VENCE',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: esPredeterminada
                                                  ? AlpesColors.arenaCalida
                                                  : AlpesColors.nogalMedio)),
                                      Text('$mes/$anio',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: esPredeterminada
                                                  ? Colors.white
                                                  : AlpesColors.cafeOscuro)),
                                    ],
                                  ),
                                ],
                              ),

                              if (alias.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(alias,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: esPredeterminada
                                            ? AlpesColors.arenaCalida
                                            : AlpesColors.nogalMedio)),
                              ],

                              const SizedBox(height: 12),
                              const Divider(color: Colors.white24),

                              // Acciones
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!esPredeterminada)
                                    TextButton.icon(
                                      icon: Icon(Icons.star_outline, size: 16,
                                          color: esPredeterminada ? Colors.white : AlpesColors.nogalMedio),
                                      label: Text('Predeterminada',
                                          style: TextStyle(
                                              color: esPredeterminada
                                                  ? Colors.white
                                                  : AlpesColors.nogalMedio)),
                                      onPressed: () => _marcarPredeterminada(id),
                                    ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        color: esPredeterminada
                                            ? Colors.white70
                                            : AlpesColors.rojoColonial),
                                    onPressed: () => _eliminar(id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _mostrarFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AlpesColors.cremaFondo,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FormularioTarjeta(onGuardado: _cargar),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FORMULARIO
// ═══════════════════════════════════════════════════════════
class _FormularioTarjeta extends StatefulWidget {
  final VoidCallback onGuardado;
  const _FormularioTarjeta({required this.onGuardado});

  @override
  State<_FormularioTarjeta> createState() => _FormularioTarjetaState();
}

class _FormularioTarjetaState extends State<_FormularioTarjeta> {
  final _formKey = GlobalKey<FormState>();
  final _titularCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();
  final _mesCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  String _marca = 'VISA';
  bool _predeterminada = false;
  bool _guardando = false;

  final _marcas = ['VISA', 'MASTERCARD', 'AMEX', 'OTRO'];

  String _formatearNumero(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final auth = context.read<AuthProvider>();
    final numeroLimpio = _numeroCtrl.text.replaceAll(' ', '');
    try {
      final body = {
        'cli_id': auth.clienteId,
        'titular': _titularCtrl.text.trim().toUpperCase(),
        'ultimos_4': numeroLimpio.substring(numeroLimpio.length - 4),
        'marca': _marca,
        'mes_vencimiento': int.tryParse(_mesCtrl.text) ?? 1,
        'anio_vencimiento': int.tryParse(_anioCtrl.text) ?? 2025,
        'alias_tarjeta': _aliasCtrl.text.trim(),
        'predeterminada': _predeterminada ? 1 : 0,
      };

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tarjetas-cliente'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        Navigator.pop(context);
        widget.onGuardado();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tarjeta guardada'),
              backgroundColor: AlpesColors.exito),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['mensaje'] ?? 'Error al guardar'),
              backgroundColor: AlpesColors.rojoColonial),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: AlpesColors.rojoColonial),
      );
    }
    setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AlpesColors.arenaCalida,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Nueva tarjeta', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Número completo
              TextFormField(
                controller: _numeroCtrl,
                maxLength: 19, // 16 dígitos + 3 espacios
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de tarjeta',
                  hintText: '1234 5678 9012 3456',
                  prefixIcon: Icon(Icons.credit_card, color: AlpesColors.nogalMedio),
                  counterText: '',
                ),
                onChanged: (v) {
                  final formatted = _formatearNumero(v);
                  if (formatted != v) {
                    _numeroCtrl.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                validator: (v) {
                  final digits = (v ?? '').replaceAll(' ', '');
                  return digits.length != 16 ? 'Ingresa los 16 dígitos' : null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titularCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Nombre del titular',
                  hintText: 'Como aparece en la tarjeta',
                  prefixIcon: Icon(Icons.person_outline, color: AlpesColors.nogalMedio),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _marca,
                decoration: const InputDecoration(labelText: 'Marca'),
                items: _marcas.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _marca = v ?? 'VISA'),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mesCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: const InputDecoration(
                          labelText: 'Mes', hintText: 'MM', counterText: ''),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n < 1 || n > 12) ? 'Inválido' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _anioCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                          labelText: 'Año', hintText: 'YYYY', counterText: ''),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n < 2024) ? 'Inválido' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _aliasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alias (opcional)',
                  hintText: 'Ej: Tarjeta personal',
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                value: _predeterminada,
                onChanged: (v) => setState(() => _predeterminada = v),
                title: const Text('Marcar como predeterminada'),
                activeColor: AlpesColors.cafeOscuro,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('GUARDAR TARJETA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}