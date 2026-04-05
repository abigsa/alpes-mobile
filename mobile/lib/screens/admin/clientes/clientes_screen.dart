import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});
  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Map<String,dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.cliente));
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
    await http.delete(Uri.parse(ApiConfig.baseUrl + ApiConfig.cliente + '/' + id.toString()));
    _cargar();
  }

  void _abrirForm([Map<String,dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ClientesForm(item: item, onGuardado: _cargar),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('CLIENTES'),
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

class _ClientesForm extends StatefulWidget {
  final Map<String,dynamic>? item;
  final VoidCallback onGuardado;
  const _ClientesForm({super.key, this.item, required this.onGuardado});
  @override
  State<_ClientesForm> createState() => __ClientesFormState();
}

class __ClientesFormState extends State<_ClientesForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    controllers['tipo_documento'] = TextEditingController();
    controllers['num_documento'] = TextEditingController();
    controllers['nombres'] = TextEditingController();
    controllers['apellidos'] = TextEditingController();
    controllers['email'] = TextEditingController();
    controllers['tel_celular'] = TextEditingController();
    controllers['direccion'] = TextEditingController();
    controllers['ciudad'] = TextEditingController();
    controllers['departamento'] = TextEditingController();
    controllers['pais'] = TextEditingController();
    if (widget.item != null) {
      for (final k in controllers.keys) {
        final upper = k.toUpperCase();
        controllers[k]!.text = '\${widget.item![upper] ?? widget.item![k] ?? ''}';
      }
    }
  }

  @override
  void dispose() {
    controllers['tipo_documento']?.dispose();
    controllers['num_documento']?.dispose();
    controllers['nombres']?.dispose();
    controllers['apellidos']?.dispose();
    controllers['email']?.dispose();
    controllers['tel_celular']?.dispose();
    controllers['direccion']?.dispose();
    controllers['ciudad']?.dispose();
    controllers['departamento']?.dispose();
    controllers['pais']?.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = {
      'tipo_documento': controllers['tipo_documento']!.text,
      'num_documento': controllers['num_documento']!.text,
      'nombres': controllers['nombres']!.text,
      'apellidos': controllers['apellidos']!.text,
      'email': controllers['email']!.text,
      'tel_celular': controllers['tel_celular']!.text,
      'direccion': controllers['direccion']!.text,
      'ciudad': controllers['ciudad']!.text,
      'departamento': controllers['departamento']!.text,
      'pais': controllers['pais']!.text,
      };
      final idKey = widget.item?.keys.firstWhere((k) => k.toLowerCase().contains('id'), orElse: () => '') ?? '';
      final id = idKey.isNotEmpty ? widget.item![idKey] : null;
      http.Response res;
      if (id != null) {
        body[idKey.toLowerCase()] = id;
        res = await http.put(Uri.parse(ApiConfig.baseUrl + ApiConfig.cliente + '/' + id.toString()),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      } else {
        res = await http.post(Uri.parse(ApiConfig.baseUrl + ApiConfig.cliente),
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
                Text(widget.item == null ? 'Nuevo clientes' : 'Editar clientes',
                  style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
              TextFormField(
                controller: controllers['tipo_documento'],
                decoration: const InputDecoration(labelText: 'Tipo Documento'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['num_documento'],
                decoration: const InputDecoration(labelText: 'Num Documento'),
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
                controller: controllers['tel_celular'],
                decoration: const InputDecoration(labelText: 'Tel Celular'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['direccion'],
                decoration: const InputDecoration(labelText: 'Direccion'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['ciudad'],
                decoration: const InputDecoration(labelText: 'Ciudad'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['departamento'],
                decoration: const InputDecoration(labelText: 'Departamento'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['pais'],
                decoration: const InputDecoration(labelText: 'Pais'),
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
