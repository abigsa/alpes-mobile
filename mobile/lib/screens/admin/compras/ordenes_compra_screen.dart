// ORDENES COMPRA
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class OrdenesCompraScreen extends StatefulWidget {
  const OrdenesCompraScreen({super.key});
  @override
  State<OrdenesCompraScreen> createState() => _OrdenesCompraScreenState();
}

class _OrdenesCompraScreenState extends State<OrdenesCompraScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _cargar(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.ordenCompra));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        _items = List<Map<String, dynamic>>.from(data['data']);
        _filtrar();
      }
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados = q.isEmpty ? List.from(_items) : _items.where((o) =>
          (o['NUM_OC'] ?? o['num_oc'] ?? '').toString().toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _eliminar(dynamic id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Eliminar orden de compra'),
      content: const Text('¿Estás seguro?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AlpesColors.rojoColonial),
            child: const Text('Eliminar')),
      ],
    ));
    if (ok != true) return;
    await http.delete(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenCompra}/$id'));
    _cargar();
  }

  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CompraForm(item: item, onGuardado: _cargar));
  }

  Color _colorEstado(String e) {
    switch (e.toLowerCase()) {
      case 'aprobada': return const Color(0xFF3B6D11);
      case 'pendiente': return const Color(0xFF854F0B);
      case 'recibida': return const Color(0xFF185FA5);
      case 'cancelada': return AlpesColors.rojoColonial;
      default: return AlpesColors.nogalMedio;
    }
  }
  Color _bgEstado(String e) {
    switch (e.toLowerCase()) {
      case 'aprobada': return const Color(0xFFEAF3DE);
      case 'pendiente': return const Color(0xFFFAEEDA);
      case 'recibida': return const Color(0xFFE6F1FB);
      case 'cancelada': return const Color(0xFFFCEBEB);
      default: return AlpesColors.pergamino;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('ÓRDENES DE COMPRA'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.canPop() ? context.pop() : context.go('/admin')),
      ),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: TextField(controller: _searchCtrl, onChanged: (_) => _filtrar(),
            decoration: InputDecoration(hintText: 'Buscar por número OC…',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true, fillColor: AlpesColors.cremaFondo,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
              : _filtrados.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: AlpesColors.arenaCalida.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text('Sin órdenes de compra', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AlpesColors.nogalMedio)),
                    ]))
                  : RefreshIndicator(color: AlpesColors.cafeOscuro, onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
                        itemCount: _filtrados.length,
                        itemBuilder: (_, i) {
                          final o = _filtrados[i];
                          final id     = o['OC_ID'] ?? o['oc_id'] ?? o['ID'] ?? o['id'];
                          final num    = o['NUM_OC'] ?? o['num_oc'] ?? '#$id';
                          final total  = double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0;
                          final estado = (o['ESTADO'] ?? o['estado'] ?? '-').toString();
                          final provId = o['PROV_ID'] ?? o['prov_id'] ?? '-';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AlpesColors.pergamino),
                                boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
                            child: Padding(padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                Container(width: 44, height: 44,
                                    decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.shopping_bag_rounded, color: AlpesColors.cafeOscuro, size: 22)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('$num', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AlpesColors.cafeOscuro)),
                                  const SizedBox(height: 3),
                                  Text('Proveedor: #$provId', style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
                                  Text('Q ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro)),
                                ])),
                                Column(children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: _bgEstado(estado), borderRadius: BorderRadius.circular(20)),
                                      child: Text(estado, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _colorEstado(estado)))),
                                  const SizedBox(height: 8),
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    _iBtn(Icons.edit_outlined, AlpesColors.nogalMedio, () => _abrirForm(o)),
                                    const SizedBox(width: 4),
                                    _iBtn(Icons.delete_outline, AlpesColors.rojoColonial, () => _eliminar(id)),
                                  ]),
                                ]),
                              ])),
                          );
                        },
                      )),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AlpesColors.cafeOscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva orden', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => _abrirForm(),
      ),
    );
  }
  Widget _iBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 15, color: color)));
}

class _CompraForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;
  const _CompraForm({this.item, required this.onGuardado});
  @override State<_CompraForm> createState() => __CompraFormState();
}
class __CompraFormState extends State<_CompraForm> {
  final _fk = GlobalKey<FormState>(); late final Map<String, TextEditingController> _c; bool _g = false;
  @override void initState() { super.initState(); _c = { 'num_oc': TextEditingController(), 'prov_id': TextEditingController(), 'estado_oc_id': TextEditingController(), 'condicion_pago_id': TextEditingController(), 'subtotal': TextEditingController(), 'impuesto': TextEditingController(), 'total': TextEditingController(), 'observaciones': TextEditingController() }; if (widget.item != null) for (final k in _c.keys) _c[k]!.text = '${widget.item![k.toUpperCase()] ?? widget.item![k] ?? ''}'; }
  @override void dispose() { _c.values.forEach((c) => c.dispose()); super.dispose(); }
  Future<void> _guardar() async {
    if (!_fk.currentState!.validate()) return; setState(() => _g = true);
    try {
      final body = _c.map((k, v) => MapEntry(k, v.text.trim()));
      final idKey = widget.item?.keys.firstWhere((k) => k.toLowerCase() == 'oc_id', orElse: () => '') ?? '';
      final id = idKey.isNotEmpty ? widget.item![idKey] : null;
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenCompra}${id != null ? '/$id' : ''}');
      final res = id != null ? await http.put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)) : await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) { widget.onGuardado(); if (context.mounted) Navigator.pop(context); }
      else if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['mensaje'] ?? 'Error'), backgroundColor: AlpesColors.rojoColonial));
    } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AlpesColors.rojoColonial)); }
    finally { setState(() => _g = false); }
  }
  Widget _f(String label, String key, {TextInputType? type}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: _c[key], keyboardType: type, decoration: InputDecoration(labelText: label)));
  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: Form(key: _fk, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AlpesColors.pergamino, borderRadius: BorderRadius.circular(2)))),
        Text(widget.item == null ? 'Nueva orden de compra' : 'Editar orden', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: _f('No. OC', 'num_oc')), const SizedBox(width: 10), Expanded(child: _f('Proveedor ID', 'prov_id', type: TextInputType.number))]),
        Row(children: [Expanded(child: _f('Subtotal', 'subtotal', type: TextInputType.number)), const SizedBox(width: 10), Expanded(child: _f('Impuesto', 'impuesto', type: TextInputType.number))]),
        _f('Total', 'total', type: TextInputType.number),
        _f('Observaciones', 'observaciones'),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _g ? null : _guardar, child: _g ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('GUARDAR')),
      ])))));
}
