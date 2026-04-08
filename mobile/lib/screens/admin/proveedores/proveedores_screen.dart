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
  List<Map<String, dynamic>> _filtrados = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.proveedores),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        _items = List<Map<String, dynamic>>.from(data['data']);
        _filtrar();
      }
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados = q.isEmpty
          ? List.from(_items)
          : _items.where((p) {
              final rs = (p['RAZON_SOCIAL'] ?? p['razon_social'] ?? '')
                  .toString()
                  .toLowerCase();
              final nit =
                  (p['NIT'] ?? p['nit'] ?? '').toString().toLowerCase();
              return rs.contains(q) || nit.contains(q);
            }).toList();
    });
  }

  Future<void> _eliminar(dynamic id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Eliminar proveedor'),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProveedoresForm(
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
        item['PROV_ID'] ?? item['prov_id'] ?? item['ID'] ?? item['id'];

    final int id = int.tryParse('${idValue ?? 0}') ?? 0;

    if (id <= 0) {
      _abrirForm(item);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.proveedores}/$id'),
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
        title: const Text('PROVEEDORES'),
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
                hintText: 'Buscar proveedor…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filtrar();
                        },
                      )
                    : null,
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
          if (!_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Text(
                    '${_filtrados.length} proveedor${_filtrados.length != 1 ? 'es' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AlpesColors.nogalMedio,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                              Icons.local_shipping_outlined,
                              size: 64,
                              color: AlpesColors.arenaCalida.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Sin proveedores',
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
                            final p = _filtrados[i];
                            final id =
                                p['PROV_ID'] ?? p['prov_id'] ?? p['ID'] ?? p['id'];
                            final rs = p['RAZON_SOCIAL'] ??
                                p['razon_social'] ??
                                'Sin nombre';
                            final nit = p['NIT'] ?? p['nit'] ?? '';
                            final tel = p['TELEFONO'] ?? p['telefono'] ?? '';
                            final email = p['EMAIL'] ?? p['email'] ?? '';
                            final ciudad = p['CIUDAD'] ?? p['ciudad'] ?? '';
                            final initial =
                                rs.toString().isNotEmpty ? rs.toString()[0].toUpperCase() : 'P';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AlpesColors.pergamino),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AlpesColors.cafeOscuro.withOpacity(0.05),
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
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: AlpesColors.nogalMedio
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AlpesColors.nogalMedio,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rs.toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: AlpesColors.cafeOscuro,
                                            ),
                                          ),
                                          if (nit.toString().isNotEmpty)
                                            Text(
                                              'NIT: $nit',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AlpesColors.nogalMedio,
                                              ),
                                            ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              if (tel.toString().isNotEmpty) ...[
                                                const Icon(
                                                  Icons.phone_outlined,
                                                  size: 11,
                                                  color: AlpesColors.arenaCalida,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  tel.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AlpesColors.nogalMedio,
                                                  ),
                                                ),
                                              ],
                                              if (ciudad.toString().isNotEmpty) ...[
                                                if (tel.toString().isNotEmpty)
                                                  const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.location_on_outlined,
                                                  size: 11,
                                                  color: AlpesColors.arenaCalida,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  ciudad.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AlpesColors.nogalMedio,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (email.toString().isNotEmpty)
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.email_outlined,
                                                  size: 11,
                                                  color: AlpesColors.arenaCalida,
                                                ),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    email.toString(),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AlpesColors.nogalMedio,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        _iBtn(
                                          Icons.edit_outlined,
                                          AlpesColors.nogalMedio,
                                          () => _abrirFormConDetalle(p),
                                        ),
                                        const SizedBox(height: 4),
                                        _iBtn(
                                          Icons.delete_outline,
                                          AlpesColors.rojoColonial,
                                          () => _eliminar(id),
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
          'Nuevo proveedor',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () => _abrirForm(),
      ),
    );
  }

  Widget _iBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );
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
  final _fk = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  bool _g = false;

  @override
  void initState() {
    super.initState();
    _c = {
      'razon_social': TextEditingController(),
      'nit': TextEditingController(),
      'email': TextEditingController(),
      'telefono': TextEditingController(),
      'direccion': TextEditingController(),
      'ciudad': TextEditingController(),
      'pais': TextEditingController(),
    };
    if (widget.item != null) {
      for (final k in _c.keys) {
        _c[k]!.text =
            '${widget.item![k.toUpperCase()] ?? widget.item![k] ?? ''}';
      }
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
      final body = _c.map((k, v) => MapEntry(k, v.text.trim()));
      final idKey = widget.item?.keys.firstWhere(
            (k) => k.toLowerCase() == 'prov_id',
            orElse: () => '',
          ) ??
          '';
      final id = idKey.isNotEmpty ? widget.item![idKey] : null;

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.proveedores}${id != null ? '/$id' : ''}',
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
      setState(() => _g = false);
    }
  }

  Widget _f(
    String label,
    String key, {
    TextInputType? type,
    bool req = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _c[key],
          keyboardType: type,
          decoration: InputDecoration(labelText: label),
          validator: req
              ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
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
                  widget.item == null ? 'Nuevo proveedor' : 'Editar proveedor',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AlpesColors.cafeOscuro,
                  ),
                ),
                const SizedBox(height: 16),
                _f('Razón social', 'razon_social', req: true),
                _f('NIT', 'nit'),
                _f('Email', 'email', type: TextInputType.emailAddress),
                _f('Teléfono', 'telefono', type: TextInputType.phone),
                _f('Dirección', 'direccion'),
                Row(
                  children: [
                    Expanded(child: _f('Ciudad', 'ciudad')),
                    const SizedBox(width: 10),
                    Expanded(child: _f('País', 'pais')),
                  ],
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