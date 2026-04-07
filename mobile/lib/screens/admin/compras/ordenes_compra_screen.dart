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
<<<<<<< Updated upstream
  List<Map<String,dynamic>> _items = [];
=======
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtrados = [];
  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _estadosOrdenCompra = [];
  List<Map<String, dynamic>> _condicionesPago = [];

>>>>>>> Stashed changes
  bool _loading = true;

  @override
<<<<<<< Updated upstream
  void initState() { super.initState(); _cargar(); }
=======
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
>>>>>>> Stashed changes

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
<<<<<<< Updated upstream
      final res = await http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.ordenCompra));
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
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AlpesColors.rojoColonial), child: const Text('Eliminar')),
      ],
    ));
=======
      final responses = await Future.wait([
        http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.ordenCompra)),
        http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.proveedores)),
        http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.estadoOrdenCompra)),
        http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.condicionPago)),
      ]);

      final ordenesData = jsonDecode(responses[0].body);
      final proveedoresData = jsonDecode(responses[1].body);
      final estadosData = jsonDecode(responses[2].body);
      final condicionesData = jsonDecode(responses[3].body);

      if (!mounted) return;

      setState(() {
        _items = ordenesData['ok'] == true
            ? List<Map<String, dynamic>>.from(ordenesData['data'])
            : [];
        _proveedores = proveedoresData['ok'] == true
            ? List<Map<String, dynamic>>.from(proveedoresData['data'])
            : [];
        _estadosOrdenCompra = estadosData['ok'] == true
            ? List<Map<String, dynamic>>.from(estadosData['data'])
            : [];
        _condicionesPago = condicionesData['ok'] == true
            ? List<Map<String, dynamic>>.from(condicionesData['data'])
            : [];
        _filtrar();
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados = q.isEmpty
          ? List.from(_items)
          : _items.where((o) {
              final numOc =
                  (o['NUM_OC'] ?? o['num_oc'] ?? '').toString().toLowerCase();
              final razonSocial = (o['RAZON_SOCIAL'] ?? o['razon_social'] ?? '')
                  .toString()
                  .toLowerCase();
              return numOc.contains(q) || razonSocial.contains(q);
            }).toList();
    });
  }

  Future<void> _eliminar(dynamic id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Eliminar orden de compra'),
        content: const Text('¿Estás seguro?'),
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

>>>>>>> Stashed changes
    if (ok != true) return;

    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenCompra}/$id'),
    );
    _cargar();
  }

