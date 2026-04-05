import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.proveedores),
      );
      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _eliminar(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AlpesColors.rojoColonial,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.proveedores}/$id'),
    );

    _cargar();
  }

  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProveedoresForm(
        item: item,
        onGuardado: _cargar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
          title: const Text('PROVEEDORES'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/admin');
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _abrirForm(),
            ),
          ],
        ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AlpesColors.cafeOscuro,
              ),
            )
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: AlpesColors.arenaCalida,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sin registros',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                        onPressed: () => _abrirForm(),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AlpesColors.cafeOscuro,
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];

                      final dynamic idValue = item['PROV_ID'] ??
                          item['prov_id'] ??
                          item['PROVEEDOR_ID'] ??
                          item['proveedor_id'] ??
                          item['ID'] ??
                          item['id'];

                      final int id = int.tryParse('${idValue ?? 0}') ?? 0;

                      final nombre = item['RAZON_SOCIAL'] ??
                          item['razon_social'] ??
                          item['NOMBRE'] ??
                          item['nombre'] ??
                          'Sin nombre';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            nombre.toString(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text('ID: $id'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AlpesColors.nogalMedio,
                                ),
                                onPressed: () => _abrirForm(item),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AlpesColors.rojoColonial,
                                ),
                                onPressed: id > 0 ? () => _eliminar(id) : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AlpesColors.cafeOscuro,
        onPressed: () => _abrirForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ProveedoresForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;

  const _ProveedoresForm({
    this.item,
    required this.onGuardado,
  });

  @override
  State<_ProveedoresForm> createState() => __ProveedoresFormState();
}

class __ProveedoresFormState extends State<_ProveedoresForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    controllers['razon_social'] = TextEditingController();
    controllers['nit'] = TextEditingController();
    controllers['email'] = TextEditingController();
    controllers['telefono'] = TextEditingController();
    controllers['direccion'] = TextEditingController();
    controllers['ciudad'] = TextEditingController();
    controllers['pais'] = TextEditingController();

    if (widget.item != null) {
      for (final k in controllers.keys) {
        final upper = k.toUpperCase();
        controllers[k]!.text =
            (widget.item![upper] ?? widget.item![k] ?? '').toString();
      }
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final body = <String, dynamic>{
        'razon_social': controllers['razon_social']!.text,
        'nit': controllers['nit']!.text,
        'email': controllers['email']!.text,
        'telefono': controllers['telefono']!.text,
        'direccion': controllers['direccion']!.text,
        'ciudad': controllers['ciudad']!.text,
        'pais': controllers['pais']!.text,
      };

      final id = widget.item?['PROV_ID'] ??
          widget.item?['prov_id'] ??
          widget.item?['PROVEEDOR_ID'] ??
          widget.item?['proveedor_id'] ??
          widget.item?['ID'] ??
          widget.item?['id'];

      http.Response res;

      if (id != null) {
        res = await http.put(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.proveedores}/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } else {
        res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.proveedores}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      }

      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        widget.onGuardado();
        if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['mensaje'] ?? 'Error'),
              backgroundColor: AlpesColors.rojoColonial,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AlpesColors.rojoColonial,
          ),
        );
      }
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.item == null ? 'Nuevo proveedor' : 'Editar proveedor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _campo('Razon Social', 'razon_social'),
                _campo('Nit', 'nit'),
                _campo('Email', 'email'),
                _campo('Telefono', 'telefono'),
                _campo('Direccion', 'direccion'),
                _campo('Ciudad', 'ciudad'),
                _campo('Pais', 'pais'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('GUARDAR'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controllers[key],
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}