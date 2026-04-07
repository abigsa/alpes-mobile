import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class NominaScreen extends StatefulWidget {
  const NominaScreen({super.key});

  @override
  State<NominaScreen> createState() => _NominaScreenState();
}

class _NominaScreenState extends State<NominaScreen> {
<<<<<<< Updated upstream
  List<Map<String,dynamic>> _items = [];
  bool _loading = true;

=======
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _empleados = [];
  bool _loading = true;

  double get _totalBruto => _items.fold(
        0,
        (s, n) =>
            s +
            (double.tryParse('${n['MONTO_BRUTO'] ?? n['monto_bruto'] ?? 0}') ??
                0),
      );

  double get _totalNeto => _items.fold(
        0,
        (s, n) =>
            s +
            (double.tryParse('${n['MONTO_NETO'] ?? n['monto_neto'] ?? 0}') ??
                0),
      );

>>>>>>> Stashed changes
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
<<<<<<< Updated upstream
      final res = await http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.nomina));
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
        http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.nomina)),
        http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.empleados)),
      ]);

      final nominasData = jsonDecode(responses[0].body);
      final empleadosData = jsonDecode(responses[1].body);

      if (!mounted) return;

      setState(() {
        _items = nominasData['ok'] == true
            ? List<Map<String, dynamic>>.from(nominasData['data'])
            : [];

        _empleados = empleadosData['ok'] == true
            ? List<Map<String, dynamic>>.from(empleadosData['data'])
            : [];
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _eliminar(dynamic id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Eliminar nómina'),
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
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.nomina}/$id'),
    );
    _cargar();
  }

<<<<<<< Updated upstream
  void _abrirForm([Map<String,dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NominaForm(item: item, onGuardado: _cargar),
    );
  }

=======
  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NominaForm(
        item: item,
        empleados: _empleados,
        onGuardado: _cargar,
      ),
    );
  }

  String _formatearFecha(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    final raw = value.toString();
    if (raw.contains('T')) return raw.split('T').first;
    return raw;
  }

  String _nombreEmpleado(dynamic empId) {
    Map<String, dynamic>? empleado;
    for (final e in _empleados) {
      if ('${e['EMP_ID']}' == '$empId') {
        empleado = e;
        break;
      }
    }

    if (empleado == null) return 'Empleado #$empId';

    final nombres = '${empleado['NOMBRES'] ?? ''}'.trim();
    final apellidos = '${empleado['APELLIDOS'] ?? ''}'.trim();
    final nombreCompleto = '$nombres $apellidos'.trim();

    return nombreCompleto.isEmpty
        ? 'Empleado #$empId'
        : '$nombreCompleto (#$empId)';
  }

  Color _colorEstado(String e) => e.toLowerCase() == 'pagado'
      ? const Color(0xFF3B6D11)
      : e.toLowerCase() == 'pendiente'
          ? const Color(0xFF854F0B)
          : AlpesColors.nogalMedio;

  Color _bgEstado(String e) => e.toLowerCase() == 'pagado'
      ? const Color(0xFFEAF3DE)
      : e.toLowerCase() == 'pendiente'
          ? const Color(0xFFFAEEDA)
          : AlpesColors.pergamino;

>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
<<<<<<< Updated upstream
        title: const Text('NOMINA'),
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
        title: const Text('NÓMINA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AlpesColors.cafeOscuro,
              ),
            )
          : RefreshIndicator(
              color: AlpesColors.cafeOscuro,
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  if (_items.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _totalCard(
                            'Total bruto',
                            'Q ${_totalBruto.toStringAsFixed(2)}',
                            Icons.account_balance_rounded,
                            AlpesColors.cafeOscuro,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _totalCard(
                            'Total neto',
                            'Q ${_totalNeto.toStringAsFixed(2)}',
                            Icons.payments_rounded,
                            AlpesColors.verdeSelva,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  ..._items.map((n) {
                    final id =
                        n['NOMINA_ID'] ?? n['nomina_id'] ?? n['ID'] ?? n['id'];
                    final empId = n['EMP_ID'] ?? n['emp_id'] ?? '-';
                    final bruto = double.tryParse(
                          '${n['MONTO_BRUTO'] ?? n['monto_bruto'] ?? 0}',
                        ) ??
                        0;
                    final neto = double.tryParse(
                          '${n['MONTO_NETO'] ?? n['monto_neto'] ?? 0}',
                        ) ??
                        0;
                    final estado = (n['ESTADO'] ?? n['estado'] ?? '-').toString();
                    final inicio = _formatearFecha(
                      n['PERIODO_INICIO'] ?? n['periodo_inicio'],
                    );
                    final fin = _formatearFecha(
                      n['PERIODO_FIN'] ?? n['periodo_fin'],
                    );

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
                                color: AlpesColors.oroGuatemalteco.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.payments_rounded,
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
                                    _nombreEmpleado(empId),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AlpesColors.cafeOscuro,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$inicio → $fin',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AlpesColors.nogalMedio,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Bruto: Q ${bruto.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AlpesColors.nogalMedio,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Neto: Q ${neto.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AlpesColors.cafeOscuro,
                                        ),
                                      ),
                                    ],
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
                                      () => _abrirForm(n),
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
                  }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AlpesColors.cafeOscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva nómina',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
>>>>>>> Stashed changes
        onPressed: () => _abrirForm(),
      ),
    );
  }