<<<<<<< Updated upstream
  void _abrirForm([Map<String,dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OrdenesCompraForm(item: item, onGuardado: _cargar),
    );
=======
  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CompraForm(
        item: item,
        proveedores: _proveedores,
        estadosOrdenCompra: _estadosOrdenCompra,
        condicionesPago: _condicionesPago,
        onGuardado: _cargar,
      ),
    );
  }

  Future<void> _abrirFormConDetalle([Map<String, dynamic>? item]) async {
    if (item == null) {
      _abrirForm();
      return;
    }

    final dynamic idValue = item['ORDEN_COMPRA_ID'] ??
        item['orden_compra_id'] ??
        item['ID'] ??
        item['id'];

    final int id = int.tryParse('${idValue ?? 0}') ?? 0;

    if (id <= 0) {
      _abrirForm(item);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenCompra}/$id'),
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

  String _formatearFecha(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    final raw = value.toString();
    if (raw.contains('T')) return raw.split('T').first;
    return raw;
  }

  Color _colorEstado(String e) {
    switch (e.toLowerCase()) {
      case 'aprobada':
        return const Color(0xFF3B6D11);
      case 'pendiente':
        return const Color(0xFF854F0B);
      case 'recibida':
        return const Color(0xFF185FA5);
      case 'cancelada':
        return AlpesColors.rojoColonial;
      case 'abierta':
        return AlpesColors.nogalMedio;
      case 'cerrada':
        return AlpesColors.nogalMedio;
      default:
        return AlpesColors.nogalMedio;
    }
  }

  Color _bgEstado(String e) {
    switch (e.toLowerCase()) {
      case 'aprobada':
        return const Color(0xFFEAF3DE);
      case 'pendiente':
        return const Color(0xFFFAEEDA);
      case 'recibida':
        return const Color(0xFFE6F1FB);
      case 'cancelada':
        return const Color(0xFFFCEBEB);
      case 'abierta':
      case 'cerrada':
        return AlpesColors.pergamino;
      default:
        return AlpesColors.pergamino;
    }
>>>>>>> Stashed changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
<<<<<<< Updated upstream
        title: const Text('ORDENES COMPRA'),
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
                          subtitle: const Text('ID: \${item[idKey]}'),
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
=======
        title: const Text('ÓRDENES DE COMPRA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin'),
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
                hintText: 'Buscar por número OC…',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: AlpesColors.cremaFondo,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AlpesColors.cafeOscuro,
                    ),
                  )
                : _filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: AlpesColors.arenaCalida.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Sin órdenes de compra',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AlpesColors.nogalMedio,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AlpesColors.cafeOscuro,
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
                          itemCount: _filtrados.length,
                          itemBuilder: (_, i) {
                            final o = _filtrados[i];
                            final id = o['ORDEN_COMPRA_ID'] ??
                                o['orden_compra_id'] ??
                                o['ID'] ??
                                o['id'];
                            final num = o['NUM_OC'] ?? o['num_oc'] ?? '#$id';
                            final total =
                                double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0;
                            final estado = (o['ESTADO_OC'] ??
                                    o['estado_oc'] ??
                                    o['ESTADO_OC_CODIGO'] ??
                                    o['estado_oc_codigo'] ??
                                    o['ESTADO'] ??
                                    o['estado'] ??
                                    '-')
                                .toString();
                            final razonSocial =
                                (o['RAZON_SOCIAL'] ?? o['razon_social'] ?? '-')
                                    .toString();
                            final fechaOc =
                                _formatearFecha(o['FECHA_OC'] ?? o['fecha_oc']);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AlpesColors.pergamino),
                                boxShadow: [
                                  BoxShadow(
                                    color: AlpesColors.cafeOscuro.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AlpesColors.cafeOscuro.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.shopping_bag_rounded,
                                        color: AlpesColors.cafeOscuro,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$num',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: AlpesColors.cafeOscuro,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Proveedor: $razonSocial',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AlpesColors.nogalMedio,
                                            ),
                                          ),
                                          Text(
                                            'Fecha: $fechaOc',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AlpesColors.nogalMedio,
                                            ),
                                          ),
                                          Text(
                                            'Q ${total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AlpesColors.cafeOscuro,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _bgEstado(estado),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            estado,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: _colorEstado(estado),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _iBtn(
                                              Icons.edit_outlined,
                                              AlpesColors.nogalMedio,
                                              () => _abrirFormConDetalle(o),
                                            ),
                                            const SizedBox(width: 4),
                                            _iBtn(
                                              Icons.delete_outline,
                                              AlpesColors.rojoColonial,
                                              () => _eliminar(id),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AlpesColors.cafeOscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva orden',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
>>>>>>> Stashed changes
        onPressed: () => _abrirForm(),
      ),
    );
  }
<<<<<<< Updated upstream
}

class _OrdenesCompraForm extends StatefulWidget {
  final Map<String,dynamic>? item;
  final VoidCallback onGuardado;
  const _OrdenesCompraForm({this.item, required this.onGuardado});
  @override
  State<_OrdenesCompraForm> createState() => __OrdenesCompraFormState();
}

