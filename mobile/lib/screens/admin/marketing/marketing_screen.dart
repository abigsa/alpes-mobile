import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
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
        Uri.parse(ApiConfig.baseUrl + ApiConfig.campanaMarketing),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
<<<<<<< Updated upstream
        setState(() {
          _items = List<Map<String, dynamic>>.from(data['data']);
        });
=======
        setState(() => _items = List<Map<String, dynamic>>.from(data['data']));
>>>>>>> Stashed changes
      }
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

<<<<<<< Updated upstream
  Future<void> _eliminar(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Eliminar este registro?'),
=======
  Future<void> _eliminar(dynamic id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Eliminar campaña'),
        content: const Text('¿Estás seguro?'),
>>>>>>> Stashed changes
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
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.campanaMarketing}/$id'),
    );
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
    _cargar();
  }

  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
<<<<<<< Updated upstream
      builder: (_) => _MarketingForm(
        item: item,
        onGuardado: _cargar,
=======
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MarketingForm(item: item, onGuardado: _cargar),
    );
  }

  Color _canalColor(String canal) {
    switch (canal.toLowerCase()) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFC13584);
      case 'email':
        return const Color(0xFF2E7D32);
      case 'tv':
        return const Color(0xFFB26A00);
      case 'redes sociales':
        return const Color(0xFF185FA5);
      default:
        return AlpesColors.nogalMedio;
    }
  }

  String _formatearFecha(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '';
    final raw = value.toString().trim();
    if (raw.contains('T')) return raw.split('T').first;
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final totalPresupuesto = _items.fold<double>(
      0,
      (s, c) =>
          s +
          (double.tryParse('${c['PRESUPUESTO'] ?? c['presupuesto'] ?? 0}') ?? 0),
    );

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('MARKETING'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AlpesColors.cafeOscuro),
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
                          child: _statCard(
                            'Campañas',
                            '${_items.length}',
                            Icons.campaign_rounded,
                            AlpesColors.cafeOscuro,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            'Presupuesto total',
                            'Q ${totalPresupuesto.toStringAsFixed(0)}',
                            Icons.attach_money_rounded,
                            AlpesColors.oroGuatemalteco,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  ..._items.map((c) {
                    final id = c['CAMPANA_MARKETING_ID'] ??
                        c['campana_marketing_id'] ??
                        c['ID'] ??
                        c['id'];
                    final nombre = c['NOMBRE'] ?? c['nombre'] ?? 'Sin nombre';
                    final canal = (c['CANAL'] ?? c['canal'] ?? '-').toString();
                    final presupuesto = double.tryParse(
                          '${c['PRESUPUESTO'] ?? c['presupuesto'] ?? 0}',
                        ) ??
                        0;
                    final inicio = _formatearFecha(c['INICIO'] ?? c['inicio']);
                    final fin = _formatearFecha(c['FIN'] ?? c['fin']);
                    final initial = nombre.toString().isNotEmpty
                        ? nombre.toString()[0].toUpperCase()
                        : 'M';

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
                                color: _canalColor(canal).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _canalColor(canal),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$nombre',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AlpesColors.cafeOscuro,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _canalColor(canal).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          canal,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _canalColor(canal),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.attach_money_rounded,
                                        size: 13,
                                        color: AlpesColors.oroGuatemalteco,
                                      ),
                                      Text(
                                        'Q ${presupuesto.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AlpesColors.nogalMedio,
                                        ),
                                      ),
                                      if (inicio.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 11,
                                          color: AlpesColors.arenaCalida,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$inicio → $fin',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AlpesColors.nogalMedio,
                                          ),
                                        ),
                                      ],
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
                                  () => _abrirForm(c),
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
                  }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AlpesColors.cafeOscuro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva campaña',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        onPressed: () => _abrirForm(),
>>>>>>> Stashed changes
      ),
    );
  }

<<<<<<< Updated upstream
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('MARKETING'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
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

                      final id = item['CAMPANA_MARKETING_ID'] ??
                          item['CAMPANA_ID'] ??
                          item['campana_marketing_id'] ??
                          item['campana_id'] ??
                          item['ID'] ??
                          item['id'] ??
                          0;

                      final nombre = item['NOMBRE'] ??
                          item['nombre'] ??
                          item['TITULO'] ??
                          item['titulo'] ??
                          item['CODIGO'] ??
                          item['codigo'] ??
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
                                onPressed: () => _eliminar(
                                  int.tryParse(id.toString()) ?? 0,
                                ),
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
=======
  Widget _statCard(String label, String value, IconData icon, Color accent) {
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
>>>>>>> Stashed changes
      ),
    );
  }
}

class _MarketingForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;

<<<<<<< Updated upstream
  const _MarketingForm({
    this.item,
    required this.onGuardado,
  });
=======
  const _MarketingForm({this.item, required this.onGuardado});
>>>>>>> Stashed changes

  @override
  State<_MarketingForm> createState() => __MarketingFormState();
}

class __MarketingFormState extends State<_MarketingForm> {
<<<<<<< Updated upstream
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool _guardando = false;
=======
  static const List<String> _canales = [
    'Facebook',
    'Instagram',
    'Email',
    'TV',
    'Redes Sociales',
  ];

  final _fk = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  bool _g = false;
  String? _canalSeleccionado;
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();

<<<<<<< Updated upstream
    controllers['nombre'] = TextEditingController();
    controllers['canal'] = TextEditingController();
    controllers['presupuesto'] = TextEditingController();
    controllers['inicio'] = TextEditingController();
    controllers['fin'] = TextEditingController();

