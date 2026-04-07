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
  void initState() {
    super.initState();
    _cargar();
  }

<<<<<<< Updated upstream
=======
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

>>>>>>> Stashed changes
  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.empleados),
      );
      final data = jsonDecode(res.body);
<<<<<<< Updated upstream
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
          : _items.where((e) {
              final nombre =
                  '${e['NOMBRES'] ?? e['nombres'] ?? ''} ${e['APELLIDOS'] ?? e['apellidos'] ?? ''}'
                      .toLowerCase();
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
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.empleados}/$id'),
    );
    _cargar();
  }

  void _abrirForm([Map<String,dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
<<<<<<< Updated upstream
      builder: (_) => _EmpleadosForm(item: item, onGuardado: _cargar),
    );
  }

=======
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EmpleadosForm(
        item: item,
        onGuardado: _cargar,
      ),
    );
  }

  Color _colorEstado(String estado) => estado.toLowerCase() == 'activo'
      ? const Color(0xFF3B6D11)
      : AlpesColors.rojoColonial;

  Color _bgEstado(String estado) => estado.toLowerCase() == 'activo'
      ? const Color(0xFFEAF3DE)
      : const Color(0xFFFCEBEB);

>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('EMPLEADOS'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _abrirForm())],
      ),
<<<<<<< Updated upstream
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
=======
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
                    '${_filtrados.length} empleado${_filtrados.length != 1 ? 's' : ''}',
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
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AlpesColors.cafeOscuro,
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
                          itemCount: _filtrados.length,
                          itemBuilder: (_, i) => _buildCard(_filtrados[i]),
>>>>>>> Stashed changes
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AlpesColors.cafeOscuro,
<<<<<<< Updated upstream
        child: const Icon(Icons.add, color: Colors.white),
=======
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Nuevo empleado',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
>>>>>>> Stashed changes
        onPressed: () => _abrirForm(),
      ),
    );
  }
<<<<<<< Updated upstream
=======

  Widget _buildCard(Map<String, dynamic> e) {
    final id = e['EMP_ID'] ?? e['emp_id'] ?? e['ID'] ?? e['id'];
    final nombres = e['NOMBRES'] ?? e['nombres'] ?? '';
    final apellidos = e['APELLIDOS'] ?? e['apellidos'] ?? '';
    final email = e['EMAIL'] ?? e['email'] ?? '';
    final salario =
        double.tryParse('${e['SALARIO_BASE'] ?? e['salario_base'] ?? 0}') ?? 0;
    final estado = (e['ESTADO'] ?? e['estado'] ?? 'Activo').toString();
    final fullName = '$nombres $apellidos'.trim();
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'E';

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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AlpesColors.verdeSelva.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AlpesColors.verdeSelva,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fullName.isNotEmpty ? fullName : 'Sin nombre',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AlpesColors.cafeOscuro,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (email.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 11,
                          color: AlpesColors.arenaCalida,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AlpesColors.nogalMedio,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money_rounded,
                        size: 13,
                        color: AlpesColors.oroGuatemalteco,
                      ),
                      Text(
                        'Q ${salario.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AlpesColors.nogalMedio,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _iconBtn(
                  Icons.edit_outlined,
                  AlpesColors.nogalMedio,
                  () => _abrirForm(e),
                ),
                const SizedBox(height: 4),
                _iconBtn(
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
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
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

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.badge_outlined,
              size: 64,
              color: AlpesColors.arenaCalida.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sin empleados',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AlpesColors.nogalMedio,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Agregar empleado'),
              onPressed: () => _abrirForm(),
            ),
          ],
        ),
      );
>>>>>>> Stashed changes
}

class _EmpleadosForm extends StatefulWidget {
  final Map<String,dynamic>? item;
  final VoidCallback onGuardado;

  const _EmpleadosForm({
    this.item,
    required this.onGuardado,
  });

  @override
  State<_EmpleadosForm> createState() => __EmpleadosFormState();
}

