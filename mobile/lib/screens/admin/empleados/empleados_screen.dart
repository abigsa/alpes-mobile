import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});
  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
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
      final res = await http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.empleados));
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
      _filtrados = q.isEmpty ? List.from(_items) : _items.where((e) {
        final nombre = '${e['NOMBRES'] ?? e['nombres'] ?? ''} ${e['APELLIDOS'] ?? e['apellidos'] ?? ''}'.toLowerCase();
        return nombre.contains(q);
      }).toList();
    });
  }

  Future<void> _eliminar(dynamic id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Eliminar empleado'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AlpesColors.rojoColonial),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await http.delete(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.empleados}/$id'));
    _cargar();
  }

  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EmpleadosForm(item: item, onGuardado: _cargar),
    );
  }

  Color _colorEstado(String estado) =>
      estado.toLowerCase() == 'activo' ? const Color(0xFF3B6D11) : AlpesColors.rojoColonial;
  Color _bgEstado(String estado) =>
      estado.toLowerCase() == 'activo' ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('EMPLEADOS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _filtrar(),
              decoration: InputDecoration(
                hintText: 'Buscar empleado…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _searchCtrl.clear(); _filtrar(); })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true, fillColor: AlpesColors.cremaFondo,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(children: [
                Text('${_filtrados.length} empleado${_filtrados.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: AlpesColors.nogalMedio,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
                : _filtrados.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AlpesColors.cafeOscuro,
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
                          itemCount: _filtrados.length,
                          itemBuilder: (_, i) => _buildCard(_filtrados[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AlpesColors.cafeOscuro,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Nuevo empleado',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => _abrirForm(),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> e) {
    final id       = e['EMP_ID'] ?? e['emp_id'] ?? e['ID'] ?? e['id'];
    final nombres  = e['NOMBRES'] ?? e['nombres'] ?? '';
    final apellidos= e['APELLIDOS'] ?? e['apellidos'] ?? '';
    final email    = e['EMAIL'] ?? e['email'] ?? '';
    final salario  = double.tryParse('${e['SALARIO_BASE'] ?? e['salario_base'] ?? 0}') ?? 0;
    final estado   = (e['ESTADO'] ?? e['estado'] ?? 'Activo').toString();
    final fullName = '$nombres $apellidos'.trim();
    final initial  = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'E';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: [
          BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                  color: AlpesColors.verdeSelva.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(initial,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: AlpesColors.verdeSelva)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(fullName.isNotEmpty ? fullName : 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.w700,
                              fontSize: 14, color: AlpesColors.cafeOscuro)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: _bgEstado(estado),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(estado,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: _colorEstado(estado))),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  if (email.isNotEmpty) Row(children: [
                    const Icon(Icons.email_outlined, size: 11, color: AlpesColors.arenaCalida),
                    const SizedBox(width: 4),
                    Expanded(child: Text(email,
                        style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.attach_money_rounded, size: 13, color: AlpesColors.oroGuatemalteco),
                    Text('Q ${salario.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AlpesColors.nogalMedio)),
                  ]),
                ],
              ),
            ),
            Column(children: [
              _iconBtn(Icons.edit_outlined, AlpesColors.nogalMedio, () => _abrirForm(e)),
              const SizedBox(height: 4),
              _iconBtn(Icons.delete_outline, AlpesColors.rojoColonial, () => _eliminar(id)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: color),
    ),
  );

  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.badge_outlined, size: 64, color: AlpesColors.arenaCalida.withOpacity(0.5)),
      const SizedBox(height: 12),
      const Text('Sin empleados',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AlpesColors.nogalMedio)),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Agregar empleado'),
        onPressed: () => _abrirForm(),
      ),
    ]),
  );
}

// ─── FORM ────────────────────────────────────────────────

class _EmpleadosForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;
  const _EmpleadosForm({this.item, required this.onGuardado});
  @override
  State<_EmpleadosForm> createState() => __EmpleadosFormState();
}

class __EmpleadosFormState extends State<_EmpleadosForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _c = {
      'depto_id'       : TextEditingController(),
      'cargo_id'       : TextEditingController(),
      'rol_empleado_id': TextEditingController(),
      'nombres'        : TextEditingController(),
      'apellidos'      : TextEditingController(),
      'email'          : TextEditingController(),
      'telefono'       : TextEditingController(),
      'salario_base'   : TextEditingController(),
      'estado'         : TextEditingController(),
    };
    if (widget.item != null) {
      for (final k in _c.keys) {
        _c[k]!.text = '${widget.item![k.toUpperCase()] ?? widget.item![k] ?? ''}';
      }
    }
  }

  @override
  void dispose() { _c.values.forEach((c) => c.dispose()); super.dispose(); }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = _c.map((k, v) => MapEntry(k, v.text.trim()));
      final idKey = widget.item?.keys.firstWhere(
              (k) => k.toLowerCase() == 'emp_id', orElse: () => '') ?? '';
      final id = idKey.isNotEmpty ? widget.item![idKey] : null;
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.empleados}${id != null ? '/$id' : ''}');
      final res = id != null
          ? await http.put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          : await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        widget.onGuardado();
        if (context.mounted) Navigator.pop(context);
      } else {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['mensaje'] ?? 'Error'),
                backgroundColor: AlpesColors.rojoColonial));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AlpesColors.rojoColonial));
    } finally { setState(() => _guardando = false); }
  }

  Widget _campo(String label, String key,
      {TextInputType? type, bool required = false, String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _c[key],
          keyboardType: type,
          decoration: InputDecoration(labelText: label, hintText: hint),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
              : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AlpesColors.pergamino,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(widget.item == null ? 'Nuevo empleado' : 'Editar empleado',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: AlpesColors.cafeOscuro)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _campo('Nombres', 'nombres', required: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _campo('Apellidos', 'apellidos', required: true)),
                ]),
                _campo('Email', 'email', type: TextInputType.emailAddress),
                _campo('Teléfono', 'telefono', type: TextInputType.phone),
                _campo('Salario base', 'salario_base', type: TextInputType.number),
                Row(children: [
                  Expanded(child: _campo('Depto. ID', 'depto_id', type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _campo('Cargo ID', 'cargo_id', type: TextInputType.number)),
                ]),
                _campo('Rol empleado ID', 'rol_empleado_id', type: TextInputType.number),
                _campo('Estado', 'estado', hint: 'ACTIVO / INACTIVO'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('GUARDAR'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