class __OrdenesCompraFormState extends State<_OrdenesCompraForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    controllers['num_oc'] = TextEditingController();
    controllers['prov_id'] = TextEditingController();
    controllers['estado_oc_id'] = TextEditingController();
    controllers['condicion_pago_id'] = TextEditingController();
    controllers['subtotal'] = TextEditingController();
    controllers['impuesto'] = TextEditingController();
    controllers['total'] = TextEditingController();
    controllers['observaciones'] = TextEditingController();
    if (widget.item != null) {
      for (final k in controllers.keys) {
        final upper = k.toUpperCase();
        controllers[k]!.text = '\${widget.item![upper] ?? widget.item![k] ?? ''}';
      }
    }
  }

  @override
  void dispose() {
    controllers['num_oc']?.dispose();
    controllers['prov_id']?.dispose();
    controllers['estado_oc_id']?.dispose();
    controllers['condicion_pago_id']?.dispose();
    controllers['subtotal']?.dispose();
    controllers['impuesto']?.dispose();
    controllers['total']?.dispose();
    controllers['observaciones']?.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = {
      'num_oc': controllers['num_oc']!.text,
      'prov_id': controllers['prov_id']!.text,
      'estado_oc_id': controllers['estado_oc_id']!.text,
      'condicion_pago_id': controllers['condicion_pago_id']!.text,
      'subtotal': controllers['subtotal']!.text,
      'impuesto': controllers['impuesto']!.text,
      'total': controllers['total']!.text,
      'observaciones': controllers['observaciones']!.text,
      };
      final idKey = widget.item?.keys.firstWhere((k) => k.toLowerCase().contains('id'), orElse: () => '') ?? '';
      final id = idKey.isNotEmpty ? widget.item![idKey] : null;
      http.Response res;
      if (id != null) {
        body[idKey.toLowerCase()] = id;
        res = await http.put(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenCompra}/$id'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      } else {
        res = await http.post(Uri.parse(ApiConfig.baseUrl + ApiConfig.ordenCompra),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      }
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        widget.onGuardado();
        if (context.mounted) Navigator.pop(context);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['mensaje'] ?? 'Error'), backgroundColor: AlpesColors.rojoColonial));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: \$e'), backgroundColor: AlpesColors.rojoColonial));
      }
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
                Text(widget.item == null ? 'Nuevo ordenes compra' : 'Editar ordenes compra',
                  style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
              TextFormField(
                controller: controllers['num_oc'],
                decoration: const InputDecoration(labelText: 'Num Oc'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['prov_id'],
                decoration: const InputDecoration(labelText: 'Prov Id'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['estado_oc_id'],
                decoration: const InputDecoration(labelText: 'Estado Oc Id'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['condicion_pago_id'],
                decoration: const InputDecoration(labelText: 'Condicion Pago Id'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['subtotal'],
                decoration: const InputDecoration(labelText: 'Subtotal'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['impuesto'],
                decoration: const InputDecoration(labelText: 'Impuesto'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['total'],
                decoration: const InputDecoration(labelText: 'Total'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['observaciones'],
                decoration: const InputDecoration(labelText: 'Observaciones'),
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
=======

  Widget _iBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

class _CompraForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final List<Map<String, dynamic>> proveedores;
  final List<Map<String, dynamic>> estadosOrdenCompra;
  final List<Map<String, dynamic>> condicionesPago;
  final VoidCallback onGuardado;

  const _CompraForm({
    this.item,
    required this.proveedores,
    required this.estadosOrdenCompra,
    required this.condicionesPago,
    required this.onGuardado,
  });

  @override
  State<_CompraForm> createState() => __CompraFormState();
>>>>>>> Stashed changes
}

class __CompraFormState extends State<_CompraForm> {
  final _fk = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;

  bool _g = false;
  int? _provIdSeleccionado;
  int? _estadoOcIdSeleccionado;
  int? _condicionPagoIdSeleccionado;

  @override
  void initState() {
    super.initState();

    _c = {
      'num_oc': TextEditingController(),
      'fecha_oc': TextEditingController(),
      'subtotal': TextEditingController(),
      'impuesto': TextEditingController(),
      'total': TextEditingController(),
      'observaciones': TextEditingController(),
    };

    if (widget.item != null) {
      _c['num_oc']!.text =
          '${widget.item!['NUM_OC'] ?? widget.item!['num_oc'] ?? ''}';
      _c['fecha_oc']!.text = _normalizarFecha(
        widget.item!['FECHA_OC'] ?? widget.item!['fecha_oc'],
      );
      _c['subtotal']!.text =
          '${widget.item!['SUBTOTAL'] ?? widget.item!['subtotal'] ?? ''}';
      _c['impuesto']!.text =
          '${widget.item!['IMPUESTO'] ?? widget.item!['impuesto'] ?? ''}';
      _c['total']!.text =
          '${widget.item!['TOTAL'] ?? widget.item!['total'] ?? ''}';
      _c['observaciones']!.text =
          '${widget.item!['OBSERVACIONES'] ?? widget.item!['observaciones'] ?? ''}';

      _provIdSeleccionado = _toInt(
        widget.item!['PROV_ID'] ?? widget.item!['prov_id'],
      );
      _estadoOcIdSeleccionado = _toInt(
        widget.item!['ESTADO_OC_ID'] ?? widget.item!['estado_oc_id'],
      );
      _condicionPagoIdSeleccionado = _toInt(
        widget.item!['CONDICION_PAGO_ID'] ?? widget.item!['condicion_pago_id'],
      );
    }

    _provIdSeleccionado = _validIntDropdownValue(
      _provIdSeleccionado,
      _proveedoresActivos
          .map((e) => _toInt(e['PROV_ID']))
          .whereType<int>()
          .toList(),
    );

    _estadoOcIdSeleccionado = _validIntDropdownValue(
      _estadoOcIdSeleccionado,
      _estadosOrdenCompraActivos
          .map((e) => _toInt(e['ESTADO_OC_ID']))
          .whereType<int>()
          .toList(),
    );

    _condicionPagoIdSeleccionado = _validIntDropdownValue(
      _condicionPagoIdSeleccionado,
      _condicionesPagoActivas
          .map((e) => _toInt(e['CONDICION_PAGO_ID']))
          .whereType<int>()
          .toList(),
    );
  }

  List<Map<String, dynamic>> get _proveedoresActivos => widget.proveedores
      .where((e) => '${e['ESTADO'] ?? ''}'.toUpperCase() == 'ACTIVO')
      .toList();

  List<Map<String, dynamic>> get _estadosOrdenCompraActivos =>
      widget.estadosOrdenCompra
          .where((e) => '${e['ESTADO'] ?? ''}'.toUpperCase() == 'ACTIVO')
          .toList();

  List<Map<String, dynamic>> get _condicionesPagoActivas => widget.condicionesPago
      .where((e) => '${e['ESTADO'] ?? ''}'.toUpperCase() == 'ACTIVO')
      .toList();

  int? _validIntDropdownValue(int? value, List<int> items) {
    if (value == null) return null;
    return items.contains(value) ? value : null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse('$value');
  }

  String _normalizarFecha(dynamic value) {
    if (value == null) return '';
    final raw = value.toString().trim();
    if (raw.isEmpty) return '';
    if (raw.contains('T')) return raw.split('T').first;
    return raw;
  }

  DateTime _parseFechaController(String text) {
    try {
      return DateTime.parse(text);
    } catch (_) {
      return DateTime.now();
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _seleccionarFechaOc() async {
    final inicial = _c['fecha_oc']!.text.trim().isNotEmpty
        ? _parseFechaController(_c['fecha_oc']!.text.trim())
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha de OC',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked != null) {
      setState(() {
        _c['fecha_oc']!.text = _formatDate(picked);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_fk.currentState!.validate()) return;

    setState(() => _g = true);
    try {
      final body = {
        'num_oc': _c['num_oc']!.text.trim(),
        'prov_id': _provIdSeleccionado,
        'estado_oc_id': _estadoOcIdSeleccionado,
        'condicion_pago_id': _condicionPagoIdSeleccionado,
        'fecha_oc': _c['fecha_oc']!.text.trim(),
        'subtotal': _c['subtotal']!.text.trim(),
        'impuesto': _c['impuesto']!.text.trim(),
        'total': _c['total']!.text.trim(),
        'observaciones': _c['observaciones']!.text.trim(),
      };

      final id = widget.item?['ORDEN_COMPRA_ID'] ??
          widget.item?['orden_compra_id'] ??
          widget.item?['ID'] ??
          widget.item?['id'];

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.ordenCompra}${id != null ? '/$id' : ''}',
      );

      final res = id != null
          ? await http.put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
          : await http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            );

      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        widget.onGuardado();
        if (context.mounted) Navigator.pop(context);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['mensaje'] ?? 'Error'),
            backgroundColor: AlpesColors.rojoColonial,
          ),
        );
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
      if (mounted) {
        setState(() => _g = false);
      }
    }
  }

  Widget _campoTexto(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[key],
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Campo requerido';
          return null;
        },
      ),
    );
  }

  Widget _campoNumero(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Campo requerido';
          if (double.tryParse(v.trim()) == null) return 'Ingresa un número válido';
          return null;
        },
      ),
    );
  }

  Widget _campoFechaOc() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c['fecha_oc'],
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Fecha OC',
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        onTap: _seleccionarFechaOc,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Campo requerido';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proveedoresDropdown = _proveedoresActivos
        .map<DropdownMenuItem<int>?>((e) {
          final provId = _toInt(e['PROV_ID']);
          if (provId == null) return null;

          final razonSocial = '${e['RAZON_SOCIAL'] ?? ''}'.trim();
          return DropdownMenuItem<int>(
            value: provId,
            child: Text(
              razonSocial.isEmpty ? 'Proveedor #$provId' : '$razonSocial (#$provId)',
              overflow: TextOverflow.ellipsis,
            ),
          );
        })
        .whereType<DropdownMenuItem<int>>()
        .toList();

    final estadosDropdown = _estadosOrdenCompraActivos
        .map<DropdownMenuItem<int>?>((e) {
          final estadoOcId = _toInt(e['ESTADO_OC_ID']);
          if (estadoOcId == null) return null;

          final codigo = '${e['CODIGO'] ?? ''}'.trim();
          return DropdownMenuItem<int>(
            value: estadoOcId,
            child: Text(
              codigo.isEmpty ? 'Estado #$estadoOcId' : codigo,
              overflow: TextOverflow.ellipsis,
            ),
          );
        })
        .whereType<DropdownMenuItem<int>>()
        .toList();

    final condicionesDropdown = _condicionesPagoActivas
        .map<DropdownMenuItem<int>?>((e) {
          final condicionId = _toInt(e['CONDICION_PAGO_ID']);
          if (condicionId == null) return null;

          final nombre = '${e['NOMBRE'] ?? ''}'.trim();
          return DropdownMenuItem<int>(
            value: condicionId,
            child: Text(
              nombre.isEmpty ? 'Condición #$condicionId' : nombre,
              overflow: TextOverflow.ellipsis,
            ),
          );
        })
        .whereType<DropdownMenuItem<int>>()
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Form(
          key: _fk,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AlpesColors.pergamino,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  widget.item == null ? 'Nueva orden de compra' : 'Editar orden',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AlpesColors.cafeOscuro,
                  ),
                ),
                const SizedBox(height: 16),
                _campoTexto('No. OC', 'num_oc'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<int>(
                    value: _provIdSeleccionado,
                    decoration: const InputDecoration(labelText: 'Proveedor'),
                    items: proveedoresDropdown,
                    onChanged: (value) {
                      setState(() => _provIdSeleccionado = value);
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona un proveedor' : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<int>(
                    value: _estadoOcIdSeleccionado,
                    decoration:
                        const InputDecoration(labelText: 'Estado orden compra'),
                    items: estadosDropdown,
                    onChanged: (value) {
                      setState(() => _estadoOcIdSeleccionado = value);
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona un estado' : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<int>(
                    value: _condicionPagoIdSeleccionado,
                    decoration:
                        const InputDecoration(labelText: 'Condición de pago'),
                    items: condicionesDropdown,
                    onChanged: (value) {
                      setState(() => _condicionPagoIdSeleccionado = value);
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona una condición de pago' : null,
                  ),
                ),
                _campoFechaOc(),
                Row(
                  children: [
                    Expanded(child: _campoNumero('Subtotal', 'subtotal')),
                    const SizedBox(width: 10),
                    Expanded(child: _campoNumero('Impuesto', 'impuesto')),
                  ],
                ),
                _campoNumero('Total', 'total'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _c['observaciones'],
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Observaciones'),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _g ? null : _guardar,
                  child: _g
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