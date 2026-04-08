import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
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
        Uri.parse(ApiConfig.baseUrl + ApiConfig.inventarioProducto),
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
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventarioProducto}/$id'),
    );

    _cargar();
  }

  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InventarioForm(
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
        title: const Text('INVENTARIO'),
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

                      final dynamic idValue = item['INV_PROD_ID'] ??
                          item['inv_prod_id'] ??
                          item['INVENTARIO_PRODUCTO_ID'] ??
                          item['inventario_producto_id'] ??
                          item['ID'] ??
                          item['id'];

                      final int id = int.tryParse('${idValue ?? 0}') ?? 0;

                      final dynamic productoIdValue =
                          item['PRODUCTO_ID'] ?? item['producto_id'] ?? 0;

                      final int productoId =
                          int.tryParse('${productoIdValue ?? 0}') ?? 0;

                      final dynamic stockValue =
                          item['STOCK'] ?? item['stock'] ?? 0;
                      final dynamic stockReservadoValue =
                          item['STOCK_RESERVADO'] ??
                              item['stock_reservado'] ??
                              0;
                      final dynamic stockMinimoValue =
                          item['STOCK_MINIMO'] ?? item['stock_minimo'] ?? 0;

                      final nombreProducto = item['NOMBRE'] ??
                          item['nombre'] ??
                          item['PRODUCTO_NOMBRE'] ??
                          item['producto_nombre'] ??
                          'Producto ID: $productoId';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            nombreProducto.toString(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            'ID: $id | Producto: $productoId | Stock: $stockValue | Reservado: $stockReservadoValue | Mínimo: $stockMinimoValue',
                          ),
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

class _InventarioForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;

  const _InventarioForm({
    super.key,
    this.item,
    required this.onGuardado,
  });

  @override
  State<_InventarioForm> createState() => __InventarioFormState();
}

class __InventarioFormState extends State<_InventarioForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool _guardando = false;

  List<Map<String, dynamic>> _productos = [];
  bool _loadingProductos = true;
  int? _productoId;

  @override
  void initState() {
    super.initState();

    controllers['stock'] = TextEditingController();
    controllers['stock_reservado'] = TextEditingController();
    controllers['stock_minimo'] = TextEditingController();

    if (widget.item != null) {
      controllers['stock']!.text =
          (widget.item!['STOCK'] ?? widget.item!['stock'] ?? '').toString();
      controllers['stock_reservado']!.text =
          (widget.item!['STOCK_RESERVADO'] ??
                  widget.item!['stock_reservado'] ??
                  '')
              .toString();
      controllers['stock_minimo']!.text =
          (widget.item!['STOCK_MINIMO'] ?? widget.item!['stock_minimo'] ?? '')
              .toString();

      _productoId = _toInt(
        widget.item!['PRODUCTO_ID'] ?? widget.item!['producto_id'],
      );
    }

    _cargarProductos();
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  int? _validDropdownValue(
    int? selectedValue,
    List<Map<String, dynamic>> items,
    String primaryKey,
    String secondaryKey,
  ) {
    if (selectedValue == null) return null;

    final exists = items.any((item) {
      final value = _toInt(item[primaryKey] ?? item[secondaryKey]);
      return value == selectedValue;
    });

    return exists ? selectedValue : null;
  }

  Future<void> _cargarProductos() async {
    setState(() => _loadingProductos = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}'),
      );
      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        _productos = List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loadingProductos = false);
      }
    }
  }

  @override
  void dispose() {
    controllers['stock']?.dispose();
    controllers['stock_reservado']?.dispose();
    controllers['stock_minimo']?.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_productoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un producto')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final body = <String, dynamic>{
        'producto_id': _productoId,
        'stock': int.tryParse(controllers['stock']!.text.trim()) ?? 0,
        'stock_reservado':
            int.tryParse(controllers['stock_reservado']!.text.trim()) ?? 0,
        'stock_minimo':
            int.tryParse(controllers['stock_minimo']!.text.trim()) ?? 0,
      };

      final id = widget.item?['INV_PROD_ID'] ??
          widget.item?['inv_prod_id'] ??
          widget.item?['INVENTARIO_PRODUCTO_ID'] ??
          widget.item?['inventario_producto_id'] ??
          widget.item?['ID'] ??
          widget.item?['id'];

      http.Response res;

      if (id != null) {
        res = await http.put(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventarioProducto}/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } else {
        res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventarioProducto}'),
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

  Widget _campo(
    String label,
    String key, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controllers[key],
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.item == null ? 'Nuevo inventario' : 'Editar inventario',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _loadingProductos
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AlpesColors.cafeOscuro,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<int>(
                          value: _validDropdownValue(
                            _productoId,
                            _productos,
                            'PRODUCTO_ID',
                            'producto_id',
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Producto',
                          ),
                          items: _productos
                              .map((producto) {
                                final id = _toInt(
                                  producto['PRODUCTO_ID'] ??
                                      producto['producto_id'],
                                );
                                final nombre = (producto['NOMBRE'] ??
                                        producto['nombre'] ??
                                        '')
                                    .toString();
                                final referencia = (producto['REFERENCIA'] ??
                                        producto['referencia'] ??
                                        '')
                                    .toString();

                                if (id == null || nombre.isEmpty) return null;

                                final label = referencia.isNotEmpty
                                    ? '$nombre ($referencia)'
                                    : nombre;

                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(label),
                                );
                              })
                              .whereType<DropdownMenuItem<int>>()
                              .toList(),
                          onChanged: (value) {
                            setState(() => _productoId = value);
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Seleccione un producto';
                            }
                            return null;
                          },
                        ),
                      ),
                _campo(
                  'Stock',
                  'stock',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el stock';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
                _campo(
                  'Stock Reservado',
                  'stock_reservado',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el stock reservado';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
                _campo(
                  'Stock Minimo',
                  'stock_minimo',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el stock mínimo';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
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
}