<<<<<<< Updated upstream
}

class _NominaForm extends StatefulWidget {
  final Map<String,dynamic>? item;
  final VoidCallback onGuardado;
  const _NominaForm({this.item, required this.onGuardado});
=======

  Widget _totalCard(String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AlpesColors.cafeOscuro,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AlpesColors.nogalMedio,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

class _NominaForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final List<Map<String, dynamic>> empleados;
  final VoidCallback onGuardado;

  const _NominaForm({
    this.item,
    required this.empleados,
    required this.onGuardado,
  });

>>>>>>> Stashed changes
  @override
  State<_NominaForm> createState() => __NominaFormState();
}

class __NominaFormState extends State<_NominaForm> {
<<<<<<< Updated upstream
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool _guardando = false;
=======
  static const List<String> _estadosNomina = [
    'ACTIVO',
    'PENDIENTE',
    'PAGADO',
  ];

  final _fk = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;

  bool _g = false;
  int? _empIdSeleccionado;
  String? _estadoSeleccionado;
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
    controllers['emp_id'] = TextEditingController();
    controllers['periodo_inicio'] = TextEditingController();
    controllers['periodo_fin'] = TextEditingController();
    controllers['monto_bruto'] = TextEditingController();
    controllers['monto_neto'] = TextEditingController();
    controllers['fecha_pago'] = TextEditingController();
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
    controllers['emp_id']?.dispose();
    controllers['periodo_inicio']?.dispose();
    controllers['periodo_fin']?.dispose();
    controllers['monto_bruto']?.dispose();
    controllers['monto_neto']?.dispose();
    controllers['fecha_pago']?.dispose();
    controllers['estado']?.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = {
      'emp_id': controllers['emp_id']!.text,
      'periodo_inicio': controllers['periodo_inicio']!.text,
      'periodo_fin': controllers['periodo_fin']!.text,
      'monto_bruto': controllers['monto_bruto']!.text,
      'monto_neto': controllers['monto_neto']!.text,
      'fecha_pago': controllers['fecha_pago']!.text,
      'estado': controllers['estado']!.text,
      };
      final idKey = widget.item?.keys.firstWhere((k) => k.toLowerCase().contains('id'), orElse: () => '') ?? '';
      final id = idKey.isNotEmpty ? widget.item![idKey] : null;
      http.Response res;
      if (id != null) {
        body[idKey.toLowerCase()] = id;
        res = await http.put(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.nomina}/$id'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      } else {
        res = await http.post(Uri.parse(ApiConfig.baseUrl + ApiConfig.nomina),
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
=======

    _c = {
      'periodo_inicio': TextEditingController(),
      'periodo_fin': TextEditingController(),
      'monto_bruto': TextEditingController(),
      'monto_neto': TextEditingController(),
      'fecha_pago': TextEditingController(),
    };

    if (widget.item != null) {
      _empIdSeleccionado = _toInt(
        widget.item!['EMP_ID'] ?? widget.item!['emp_id'],
      );

      _estadoSeleccionado = _validStringDropdownValue(
        (widget.item!['ESTADO'] ?? widget.item!['estado'])?.toString(),
        _estadosNomina,
      );

      _c['periodo_inicio']!.text = _normalizarFecha(
        widget.item!['PERIODO_INICIO'] ?? widget.item!['periodo_inicio'],
      );
      _c['periodo_fin']!.text = _normalizarFecha(
        widget.item!['PERIODO_FIN'] ?? widget.item!['periodo_fin'],
      );
      _c['fecha_pago']!.text = _normalizarFecha(
        widget.item!['FECHA_PAGO'] ?? widget.item!['fecha_pago'],
      );
      _c['monto_bruto']!.text =
          '${widget.item!['MONTO_BRUTO'] ?? widget.item!['monto_bruto'] ?? ''}';
      _c['monto_neto']!.text =
          '${widget.item!['MONTO_NETO'] ?? widget.item!['monto_neto'] ?? ''}';
    }

    _empIdSeleccionado = _validIntDropdownValue(
      _empIdSeleccionado,
      _empleadosActivos
          .map((e) => _toInt(e['EMP_ID']))
          .whereType<int>()
          .toList(),
    );
  }

  List<Map<String, dynamic>> get _empleadosActivos => widget.empleados
      .where((e) => '${e['ESTADO'] ?? ''}'.toUpperCase() == 'ACTIVO')
      .toList();

  int? _validIntDropdownValue(int? value, List<int> items) {
    if (value == null) return null;
    return items.contains(value) ? value : null;
  }

  String? _validStringDropdownValue(String? value, List<String> items) {
    if (value == null || value.isEmpty) return null;
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

  Future<void> _seleccionarFecha(String key) async {
    final inicial = _c[key]!.text.trim().isNotEmpty
        ? _parseFechaController(_c[key]!.text.trim())
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _c[key]!.text = _formatDate(picked);
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_fk.currentState!.validate()) return;

    setState(() => _g = true);

    try {
      final body = {
        'emp_id': _empIdSeleccionado,
        'periodo_inicio': _c['periodo_inicio']!.text.trim(),
        'periodo_fin': _c['periodo_fin']!.text.trim(),
        'monto_bruto': _c['monto_bruto']!.text.trim(),
        'monto_neto': _c['monto_neto']!.text.trim(),
        'fecha_pago': _c['fecha_pago']!.text.trim(),
        'estado': _estadoSeleccionado,
      };

      final id = widget.item?['NOMINA_ID'] ??
          widget.item?['nomina_id'] ??
          widget.item?['ID'] ??
          widget.item?['id'];

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.nomina}${id != null ? '/$id' : ''}',
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
      if (mounted) {
        setState(() => _g = false);
      }
    }
  }