class __EmpleadosFormState extends State<_EmpleadosForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool _guardando = false;

  List<Map<String, dynamic>> _departamentos = [];
  List<Map<String, dynamic>> _cargos = [];
  List<Map<String, dynamic>> _rolesEmpleado = [];
  bool _loadingCatalogos = true;

  int? _deptoId;
  int? _cargoId;
  int? _rolEmpleadoId;
  String? _estadoSeleccionado;

  final List<String> _estados = ['ACTIVO', 'INACTIVO'];

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
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
=======

    _c = {
      'nombres': TextEditingController(),
      'apellidos': TextEditingController(),
      'email': TextEditingController(),
      'telefono': TextEditingController(),
      'fecha_ingreso': TextEditingController(),
      'salario_base': TextEditingController(),
    };

    if (widget.item != null) {
      for (final k in _c.keys) {
        _c[k]!.text =
            '${widget.item![k.toUpperCase()] ?? widget.item![k] ?? ''}';
      }

      final fechaRaw =
          widget.item?['FECHA_INGRESO'] ?? widget.item?['fecha_ingreso'];

      if (fechaRaw != null && fechaRaw.toString().isNotEmpty) {
        _c['fecha_ingreso']!.text = fechaRaw.toString().split('T').first;
      }

      _deptoId = _toInt(
        widget.item!['DEPTO_ID'] ?? widget.item!['depto_id'],
      );
      _cargoId = _toInt(
        widget.item!['CARGO_ID'] ?? widget.item!['cargo_id'],
      );
      _rolEmpleadoId = _toInt(
        widget.item!['ROL_EMPLEADO_ID'] ?? widget.item!['rol_empleado_id'],
      );
      _estadoSeleccionado =
          (widget.item!['ESTADO'] ?? widget.item!['estado'] ?? '').toString();
      if (!_estados.contains(_estadoSeleccionado)) {
        _estadoSeleccionado = null;
      }
    } else {
      _estadoSeleccionado = 'ACTIVO';
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

  Future<void> _seleccionarFechaIngreso() async {
    DateTime initialDate;

    final actual = _c['fecha_ingreso']!.text.trim();
    if (actual.isNotEmpty) {
      try {
        initialDate = DateTime.parse(actual);
      } catch (_) {
        initialDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha de ingreso',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked != null) {
      final yyyy = picked.year.toString().padLeft(4, '0');
      final mm = picked.month.toString().padLeft(2, '0');
      final dd = picked.day.toString().padLeft(2, '0');
      _c['fecha_ingreso']!.text = '$yyyy-$mm-$dd';
      setState(() {});
    }
  }

  Future<void> _cargarCatalogos() async {
    setState(() => _loadingCatalogos = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.departamentos}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cargos}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.rolEmpleado}')),
      ]);

      final deptosData = jsonDecode(responses[0].body);
      final cargosData = jsonDecode(responses[1].body);
      final rolesData = jsonDecode(responses[2].body);

      if (deptosData['ok'] == true) {
        _departamentos = List<Map<String, dynamic>>.from(deptosData['data']);
      }

      if (cargosData['ok'] == true) {
        _cargos = List<Map<String, dynamic>>.from(cargosData['data']);
      }

      if (rolesData['ok'] == true) {
        _rolesEmpleado = List<Map<String, dynamic>>.from(rolesData['data']);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loadingCatalogos = false);
>>>>>>> Stashed changes
      }
    }
  }

  @override
  void dispose() {
<<<<<<< Updated upstream
    controllers['depto_id']?.dispose();
    controllers['cargo_id']?.dispose();
    controllers['rol_empleado_id']?.dispose();
    controllers['nombres']?.dispose();
    controllers['apellidos']?.dispose();
    controllers['email']?.dispose();
    controllers['telefono']?.dispose();
    controllers['salario_base']?.dispose();
    controllers['estado']?.dispose();
=======
    for (final c in _c.values) {
      c.dispose();
    }
>>>>>>> Stashed changes
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deptoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un departamento')),
      );
      return;
    }

    if (_cargoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un cargo')),
      );
      return;
    }

    if (_rolEmpleadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un rol de empleado')),
      );
      return;
    }

    if (_estadoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un estado')),
      );
      return;
    }

    if (_c['fecha_ingreso']!.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese la fecha de ingreso')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
<<<<<<< Updated upstream
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
        res = await http.put(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.empleados}/$id'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      } else {
        res = await http.post(Uri.parse(ApiConfig.baseUrl + ApiConfig.empleados),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      }
=======
      final body = <String, dynamic>{
        'depto_id': _deptoId,
        'cargo_id': _cargoId,
        'rol_empleado_id': _rolEmpleadoId,
        'nombres': _c['nombres']!.text.trim(),
        'apellidos': _c['apellidos']!.text.trim(),
        'email': _c['email']!.text.trim(),
        'telefono': _c['telefono']!.text.trim(),
        'fecha_ingreso': _c['fecha_ingreso']!.text.trim(),
        'salario_base':
            double.tryParse(_c['salario_base']!.text.trim()) ?? 0,
        'estado': _estadoSeleccionado,
      };

      final idKey = widget.item?.keys.firstWhere(
            (k) => k.toLowerCase() == 'emp_id',
            orElse: () => '',
          ) ??
          '';

      final id = idKey.isNotEmpty ? widget.item![idKey] : null;

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.empleados}${id != null ? '/$id' : ''}',
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