    if (widget.item != null) {
      for (final k in controllers.keys) {
        final upper = k.toUpperCase();
        controllers[k]!.text =
            (widget.item![upper] ?? widget.item![k] ?? '').toString();
      }
=======
    _c = {
      'nombre': TextEditingController(),
      'presupuesto': TextEditingController(),
      'inicio': TextEditingController(),
      'fin': TextEditingController(),
    };

    if (widget.item != null) {
      _c['nombre']!.text =
          '${widget.item!['NOMBRE'] ?? widget.item!['nombre'] ?? ''}';
      _c['presupuesto']!.text =
          '${widget.item!['PRESUPUESTO'] ?? widget.item!['presupuesto'] ?? ''}';
      _c['inicio']!.text =
          _normalizarFecha(widget.item!['INICIO'] ?? widget.item!['inicio']);
      _c['fin']!.text =
          _normalizarFecha(widget.item!['FIN'] ?? widget.item!['fin']);

      final canalActual =
          '${widget.item!['CANAL'] ?? widget.item!['canal'] ?? ''}'.trim();
      _canalSeleccionado = _validStringDropdownValue(canalActual, _canales);
>>>>>>> Stashed changes
    }
  }

  @override
  void dispose() {
<<<<<<< Updated upstream
    controllers['nombre']?.dispose();
    controllers['canal']?.dispose();
    controllers['presupuesto']?.dispose();
    controllers['inicio']?.dispose();
    controllers['fin']?.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final body = <String, dynamic>{
        'nombre': controllers['nombre']!.text,
        'canal': controllers['canal']!.text,
        'presupuesto': controllers['presupuesto']!.text,
        'inicio': controllers['inicio']!.text,
        'fin': controllers['fin']!.text,
      };

      final id = widget.item?['CAMPANA_MARKETING_ID'] ??
          widget.item?['CAMPANA_ID'] ??
          widget.item?['campana_marketing_id'] ??
          widget.item?['campana_id'];

      http.Response res;

      if (id != null) {
        res = await http.put(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.campanaMarketing}/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } else {
        res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.campanaMarketing}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      }
=======
    _c.values.forEach((c) => c.dispose());
    super.dispose();
  }

  String? _validStringDropdownValue(String? value, List<String> items) {
    if (value == null || value.isEmpty) return null;
    return items.contains(value) ? value : null;
  }

  String _normalizarFecha(dynamic value) {
    if (value == null) return '';
    final raw = value.toString().trim();
    if (raw.isEmpty) return '';
    if (raw.contains('T')) return raw.split('T').first;
    return raw;
  }

  DateTime _parseFecha(String text) {
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
        ? _parseFecha(_c[key]!.text.trim())
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

  bool _fechasValidas() {
    final inicioTxt = _c['inicio']!.text.trim();
    final finTxt = _c['fin']!.text.trim();

    if (inicioTxt.isEmpty || finTxt.isEmpty) return true;

    final inicio = _parseFecha(inicioTxt);
    final fin = _parseFecha(finTxt);

    if (fin.isBefore(inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha fin no puede ser menor que la fecha inicio'),
          backgroundColor: AlpesColors.rojoColonial,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _guardar() async {
    if (!_fk.currentState!.validate()) return;
    if (!_fechasValidas()) return;

    setState(() => _g = true);

    try {
      final body = {
        'nombre': _c['nombre']!.text.trim(),
        'canal': _canalSeleccionado,
        'presupuesto': _c['presupuesto']!.text.trim(),
        'inicio': _c['inicio']!.text.trim(),
        'fin': _c['fin']!.text.trim(),
      };

      final id = widget.item?['CAMPANA_MARKETING_ID'] ??
          widget.item?['campana_marketing_id'];

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.campanaMarketing}${id != null ? '/$id' : ''}',
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
<<<<<<< Updated upstream
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
=======
        if (context.mounted) Navigator.pop(context);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['mensaje'] ?? 'Error'),
            backgroundColor: AlpesColors.rojoColonial,
          ),
        );
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
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
=======
      setState(() => _g = false);
    }
  }

  Widget _f(
    String label,
    String key, {
    TextInputType? type,
    bool req = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[key],
        keyboardType: type,
        decoration: InputDecoration(labelText: label),
        validator: req
            ? (v) => v == null || v.trim().isEmpty ? 'Requerido' : null
            : null,
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
          if (v == null || v.trim().isEmpty) return 'Requerido';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                Text(
                  widget.item == null ? 'Nuevo marketing' : 'Editar marketing',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: controllers['nombre'],
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controllers['canal'],
                  decoration: const InputDecoration(
                    labelText: 'Canal',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controllers['presupuesto'],
                  decoration: const InputDecoration(
                    labelText: 'Presupuesto',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controllers['inicio'],
                  decoration: const InputDecoration(
                    labelText: 'Inicio',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controllers['fin'],
                  decoration: const InputDecoration(
                    labelText: 'Fin',
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
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
                  widget.item == null ? 'Nueva campaña' : 'Editar campaña',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AlpesColors.cafeOscuro,
                  ),
                ),
                const SizedBox(height: 16),
                _f('Nombre de campaña', 'nombre', req: true),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: _canalSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Canal',
                    ),
                    items: _canales
                        .map(
                          (canal) => DropdownMenuItem<String>(
                            value: canal,
                            child: Text(canal),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _canalSeleccionado = value);
                    },
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                ),
                _f(
                  'Presupuesto (Q)',
                  'presupuesto',
                  type: const TextInputType.numberWithOptions(decimal: true),
                ),
                Row(
                  children: [
                    Expanded(child: _campoFecha('Fecha inicio', 'inicio')),
                    const SizedBox(width: 10),
                    Expanded(child: _campoFecha('Fecha fin', 'fin')),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _g ? null : _guardar,
                  child: _g
>>>>>>> Stashed changes
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