  Widget _campoMonto(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Campo requerido';
          if (double.tryParse(v.trim()) == null) {
            return 'Ingresa un número válido';
          }
          return null;
        },
      ),
    );
  }

  Widget _campoFecha(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[key],
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        onTap: () => _seleccionarFecha(key),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Campo requerido';
          return null;
        },
      ),
    );
>>>>>>> Stashed changes
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
=======
    final empleadosDropdown = _empleadosActivos
        .map<DropdownMenuItem<int>?>((e) {
          final empId = _toInt(e['EMP_ID']);
          if (empId == null) return null;

          final nombres = '${e['NOMBRES'] ?? ''}'.trim();
          final apellidos = '${e['APELLIDOS'] ?? ''}'.trim();
          final nombre = '$nombres $apellidos'.trim();

          return DropdownMenuItem<int>(
            value: empId,
            child: Text(
              nombre.isEmpty ? 'Empleado #$empId' : '$nombre (#$empId)',
              overflow: TextOverflow.ellipsis,
            ),
          );
        })
        .whereType<DropdownMenuItem<int>>()
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Form(
          key: _fk,
>>>>>>> Stashed changes
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
<<<<<<< Updated upstream
                Text(widget.item == null ? 'Nuevo nomina' : 'Editar nomina',
                  style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
              TextFormField(
                controller: controllers['emp_id'],
                decoration: const InputDecoration(labelText: 'Emp Id'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['periodo_inicio'],
                decoration: const InputDecoration(labelText: 'Periodo Inicio'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['periodo_fin'],
                decoration: const InputDecoration(labelText: 'Periodo Fin'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['monto_bruto'],
                decoration: const InputDecoration(labelText: 'Monto Bruto'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['monto_neto'],
                decoration: const InputDecoration(labelText: 'Monto Neto'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controllers['fecha_pago'],
                decoration: const InputDecoration(labelText: 'Fecha Pago'),
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
                  widget.item == null ? 'Nueva nómina' : 'Editar nómina',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AlpesColors.cafeOscuro,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<int>(
                    value: _empIdSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Empleado',
                    ),
                    items: empleadosDropdown,
                    onChanged: (value) {
                      setState(() => _empIdSeleccionado = value);
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona un empleado' : null,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _campoFecha('Período inicio', 'periodo_inicio'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _campoFecha('Período fin', 'periodo_fin'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _campoMonto('Monto bruto', 'monto_bruto'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _campoMonto('Monto neto', 'monto_neto'),
                    ),
                  ],
                ),
                _campoFecha('Fecha de pago', 'fecha_pago'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: _estadoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                    ),
                    items: _estadosNomina
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
                    validator: (value) => value == null || value.isEmpty
                        ? 'Selecciona un estado'
                        : null,
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
>>>>>>> Stashed changes
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
<<<<<<< Updated upstream
}
=======
}
>>>>>>> Stashed changes