>>>>>>> Stashed changes
      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        widget.onGuardado();
        if (context.mounted) Navigator.pop(context);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< Updated upstream
          SnackBar(content: Text(data['mensaje'] ?? 'Error'), backgroundColor: AlpesColors.rojoColonial));
=======
            SnackBar(
              content: Text(data['mensaje'] ?? 'Error'),
              backgroundColor: AlpesColors.rojoColonial,
            ),
          );
>>>>>>> Stashed changes
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< Updated upstream
        const SnackBar(content: Text('Error: \$e'), backgroundColor: AlpesColors.rojoColonial));
      }
    } finally { setState(() => _guardando = false); }
  }

=======
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
    TextInputType? type,
    bool required = false,
    String? hint,
  }) {
    return Padding(
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
  }

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
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
=======
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
                  widget.item == null ? 'Nuevo empleado' : 'Editar empleado',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AlpesColors.cafeOscuro,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _campo('Nombres', 'nombres', required: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _campo('Apellidos', 'apellidos', required: true),
                    ),
                  ],
                ),
                _campo('Email', 'email', type: TextInputType.emailAddress),
                _campo('Teléfono', 'telefono', type: TextInputType.phone),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _c['fecha_ingreso'],
                    readOnly: true,
                    onTap: _seleccionarFechaIngreso,
                    decoration: const InputDecoration(
                      labelText: 'Fecha ingreso',
                      hintText: 'Seleccione una fecha',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                ),
                _campo(
                  'Salario base',
                  'salario_base',
                  type: TextInputType.number,
                ),
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
                                _deptoId,
                                _departamentos,
                                'DEPTO_ID',
                                'depto_id',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Departamento',
                              ),
                              items: _departamentos
                                  .map((depto) {
                                    final id = _toInt(
                                      depto['DEPTO_ID'] ?? depto['depto_id'],
                                    );
                                    final nombre =
                                        (depto['NOMBRE'] ?? depto['nombre'] ?? '')
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
                                setState(() => _deptoId = value);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Seleccione un departamento';
                                }
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DropdownButtonFormField<int>(
                              value: _validDropdownValue(
                                _cargoId,
                                _cargos,
                                'CARGO_ID',
                                'cargo_id',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Cargo',
                              ),
                              items: _cargos
                                  .map((cargo) {
                                    final id = _toInt(
                                      cargo['CARGO_ID'] ?? cargo['cargo_id'],
                                    );
                                    final nombre =
                                        (cargo['NOMBRE'] ?? cargo['nombre'] ?? '')
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
                                setState(() => _cargoId = value);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Seleccione un cargo';
                                }
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DropdownButtonFormField<int>(
                              value: _validDropdownValue(
                                _rolEmpleadoId,
                                _rolesEmpleado,
                                'ROL_EMPLEADO_ID',
                                'rol_empleado_id',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Rol de empleado',
                              ),
                              items: _rolesEmpleado
                                  .map((rol) {
                                    final id = _toInt(
                                      rol['ROL_EMPLEADO_ID'] ??
                                          rol['rol_empleado_id'],
                                    );
                                    final nombre =
                                        (rol['NOMBRE'] ?? rol['nombre'] ?? '')
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
                                setState(() => _rolEmpleadoId = value);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Seleccione un rol de empleado';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: _estadoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                    ),
                    items: _estados
                        .map(
                          (estado) => DropdownMenuItem<String>(
                            value: estado,
                            child: Text(estado),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _estadoSeleccionado = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Seleccione un estado';
                      }
                      return null;
                    },
                  ),
                ),
>>>>>>> Stashed changes
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
<<<<<<< Updated upstream
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('GUARDAR'),
=======
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('GUARDAR'),
>>>>>>> Stashed changes
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}