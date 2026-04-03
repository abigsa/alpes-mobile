import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});
  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  List<Map<String,dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.productos));
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
    await http.delete(Uri.parse(ApiConfig.baseUrl + ApiConfig.productos + '/' + id.toString()));
    _cargar();
  }

  void _abrirForm([Map<String,dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductosForm(item: item, onGuardado: _cargar),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('PRODUCTOS'),
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

class _ProductosForm extends StatefulWidget {
  final Map<String,dynamic>? item;
  final VoidCallback onGuardado;
  const _ProductosForm({super.key, this.item, required this.onGuardado});
  @override
  State<_ProductosForm> createState() => __ProductosFormState();
}

class __ProductosFormState extends State<_ProductosForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    controllers['nombre'] = TextEditingController();
    controllers['descripcion'] = TextEditingController();
    controllers['tipo'] = TextEditingController();
    controllers['material'] = TextEditingController();
    controllers['color'] = TextEditingController();
    controllers['imagen_url'] = TextEditingController();
    controllers['unidad_medida_id'] = TextEditingController();
    controllers['categoria_id'] = TextEditingController();
    controllers['lote_producto'] = TextEditingController();
    if (widget.item != null) {
      for (final k in controllers.keys) {
        final upper = k.toUpperCase();
        controllers[k]!.text = '\${widget.item![upper] ?? widget.item![k] ?? ''}';
      }
    }
  }

  @override
  void dispose() {
    controllers['nombre']?.dispose();
    controllers['descripcion']?.dispose();
    controllers['tipo']?.dispose();
    controllers['material']?.dispose();
    controllers['color']?.dispose();
    controllers['imagen_url']?.dispose();
    controllers['unidad_medida_id']?.dispose();
    controllers['categoria_id']?.dispose();
    controllers['lote_producto']?.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = {
      'nombre': controllers['nombre']!.text,
      'descripcion': controllers['descripcion']!.text,
      'tipo': controllers['tipo']!.text,
      'material': controllers['material']!.text,
      'color': controllers['color']!.text,
      'imagen_url': controllers['imagen_url']!.text,
      'unidad_medida_id': controllers['unidad_medida_id']!.text,
      'categoria_id': controllers['categoria_id']!.text,
      'lote_producto': controllers['lote_producto']!.text,
      };
      final idKey = widget.item?.keys.firstWhere((k) => k.toLowerCase().contains('id'), orElse: () => '') ?? '';
      final id = idKey.isNotEmpty ? widget.item![idKey] : null;
      http.Response res;
      if (id != null) {
        body[idKey.toLowerCase()] = id;
        res = await http.put(Uri.parse(ApiConfig.baseUrl + ApiConfig.productos + '/' + id.toString()),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      } else {
        res = await http.post(Uri.parse(ApiConfig.baseUrl + ApiConfig.productos),
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
                Text(widget.item == null ? 'Nuevo productos' : 'Editar productos',
                  style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
              TextFormField(
                controller: controllers['nombre'],
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['descripcion'],
                decoration: const InputDecoration(labelText: 'Descripcion'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['tipo'],
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['material'],
                decoration: const InputDecoration(labelText: 'Material'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['color'],
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['imagen_url'],
                decoration: const InputDecoration(labelText: 'Imagen Url'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['unidad_medida_id'],
                decoration: const InputDecoration(labelText: 'Unidad Medida Id'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['categoria_id'],
                decoration: const InputDecoration(labelText: 'Categoria Id'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['lote_producto'],
                decoration: const InputDecoration(labelText: 'Lote Producto'),
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
