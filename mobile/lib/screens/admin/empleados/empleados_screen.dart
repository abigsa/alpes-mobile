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
  List<Map<String,dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.empleados));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) setState(() => _items = List<Map<String,dynamic>>.from(data['data']));
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  Future<void> _eliminar(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Confirmar'),
      content: const Text('¿Eliminar este registro?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar'),
          style: ElevatedButton.styleFrom(backgroundColor: AlpesColors.rojoColonial)),
      ],
    ));
    if (ok != true) return;
    await http.delete(Uri.parse(ApiConfig.baseUrl + ApiConfig.empleados + '/' + id.toString()));
    _cargar();
  }

  void _abrirForm([Map<String,dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EmpleadosForm(item: item, onGuardado: _cargar),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('EMPLEADOS'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _abrirForm())],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : _items.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.inbox_outlined, size: 64, color: AlpesColors.arenaCalida),
                  const SizedBox(height: 12),
                  Text('Sin registros', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Agregar'), onPressed: () => _abrirForm()),
                ]))
              : RefreshIndicator(
                  color: AlpesColors.cafeOscuro,
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final keys = item.keys.toList();
                      final idKey = keys.firstWhere((k) => k.toLowerCase().contains('id'), orElse: () => keys.first);
                      final nombreKey = keys.firstWhere((k) => k.toLowerCase().contains('nombre') || k.toLowerCase().contains('titulo') || k.toLowerCase().contains('codigo'), orElse: () => keys.length > 1 ? keys[1] : keys.first);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('\${item[nombreKey] ?? ''}', style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text('ID: \${item[idKey]}'),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, color: AlpesColors.nogalMedio), onPressed: () => _abrirForm(item)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: AlpesColors.rojoColonial), onPressed: () => _eliminar(item[idKey] as int)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AlpesColors.cafeOscuro,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _abrirForm(),
      ),
    );
  }
}

class _EmpleadosForm extends StatefulWidget {
  final Map<String,dynamic>? item;
  final VoidCallback onGuardado;
  const _EmpleadosForm({super.key, this.item, required this.onGuardado});
  @override
  State<_EmpleadosForm> createState() => __EmpleadosFormState();
}

class __EmpleadosFormState extends State<_EmpleadosForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    controllers['depto_id'] = TextEditingController();
    controllers['cargo_id'] = TextEditingController();
    controllers['rol_empleado_id'] = TextEditingController();
    controllers['nombres'] = TextEditingController();
    controllers['apellidos'] = TextEditingController();
    controllers['email'] = TextEditingController();
    controllers['telefono'] = TextEditingController();
    controllers['salario_base'] = TextEditingController();
    controllers['estado'] = TextEditingController();
    if (widget.item != null) {
      for (final k in controllers.keys) {
        final upper = k.toUpperCase();
        controllers[k]!.text = '\${widget.item![upper] ?? widget.item![k] ?? ''}';
      }
    }
  }

  @override
  void dispose() {
    controllers['depto_id']?.dispose();
    controllers['cargo_id']?.dispose();
    controllers['rol_empleado_id']?.dispose();
    controllers['nombres']?.dispose();
    controllers['apellidos']?.dispose();
    controllers['email']?.dispose();
    controllers['telefono']?.dispose();
    controllers['salario_base']?.dispose();
    controllers['estado']?.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = {
      'depto_id': controllers['depto_id']!.text,
      'cargo_id': controllers['cargo_id']!.text,
      'rol_empleado_id': controllers['rol_empleado_id']!.text,
      'nombres': controllers['nombres']!.text,
      'apellidos': controllers['apellidos']!.text,
      'email': controllers['email']!.text,
      'telefono': controllers['telefono']!.text,
      'salario_base': controllers['salario_base']!.text,
      'estado': controllers['estado']!.text,
      };
      final idKey = widget.item?.keys.firstWhere((k) => k.toLowerCase().contains('id'), orElse: () => '') ?? '';
      final id = idKey.isNotEmpty ? widget.item![idKey] : null;
      http.Response res;
      if (id != null) {
        body[idKey.toLowerCase()] = id;
        res = await http.put(Uri.parse(ApiConfig.baseUrl + ApiConfig.empleados + '/' + id.toString()),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      } else {
        res = await http.post(Uri.parse(ApiConfig.baseUrl + ApiConfig.empleados),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      }
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        widget.onGuardado();
        if (context.mounted) Navigator.pop(context);
      } else {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['mensaje'] ?? 'Error'), backgroundColor: AlpesColors.rojoColonial));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \$e'), backgroundColor: AlpesColors.rojoColonial));
    } finally { setState(() => _guardando = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.item == null ? 'Nuevo empleados' : 'Editar empleados',
                  style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
              TextFormField(
                controller: controllers['depto_id'],
                decoration: const InputDecoration(labelText: 'Depto Id'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['cargo_id'],
                decoration: const InputDecoration(labelText: 'Cargo Id'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['rol_empleado_id'],
                decoration: const InputDecoration(labelText: 'Rol Empleado Id'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['nombres'],
                decoration: const InputDecoration(labelText: 'Nombres'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['apellidos'],
                decoration: const InputDecoration(labelText: 'Apellidos'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['email'],
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['telefono'],
                decoration: const InputDecoration(labelText: 'Telefono'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['salario_base'],
                decoration: const InputDecoration(labelText: 'Salario Base'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['estado'],
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              const SizedBox(height: 12),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
