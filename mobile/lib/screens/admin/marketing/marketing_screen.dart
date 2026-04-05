import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});
  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.campanaMarketing));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) setState(() => _items = List<Map<String, dynamic>>.from(data['data']));
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  Future<void> _eliminar(dynamic id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Eliminar campaña'),
      content: const Text('¿Estás seguro?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AlpesColors.rojoColonial),
            child: const Text('Eliminar')),
      ],
    ));
    if (ok != true) return;
    await http.delete(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.campanaMarketing}/$id'));
    _cargar();
  }

  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MarketingForm(item: item, onGuardado: _cargar));
  }

  Color _canalColor(String canal) {
    switch (canal.toLowerCase()) {
      case 'redes sociales': return const Color(0xFF185FA5);
      case 'email': return const Color(0xFF3B6D11);
      case 'tv': return const Color(0xFF854F0B);
      default: return AlpesColors.nogalMedio;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPresupuesto = _items.fold<double>(0, (s, c) =>
        s + (double.tryParse('${c['PRESUPUESTO'] ?? c['presupuesto'] ?? 0}') ?? 0));

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('MARKETING'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              if (context.canPop()) { context.pop(); } else { context.go('/admin'); }
            }),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : RefreshIndicator(
              color: AlpesColors.cafeOscuro, onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  // Resumen
                  if (_items.isNotEmpty) ...[
                    Row(children: [
                      Expanded(child: _statCard('Campañas', '${_items.length}',
                          Icons.campaign_rounded, AlpesColors.cafeOscuro)),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard('Presupuesto total',
                          'Q ${totalPresupuesto.toStringAsFixed(0)}',
                          Icons.attach_money_rounded, AlpesColors.oroGuatemalteco)),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  // Lista campañas
                  ..._items.map((c) {
                    final id         = c['CAMP_ID'] ?? c['camp_id'] ?? c['ID'] ?? c['id'];
                    final nombre     = c['NOMBRE'] ?? c['nombre'] ?? 'Sin nombre';
                    final canal      = (c['CANAL'] ?? c['canal'] ?? '-').toString();
                    final presupuesto= double.tryParse('${c['PRESUPUESTO'] ?? c['presupuesto'] ?? 0}') ?? 0;
                    final inicio     = c['INICIO'] ?? c['inicio'] ?? '';
                    final fin        = c['FIN'] ?? c['fin'] ?? '';
                    final initial    = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'M';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AlpesColors.pergamino),
                          boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Padding(padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Container(width: 46, height: 46,
                              decoration: BoxDecoration(
                                  color: _canalColor(canal).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              alignment: Alignment.center,
                              child: Text(initial, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _canalColor(canal)))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AlpesColors.cafeOscuro)),
                            const SizedBox(height: 3),
                            Row(children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: _canalColor(canal).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Text(canal, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _canalColor(canal)))),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.attach_money_rounded, size: 13, color: AlpesColors.oroGuatemalteco),
                              Text('Q ${presupuesto.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AlpesColors.nogalMedio)),
                              if (inicio.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.calendar_today_rounded, size: 11, color: AlpesColors.arenaCalida),
                                const SizedBox(width: 3),
                                Text('$inicio → $fin', style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
                              ],
                            ]),
                          ])),
                          Column(children: [
                            _iBtn(Icons.edit_outlined, AlpesColors.nogalMedio, () => _abrirForm(c)),
                            const SizedBox(height: 4),
                            _iBtn(Icons.delete_outline, AlpesColors.rojoColonial, () => _eliminar(id)),
                          ]),
                        ])),
                    );
                  }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AlpesColors.cafeOscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva campaña', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => _abrirForm(),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accent) =>
      Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AlpesColors.pergamino),
              boxShadow: [BoxShadow(color: accent.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 17, color: accent)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro), overflow: TextOverflow.ellipsis),
              Text(label, style: const TextStyle(fontSize: 10, color: AlpesColors.nogalMedio)),
            ])),
          ]));

  Widget _iBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 15, color: color)));
}

class _MarketingForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;
  const _MarketingForm({this.item, required this.onGuardado});
  @override State<_MarketingForm> createState() => __MarketingFormState();
}
class __MarketingFormState extends State<_MarketingForm> {
  final _fk = GlobalKey<FormState>(); late final Map<String, TextEditingController> _c; bool _g = false;
  @override void initState() { super.initState(); _c = { 'nombre': TextEditingController(), 'canal': TextEditingController(), 'presupuesto': TextEditingController(), 'inicio': TextEditingController(), 'fin': TextEditingController() }; if (widget.item != null) for (final k in _c.keys) _c[k]!.text = '${widget.item![k.toUpperCase()] ?? widget.item![k] ?? ''}'; }
  @override void dispose() { _c.values.forEach((c) => c.dispose()); super.dispose(); }
  Future<void> _guardar() async {
    if (!_fk.currentState!.validate()) return; setState(() => _g = true);
    try {
      final body = _c.map((k, v) => MapEntry(k, v.text.trim()));
      final idKey = widget.item?.keys.firstWhere((k) => k.toLowerCase().contains('camp_id'), orElse: () => '') ?? '';
      final id = idKey.isNotEmpty ? widget.item![idKey] : null;
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.campanaMarketing}${id != null ? '/$id' : ''}');
      final res = id != null ? await http.put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)) : await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) { widget.onGuardado(); if (context.mounted) Navigator.pop(context); }
      else if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['mensaje'] ?? 'Error'), backgroundColor: AlpesColors.rojoColonial));
    } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AlpesColors.rojoColonial)); }
    finally { setState(() => _g = false); }
  }
  Widget _f(String label, String key, {TextInputType? type, bool req = false}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: _c[key], keyboardType: type, decoration: InputDecoration(labelText: label), validator: req ? (v) => v!.trim().isEmpty ? 'Requerido' : null : null));
  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: Form(key: _fk, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AlpesColors.pergamino, borderRadius: BorderRadius.circular(2)))),
        Text(widget.item == null ? 'Nueva campaña' : 'Editar campaña', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
        const SizedBox(height: 16),
        _f('Nombre de campaña', 'nombre', req: true),
        _f('Canal', 'canal'),
        _f('Presupuesto (Q)', 'presupuesto', type: TextInputType.number),
        Row(children: [Expanded(child: _f('Fecha inicio', 'inicio')), const SizedBox(width: 10), Expanded(child: _f('Fecha fin', 'fin'))]),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _g ? null : _guardar, child: _g ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('GUARDAR')),
      ])))));
}
