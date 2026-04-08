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
        Uri.parse(ApiConfig.baseUrl + ApiConfig.productos),
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
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}/$id'),
    );

    _cargar();
  }

  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductosForm(
        item: item,
        onGuardado: _cargar,
      ),
    );
  }

  Future<void> _abrirFormConDetalle([Map<String, dynamic>? item]) async {
    if (item == null) {
      _abrirForm();
      return;
    }

    final dynamic idValue =
        item['PRODUCTO_ID'] ?? item['producto_id'] ?? item['ID'] ?? item['id'];

    final int id = int.tryParse('${idValue ?? 0}') ?? 0;

    if (id <= 0) {
      _abrirForm(item);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}/$id'),
      );

      final data = jsonDecode(res.body);

      if (data['ok'] == true && data['data'] != null) {
        final detalle = Map<String, dynamic>.from(data['data']);
        _abrirForm(detalle);
      } else {
        _abrirForm(item);
      }
    } catch (_) {
      _abrirForm(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('PRODUCTOS'),
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

                      final dynamic idValue = item['PRODUCTO_ID'] ??
                          item['producto_id'] ??
                          item['ID'] ??
                          item['id'];

                      final int id = int.tryParse('${idValue ?? 0}') ?? 0;

                      final nombre = item['NOMBRE'] ??
                          item['nombre'] ??
                          item['REFERENCIA'] ??
                          item['referencia'] ??
                          'Sin nombre';

                      final referencia =
                          item['REFERENCIA'] ?? item['referencia'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            nombre.toString(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            referencia.toString().isNotEmpty
                                ? 'ID: $id | Ref: $referencia'
                                : 'ID: $id',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AlpesColors.nogalMedio,
                                ),
                                onPressed: () => _abrirFormConDetalle(item),
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

class _ProductosForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;

  const _ProductosForm({
    super.key,
    this.item,
    required this.onGuardado,
  });

  @override
  State<_ProductosForm> createState() => __ProductosFormState();
}

class __ProductosFormState extends State<_ProductosForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool _guardando = false;

  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _unidades = [];
  bool _loadingCatalogos = true;

  int? _categoriaId;
  int? _unidadMedidaId;

  @override
  void initState() {
    super.initState();

    controllers['referencia'] = TextEditingController();
    controllers['nombre'] = TextEditingController();
    controllers['descripcion'] = TextEditingController();
    controllers['tipo'] = TextEditingController();
    controllers['material'] = TextEditingController();
    controllers['alto_cm'] = TextEditingController();
    controllers['ancho_cm'] = TextEditingController();
    controllers['profundidad_cm'] = TextEditingController();
    controllers['color'] = TextEditingController();
    controllers['peso_gramos'] = TextEditingController();
    controllers['imagen_url'] = TextEditingController();
    controllers['lote_producto'] = TextEditingController();

    if (widget.item != null) {
      for (final k in controllers.keys) {
        final upper = k.toUpperCase();
        controllers[k]!.text =
            (widget.item![upper] ?? widget.item![k] ?? '').toString();
      }

      _unidadMedidaId = _toInt(
        widget.item!['UNIDAD_MEDIDA_ID'] ?? widget.item!['unidad_medida_id'],
      );
      _categoriaId = _toInt(
        widget.item!['CATEGORIA_ID'] ?? widget.item!['categoria_id'],
      );
    }

    _cargarCatalogos();
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

  Future<void> _cargarCatalogos() async {
    setState(() => _loadingCatalogos = true);
    try {
      final unidadesRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.unidadMedida}'),
      );
      final categoriasRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.categorias}'),
      );

      final unidadesData = jsonDecode(unidadesRes.body);
      final categoriasData = jsonDecode(categoriasRes.body);

      if (unidadesData['ok'] == true) {
        _unidades = List<Map<String, dynamic>>.from(unidadesData['data']);
      }

      if (categoriasData['ok'] == true) {
        _categorias = List<Map<String, dynamic>>.from(categoriasData['data']);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loadingCatalogos = false);
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

    if (_unidadMedidaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione la unidad de medida')),
      );
      return;
    }

    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione la categoría')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final body = <String, dynamic>{
        'referencia': controllers['referencia']!.text.trim(),
        'nombre': controllers['nombre']!.text.trim(),
        'descripcion': controllers['descripcion']!.text.trim(),
        'tipo': controllers['tipo']!.text.trim().toUpperCase(),
        'material': controllers['material']!.text.trim(),
        'alto_cm': double.tryParse(controllers['alto_cm']!.text.trim()) ?? 0,
        'ancho_cm': double.tryParse(controllers['ancho_cm']!.text.trim()) ?? 0,
        'profundidad_cm':
            double.tryParse(controllers['profundidad_cm']!.text.trim()) ?? 0,
        'color': controllers['color']!.text.trim(),
        'peso_gramos':
            int.tryParse(controllers['peso_gramos']!.text.trim()) ?? 0,
        'imagen_url': controllers['imagen_url']!.text.trim(),
        'unidad_medida_id': _unidadMedidaId,
        'categoria_id': _categoriaId,
        'lote_producto': controllers['lote_producto']!.text.trim(),
      };

      final id = widget.item?['PRODUCTO_ID'] ??
          widget.item?['producto_id'] ??
          widget.item?['ID'] ??
          widget.item?['id'];

      http.Response res;

      if (id != null) {
        res = await http.put(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } else {
        res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}'),
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
                  widget.item == null ? 'Nuevo producto' : 'Editar producto',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _campo('Referencia', 'referencia'),
                _campo(
                  'Nombre',
                  'nombre',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el nombre';
                    }
                    return null;
                  },
                ),
                _campo('Descripcion', 'descripcion'),
                _campo(
                  'Tipo (INTERIOR o EXTERIOR)',
                  'tipo',
                  validator: (value) {
                    final v = value?.trim().toUpperCase() ?? '';
                    if (v.isEmpty) return 'Ingrese el tipo';
                    if (v != 'INTERIOR' && v != 'EXTERIOR') {
                      return 'Debe ser INTERIOR o EXTERIOR';
                    }
                    return null;
                  },
                ),
                _campo('Material', 'material'),
                _campo(
                  'Alto cm',
                  'alto_cm',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el alto';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Ingrese un numero valido';
                    }
                    return null;
                  },
                ),
                _campo(
                  'Ancho cm',
                  'ancho_cm',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el ancho';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Ingrese un numero valido';
                    }
                    return null;
                  },
                ),
                _campo(
                  'Profundidad cm',
                  'profundidad_cm',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese la profundidad';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Ingrese un numero valido';
                    }
                    return null;
                  },
                ),
                _campo('Color', 'color'),
                _campo(
                  'Peso gramos',
                  'peso_gramos',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el peso';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Ingrese un numero entero valido';
                    }
                    return null;
                  },
                ),
                _campo('Imagen Url', 'imagen_url'),
                const SizedBox(height: 4),
                _loadingCatalogos
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AlpesColors.cafeOscuro,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DropdownButtonFormField<int>(
                              value: _validDropdownValue(
                                _unidadMedidaId,
                                _unidades,
                                'UNIDAD_MEDIDA_ID',
                                'unidad_medida_id',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Unidad de Medida',
                              ),
                              items: _unidades
                                  .map((unidad) {
                                    final id = _toInt(
                                      unidad['UNIDAD_MEDIDA_ID'] ??
                                          unidad['unidad_medida_id'],
                                    );
                                    final nombre =
                                        (unidad['NOMBRE'] ?? unidad['nombre'] ?? '')
                                            .toString();

                                    if (id == null || nombre.isEmpty) return null;

                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(nombre),
                                    );
                                  })
                                  .whereType<DropdownMenuItem<int>>()
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _unidadMedidaId = value);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Seleccione una unidad de medida';
                                }
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DropdownButtonFormField<int>(
                              value: _validDropdownValue(
                                _categoriaId,
                                _categorias,
                                'CATEGORIA_ID',
                                'categoria_id',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                              ),
                              items: _categorias
                                  .map((categoria) {
                                    final id = _toInt(
                                      categoria['CATEGORIA_ID'] ??
                                          categoria['categoria_id'],
                                    );
                                    final nombre = (categoria['NOMBRE'] ??
                                            categoria['nombre'] ??
                                            '')
                                        .toString();

                                    if (id == null || nombre.isEmpty) return null;

                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(nombre),
                                    );
                                  })
                                  .whereType<DropdownMenuItem<int>>()
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _categoriaId = value);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Seleccione una categoría';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                _campo('Lote Producto', 'lote_producto'),
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