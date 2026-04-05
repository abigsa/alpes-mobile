import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class NominaScreen extends StatefulWidget {
  const NominaScreen({super.key});
  @override
  State<NominaScreen> createState() => _NominaScreenState();
}

class _NominaScreenState extends State<NominaScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  double get _totalBruto => _items.fold(0, (s, n) =>
      s + (double.tryParse('${n['MONTO_BRUTO'] ?? n['monto_bruto'] ?? 0}') ?? 0));
  double get _totalNeto => _items.fold(0, (s, n) =>
      s + (double.tryParse('${n['MONTO_NETO'] ?? n['monto_neto'] ?? 0}') ?? 0));

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.nomina));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) setState(() => _items = List<Map<String, dynamic>>.from(data['data']));
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  Future<void> _eliminar(dynamic id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Eliminar nómina'),
      content: const Text('¿Estás seguro?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AlpesColors.rojoColonial),
            child: const Text('Eliminar')),
      ],
    ));
    if (ok != true) return;
    await http.delete(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.nomina}/$id'));
    _cargar();
  }

  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _NominaForm(item: item, onGuardado: _cargar));
  }

  Color _colorEstado(String e) => e.toLowerCase() == 'pagado'
      ? const Color(0xFF3B6D11) : e.toLowerCase() == 'pendiente'
      ? const Color(0xFF854F0B) : AlpesColors.nogalMedio;
  Color _bgEstado(String e) => e.toLowerCase() == 'pagado'
      ? const Color(0xFFEAF3DE) : e.toLowerCase() == 'pendiente'
      ? const Color(0xFFFAEEDA) : AlpesColors.pergamino;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('NÓMINA'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.canPop() ? context.pop() : context.go('/admin')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : RefreshIndicator(
              color: AlpesColors.cafeOscuro, onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  // Totales
                  if (_items.isNotEmpty) ...[
                    Row(children: [
                      Expanded(child: _totalCard('Total bruto', 'Q ${_totalBruto.toStringAsFixed(2)}',
                          Icons.account_balance_rounded, AlpesColors.cafeOscuro)),
                      const SizedBox(width: 10),
                      Expanded(child: _totalCard('Total neto', 'Q ${_totalNeto.toStringAsFixed(2)}',
                          Icons.payments_rounded, AlpesColors.verdeSelva)),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  ..._items.map((n) {
                    final id     = n['NOM_ID'] ?? n['nom_id'] ?? n['ID'] ?? n['id'];
                    final empId  = n['EMP_ID'] ?? n['emp_id'] ?? '-';
                    final bruto  = double.tryParse('${n['MONTO_BRUTO'] ?? n['monto_bruto'] ?? 0}') ?? 0;
                    final neto   = double.tryParse('${n['MONTO_NETO'] ?? n['monto_neto'] ?? 0}') ?? 0;
                    final estado = (n['ESTADO'] ?? n['estado'] ?? '-').toString();
                    final inicio = n['PERIODO_INICIO'] ?? n['periodo_inicio'] ?? '';
                    final fin    = n['PERIODO_FIN']    ?? n['periodo_fin']    ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AlpesColors.pergamino),
                          boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
                              blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Container(width: 44, height: 44,
                              decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.payments_rounded, color: AlpesColors.cafeOscuro, size: 22)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Empleado #$empId',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AlpesColors.cafeOscuro)),
                            const SizedBox(height: 3),
                            Text(inicio.isNotEmpty ? '$inicio → $fin' : '-',
                                style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text('Bruto: Q ${bruto.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
                              const SizedBox(width: 10),
                              Text('Neto: Q ${neto.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                      color: AlpesColors.cafeOscuro)),
                            ]),
                          ])),
                          Column(children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: _bgEstado(estado),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(estado, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: _colorEstado(estado)))),
                            const SizedBox(height: 8),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              _iBtn(Icons.edit_outlined, AlpesColors.nogalMedio, () => _abrirForm(n)),
                              const SizedBox(width: 4),
                              _iBtn(Icons.delete_outline, AlpesColors.rojoColonial, () => _eliminar(id)),
                            ]),
                          ]),
                        ]),
                      ),
                    );
                  }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AlpesColors.cafeOscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva nómina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => _abrirForm(),
      ),
    );
  }

  Widget _totalCard(String label, String value, IconData icon, Color accent) =>
      Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AlpesColors.pergamino),
              boxShadow: [BoxShadow(color: accent.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Row(children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 17, color: accent)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro), overflow: TextOverflow.ellipsis),
              Text(label, style: const TextStyle(fontSize: 10, color: AlpesColors.nogalMedio)),
            ])),
          ]));

  Widget _iBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: color)));
}

class _NominaForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;
  const _NominaForm({this.item, required this.onGuardado});
  @override State<_NominaForm> createState() => __NominaFormState();
}

class __NominaFormState extends State<_NominaForm> {
  final _fk = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  bool _g = false;

  @override
  void initState() {
    super.initState();
    _c = {
      'emp_id': TextEditingController(), 'periodo_inicio': TextEditingController(),
      'periodo_fin': TextEditingController(), 'monto_bruto': TextEditingController(),
      'monto_neto': TextEditingController(), 'fecha_pago': TextEditingController(),
      'estado': TextEditingController(),
    };
    if (widget.item != null) {
      for (final k in _c.keys) _c[k]!.text = '${widget.item![k.toUpperCase()] ?? widget.item![k] ?? ''}';
    }
  }

  @override void dispose() { _c.values.forEach((c) => c.dispose()); super.dispose(); }

  Future<void> _guardar() async {
    if (!_fk.currentState!.validate()) return;
    setState(() => _g = true);
    try {
      final body = _c.map((k, v) => MapEntry(k, v.text.trim()));
      final idKey = widget.item?.keys.firstWhere((k) => k.toLowerCase().contains('nom_id'), orElse: () => '') ?? '';
      final id = idKey.isNotEmpty ? widget.item![idKey] : null;
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.nomina}${id != null ? '/$id' : ''}');
      final res = id != null
          ? await http.put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          : await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) { widget.onGuardado(); if (context.mounted) Navigator.pop(context); }
      else if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['mensaje'] ?? 'Error'), backgroundColor: AlpesColors.rojoColonial));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AlpesColors.rojoColonial));
    } finally { setState(() => _g = false); }
  }

  Widget _f(String label, String key, {TextInputType? type}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(controller: _c[key], keyboardType: type,
          decoration: InputDecoration(labelText: label)));

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Form(key: _fk, child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AlpesColors.pergamino, borderRadius: BorderRadius.circular(2)))),
                Text(widget.item == null ? 'Nueva nómina' : 'Editar nómina',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
                const SizedBox(height: 16),
                _f('Empleado ID', 'emp_id', type: TextInputType.number),
                Row(children: [
                  Expanded(child: _f('Período inicio', 'periodo_inicio')),
                  const SizedBox(width: 10),
                  Expanded(child: _f('Período fin', 'periodo_fin')),
                ]),
                Row(children: [
                  Expanded(child: _f('Monto bruto', 'monto_bruto', type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _f('Monto neto', 'monto_neto', type: TextInputType.number)),
                ]),
                _f('Fecha de pago', 'fecha_pago'),
                _f('Estado', 'estado'),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _g ? null : _guardar,
                    child: _g ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('GUARDAR')),
              ])))));
}
