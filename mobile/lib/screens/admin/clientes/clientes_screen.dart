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

class _ClientesScreenState extends State<ClientesScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    _fadeCtrl.reset();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cliente}'),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        _items = List<Map<String, dynamic>>.from(data['data']);
        _filtrar();
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _fadeCtrl.forward();
      }
    }
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados = q.isEmpty
          ? List.from(_items)
          : _items.where((c) {
              final nombre =
                  '${c['NOMBRES'] ?? c['nombres'] ?? ''} ${c['APELLIDOS'] ?? c['apellidos'] ?? ''}'
                      .toLowerCase();
              final email =
                  (c['EMAIL'] ?? c['email'] ?? '').toString().toLowerCase();
              final tel = (c['TEL_CELULAR'] ??
                      c['tel_celular'] ??
                      c['TELEFONO'] ??
                      c['telefono'] ??
                      '')
                  .toString()
                  .toLowerCase();
              final pais =
                  (c['PAIS'] ?? c['pais'] ?? '').toString().toLowerCase();
              final ciudad =
                  (c['CIUDAD'] ?? c['ciudad'] ?? '').toString().toLowerCase();
              final departamento =
                  (c['DEPARTAMENTO'] ?? c['departamento'] ?? '')
                      .toString()
                      .toLowerCase();

              return nombre.contains(q) ||
                  email.contains(q) ||
                  tel.contains(q) ||
                  pais.contains(q) ||
                  ciudad.contains(q) ||
                  departamento.contains(q);
            }).toList();
    });
  }

  bool _isMissingValue(dynamic value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    return text.isEmpty ||
        text == 'pendiente de completar' ||
        text == 'pendiente' ||
        text == 'sin completar' ||
        text == 'n/a' ||
        text == 'na' ||
        text == 'null';
  }

  int get _totalActivos => _items
      .where((c) => (c['ACTIVO'] ?? c['activo'] ?? 1).toString() == '1')
      .length;

  int get _totalInactivos => _items.length - _totalActivos;

  bool _clienteTienePendientes(Map<String, dynamic> c) {
    final campos = [
      c['TIPO_DOCUMENTO'] ?? c['tipo_documento'],
      c['NUM_DOCUMENTO'] ?? c['num_documento'],
      c['NOMBRES'] ?? c['nombres'] ?? c['NOMBRE'] ?? c['nombre'],
      c['APELLIDOS'] ?? c['apellidos'],
      c['EMAIL'] ?? c['email'] ?? c['CORREO'] ?? c['correo'],
      c['TEL_CELULAR'] ??
          c['tel_celular'] ??
          c['TELEFONO'] ??
          c['telefono'] ??
          c['CELULAR'] ??
          c['celular'],
      c['PAIS'] ?? c['pais'],
      c['DEPARTAMENTO'] ?? c['departamento'],
      c['CIUDAD'] ?? c['ciudad'],
      c['DIRECCION'] ?? c['direccion'],
    ];

    return campos.any(_isMissingValue);
  }

  List<Map<String, dynamic>> get _clientesPendientes =>
      _items.where(_clienteTienePendientes).toList();

  List<String> _faltantesCliente(Map<String, dynamic> c) {
    final faltantes = <String>[];

    final tipoDocumento = c['TIPO_DOCUMENTO'] ?? c['tipo_documento'];
    final numeroDocumento = c['NUM_DOCUMENTO'] ?? c['num_documento'];
    final nombres = c['NOMBRES'] ?? c['nombres'] ?? c['NOMBRE'] ?? c['nombre'];
    final apellidos = c['APELLIDOS'] ?? c['apellidos'];
    final email = c['EMAIL'] ?? c['email'] ?? c['CORREO'] ?? c['correo'];
    final telefono = c['TEL_CELULAR'] ??
        c['tel_celular'] ??
        c['TELEFONO'] ??
        c['telefono'] ??
        c['CELULAR'] ??
        c['celular'];
    final pais = c['PAIS'] ?? c['pais'];
    final departamento = c['DEPARTAMENTO'] ?? c['departamento'];
    final ciudad = c['CIUDAD'] ?? c['ciudad'];
    final direccion = c['DIRECCION'] ?? c['direccion'];

    if (_isMissingValue(tipoDocumento)) faltantes.add('tipo documento');
    if (_isMissingValue(numeroDocumento)) faltantes.add('número documento');
    if (_isMissingValue(nombres)) faltantes.add('nombres');
    if (_isMissingValue(apellidos)) faltantes.add('apellidos');
    if (_isMissingValue(email)) faltantes.add('email');
    if (_isMissingValue(telefono)) faltantes.add('teléfono');
    if (_isMissingValue(pais)) faltantes.add('país');
    if (_isMissingValue(departamento)) faltantes.add('departamento');
    if (_isMissingValue(ciudad)) faltantes.add('ciudad');
    if (_isMissingValue(direccion)) faltantes.add('dirección');

    return faltantes;
  }

  Future<void> _eliminar(dynamic id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar cliente',
          style: TextStyle(
            color: AlpesColors.cafeOscuro,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          '¿Estás seguro? Esta acción no se puede deshacer.',
          style: TextStyle(color: AlpesColors.nogalMedio, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AlpesColors.nogalMedio),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AlpesColors.rojoColonial,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cliente}/$id'),
    );
    _cargar();
  }

  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClientesForm(item: item, onGuardado: _cargar),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Widget _headerBadge(String label, Color textColor, Color bgColor) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      );

  Widget _buildPendientesInfoCard() {
    final pendientes = _clientesPendientes;

    if (_loading) {
      return const SizedBox.shrink();
    }

    if (pendientes.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4EA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3B6D11).withOpacity(0.18)),
        ),
        child: Row(
          children: const [
            Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF3B6D11),
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Todos los clientes tienen su información completa.',
                style: TextStyle(
                  color: AlpesColors.cafeOscuro,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFFBF1),
            AlpesColors.oroGuatemalteco.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AlpesColors.oroGuatemalteco.withOpacity(0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AlpesColors.cafeOscuro.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AlpesColors.oroGuatemalteco.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AlpesColors.oroGuatemalteco,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Clientes pendientes de completar información (${pendientes.length})',
                  style: const TextStyle(
                    color: AlpesColors.cafeOscuro,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pendientes.take(5).map((cliente) {
            final nombres = (cliente['NOMBRES'] ??
                    cliente['nombres'] ??
                    cliente['NOMBRE'] ??
                    cliente['nombre'] ??
                    '')
                .toString()
                .trim();
            final apellidos =
                (cliente['APELLIDOS'] ?? cliente['apellidos'] ?? '')
                    .toString()
                    .trim();
            final nombreCompleto = '$nombres $apellidos'.trim().isEmpty
                ? 'Cliente sin nombre'
                : '$nombres $apellidos'.trim();
            final faltantes = _faltantesCliente(cliente);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AlpesColors.arenaCalida.withOpacity(0.18),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AlpesColors.cafeOscuro,
                    child: Text(
                      nombreCompleto.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AlpesColors.oroGuatemalteco,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreCompleto,
                          style: const TextStyle(
                            color: AlpesColors.cafeOscuro,
                            fontSize: 12.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Falta: ${faltantes.join(", ")}',
                          style: const TextStyle(
                            color: AlpesColors.nogalMedio,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (pendientes.length > 5) ...[
            const SizedBox(height: 4),
            Text(
              'Y ${pendientes.length - 5} cliente(s) más con información pendiente.',
              style: const TextStyle(
                color: AlpesColors.nogalMedio,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: RefreshIndicator(
        color: AlpesColors.cafeOscuro,
        onRefresh: _cargar,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: AlpesColors.cafeOscuro,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/admin'),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Clientes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (!_loading)
                      Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AlpesColors.oroGuatemalteco.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AlpesColors.oroGuatemalteco.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          '${_items.length}',
                          style: const TextStyle(
                            color: AlpesColors.oroGuatemalteco,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                background: Stack(
                  children: [
                    Container(color: AlpesColors.cafeOscuro),
                    Positioned(
                      top: -40,
                      right: -30,
                      child: _circle(
                        140,
                        AlpesColors.oroGuatemalteco.withOpacity(0.07),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 65,
                      child: _circle(
                        65,
                        AlpesColors.oroGuatemalteco.withOpacity(0.05),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: 60,
                      child: _circle(
                        85,
                        AlpesColors.oroGuatemalteco.withOpacity(0.06),
                      ),
                    ),
                    Positioned(
                      top: 30,
                      left: -20,
                      child: _circle(
                        70,
                        AlpesColors.oroGuatemalteco.withOpacity(0.04),
                      ),
                    ),
                    if (!_loading)
                      Positioned(
                        bottom: 44,
                        right: 16,
                        child: Row(
                          children: [
                            _headerBadge(
                              '$_totalActivos activos',
                              const Color(0xFF3B6D11),
                              const Color(0xFFEAF3DE),
                            ),
                            if (_totalInactivos > 0) ...[
                              const SizedBox(width: 6),
                              _headerBadge(
                                '$_totalInactivos inactivos',
                                AlpesColors.rojoColonial,
                                const Color(0xFFFCEBEB),
                              ),
                            ],
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AlpesColors.oroGuatemalteco.withOpacity(0.45),
                              AlpesColors.oroGuatemalteco.withOpacity(0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 20,
                      child: Icon(
                        Icons.people_alt_rounded,
                        size: 40,
                        color: AlpesColors.oroGuatemalteco.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: _buildPendientesInfoCard()),

            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _filtrar(),
                  decoration: InputDecoration(
                    hintText:
                        'Buscar por nombre, email, teléfono, país, departamento o ciudad…',
                    hintStyle: const TextStyle(
                      color: AlpesColors.arenaCalida,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AlpesColors.nogalMedio,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: AlpesColors.arenaCalida,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              _filtrar();
                            },
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: AlpesColors.cremaFondo,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AlpesColors.oroGuatemalteco.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                color: AlpesColors.cremaFondo,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AlpesColors.oroGuatemalteco,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _loading
                          ? 'Cargando…'
                          : '${_filtrados.length} cliente${_filtrados.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AlpesColors.nogalMedio,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty && !_loading) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AlpesColors.oroGuatemalteco.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'filtrado',
                          style: TextStyle(
                            fontSize: 10,
                            color: AlpesColors.oroGuatemalteco,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AlpesColors.cafeOscuro,
                  ),
                ),
              )
            else if (_filtrados.isEmpty)
              SliverFillRemaining(child: _emptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => FadeTransition(
                      opacity: _fadeAnim,
                      child: _HoverClienteCard(
                        cliente: _filtrados[i],
                        onEdit: () => _abrirForm(_filtrados[i]),
                        onDelete: () {
                          final id = _filtrados[i]['CLI_ID'] ??
                              _filtrados[i]['cli_id'] ??
                              _filtrados[i]['ID'] ??
                              _filtrados[i]['id'];
                          _eliminar(id);
                        },
                      ),
                    ),
                    childCount: _filtrados.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AlpesColors.cafeOscuro,
        elevation: 6,
        icon: const Icon(
          Icons.person_add_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: const Text(
          '+ Nuevo cliente',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        onPressed: () => _abrirForm(),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                ),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 38,
                color: AlpesColors.oroGuatemalteco.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Sin clientes',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AlpesColors.cafeOscuro,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No se encontraron resultados para esta búsqueda',
              style: TextStyle(fontSize: 13, color: AlpesColors.nogalMedio),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AlpesColors.cafeOscuro,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                elevation: 3,
              ),
              icon: const Icon(
                Icons.person_add_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Agregar cliente',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _abrirForm(),
            ),
          ],
        ),
      );
}

class _HoverClienteCard extends StatefulWidget {
  final Map<String, dynamic> cliente;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HoverClienteCard({
    required this.cliente,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_HoverClienteCard> createState() => _HoverClienteCardState();
}

class _HoverClienteCardState extends State<_HoverClienteCard> {
  bool _hovered = false;
  bool _expanded = false;

  bool _isMissingValue(dynamic value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    return text.isEmpty ||
        text == 'pendiente de completar' ||
        text == 'pendiente' ||
        text == 'sin completar' ||
        text == 'n/a' ||
        text == 'na' ||
        text == 'null';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cliente;
    final nombres = (c['NOMBRES'] ?? c['nombres'] ?? '').toString();
    final apellidos = (c['APELLIDOS'] ?? c['apellidos'] ?? '').toString();
    final email = (c['EMAIL'] ?? c['email'] ?? '').toString();
    final telefono = (c['TEL_CELULAR'] ??
            c['tel_celular'] ??
            c['TELEFONO'] ??
            c['telefono'] ??
            '')
        .toString();
    final pais = (c['PAIS'] ?? c['pais'] ?? '').toString();
    final departamento =
        (c['DEPARTAMENTO'] ?? c['departamento'] ?? '').toString();
    final ciudad = (c['CIUDAD'] ?? c['ciudad'] ?? '').toString();
    final direccion = (c['DIRECCION'] ?? c['direccion'] ?? '').toString();
    final tipoDoc =
        (c['TIPO_DOCUMENTO'] ?? c['tipo_documento'] ?? '').toString();
    final numDoc = (c['NUM_DOCUMENTO'] ?? c['num_documento'] ?? '').toString();
    final activo = (c['ACTIVO'] ?? c['activo'] ?? 1).toString() == '1';
    final fullName = '$nombres $apellidos'.trim();
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'C';

    final hasExtra = !_isMissingValue(pais) ||
        !_isMissingValue(departamento) ||
        !_isMissingValue(ciudad) ||
        !_isMissingValue(direccion) ||
        !_isMissingValue(numDoc) ||
        !_isMissingValue(tipoDoc);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 10),
        transform: Matrix4.identity()..translate(0.0, _hovered ? -3.0 : 0.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _hovered
                ? [Colors.white, AlpesColors.oroGuatemalteco.withOpacity(0.06)]
                : [Colors.white, const Color(0xFFF9F6F2)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? AlpesColors.oroGuatemalteco.withOpacity(0.55)
                : AlpesColors.pergamino,
            width: _hovered ? 1.5 : 1.0,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AlpesColors.cafeOscuro.withOpacity(0.11),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AlpesColors.oroGuatemalteco.withOpacity(0.07),
                    blurRadius: 6,
                  ),
                ]
              : [
                  BoxShadow(
                    color: AlpesColors.cafeOscuro.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AlpesColors.oroGuatemalteco.withOpacity(0.28),
                          AlpesColors.oroGuatemalteco.withOpacity(0.12),
                        ],
                      ),
                      border: Border.all(
                        color: AlpesColors.oroGuatemalteco.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AlpesColors.cafeOscuro,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
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
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: AlpesColors.cafeOscuro,
                                  letterSpacing: 0.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _badgeEstado(activo),
                          ],
                        ),
                        if (!_isMissingValue(email)) ...[
                          const SizedBox(height: 5),
                          _infoRow(
                            Icons.email_outlined,
                            email,
                            AlpesColors.nogalMedio,
                            11,
                          ),
                        ],
                        if (!_isMissingValue(telefono)) ...[
                          const SizedBox(height: 3),
                          _infoRow(
                            Icons.phone_outlined,
                            telefono,
                            AlpesColors.nogalMedio,
                            11,
                          ),
                        ],
                        if (!_isMissingValue(pais) ||
                            !_isMissingValue(departamento) ||
                            !_isMissingValue(ciudad)) ...[
                          const SizedBox(height: 3),
                          _infoRow(
                            Icons.location_on_outlined,
                            [pais, departamento, ciudad]
                                .where((s) => !_isMissingValue(s))
                                .join(', '),
                            AlpesColors.arenaCalida,
                            10.5,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _iconBtn(
                        Icons.edit_outlined,
                        AlpesColors.nogalMedio,
                        widget.onEdit,
                      ),
                      const SizedBox(height: 6),
                      _iconBtn(
                        Icons.delete_outline_rounded,
                        AlpesColors.rojoColonial,
                        widget.onDelete,
                      ),
                      if (hasExtra) ...[
                        const SizedBox(height: 6),
                        _iconBtn(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          AlpesColors.arenaCalida,
                          () => setState(() => _expanded = !_expanded),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AlpesColors.cafeOscuro.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AlpesColors.oroGuatemalteco.withOpacity(0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información adicional',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AlpesColors.cafeOscuro,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!_isMissingValue(tipoDoc) || !_isMissingValue(numDoc))
                      _detalleRow(
                        'Documento',
                        [tipoDoc, numDoc]
                            .where((s) => !_isMissingValue(s))
                            .join(' · '),
                      ),
                    if (!_isMissingValue(pais)) _detalleRow('País', pais),
                    if (!_isMissingValue(departamento))
                      _detalleRow('Departamento', departamento),
                    if (!_isMissingValue(ciudad)) _detalleRow('Ciudad', ciudad),
                    if (!_isMissingValue(direccion))
                      _detalleRow('Dirección', direccion),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeEstado(bool activo) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activo
                    ? const Color(0xFF3B6D11)
                    : AlpesColors.rojoColonial,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              activo ? 'Activo' : 'Inactivo',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: activo
                    ? const Color(0xFF3B6D11)
                    : AlpesColors.rojoColonial,
              ),
            ),
          ],
        ),
      );

  Widget _infoRow(IconData icon, String text, Color color, double size) => Row(
        children: [
          Icon(icon, size: 11.5, color: AlpesColors.arenaCalida),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: size, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _detalleRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AlpesColors.arenaCalida,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  color: AlpesColors.cafeOscuro,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(_hovered ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      );
}

class _ClientesForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;

  const _ClientesForm({this.item, required this.onGuardado});

  @override
  State<_ClientesForm> createState() => __ClientesFormState();
}

class __ClientesFormState extends State<_ClientesForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  bool _guardando = false;

  bool _isPendingText(dynamic value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    return text.isEmpty ||
        text == 'pendiente de completar' ||
        text == 'pendiente' ||
        text == 'sin completar' ||
        text == 'n/a' ||
        text == 'na' ||
        text == 'null';
  }

  String _cleanInitialValue(dynamic value) {
    return _isPendingText(value) ? '' : value.toString();
  }

  @override
  void initState() {
    super.initState();
    _c = {
      'tipo_documento': TextEditingController(),
      'num_documento': TextEditingController(),
      'nombres': TextEditingController(),
      'apellidos': TextEditingController(),
      'email': TextEditingController(),
      'tel_celular': TextEditingController(),
      'pais': TextEditingController(),
      'departamento': TextEditingController(),
      'ciudad': TextEditingController(),
      'direccion': TextEditingController(),
    };
    if (widget.item != null) {
      for (final k in _c.keys) {
        _c[k]!.text = _cleanInitialValue(
          widget.item![k.toUpperCase()] ?? widget.item![k] ?? '',
        );
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

  String _normalizeOptional(String value) {
    final v = value.trim();
    return v.isEmpty ? 'Pendiente de completar' : v;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = {
        'tipo_documento': _normalizeOptional(_c['tipo_documento']!.text),
        'num_documento': _normalizeOptional(_c['num_documento']!.text),
        'nombres': _normalizeOptional(_c['nombres']!.text),
        'apellidos': _normalizeOptional(_c['apellidos']!.text),
        'email': _normalizeOptional(_c['email']!.text),
        'tel_celular': _normalizeOptional(_c['tel_celular']!.text),
        'pais': _normalizeOptional(_c['pais']!.text),
        'departamento': _normalizeOptional(_c['departamento']!.text),
        'ciudad': _normalizeOptional(_c['ciudad']!.text),
        'direccion': _normalizeOptional(_c['direccion']!.text),
      };

      final idKey = widget.item?.keys.firstWhere(
            (k) => k.toLowerCase() == 'cli_id',
            orElse: () => '',
          ) ??
          '';
      final id = idKey.isNotEmpty ? widget.item![idKey] : null;
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.cliente}${id != null ? '/$id' : ''}',
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
              behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _campo(
    String label,
    String key, {
    TextInputType? type,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _c[key],
          keyboardType: type,
          decoration: InputDecoration(labelText: label),
        ),
      );

  Widget _seccion(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 13,
              decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AlpesColors.cafeOscuro,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: AlpesColors.pergamino,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 17,
                      decoration: BoxDecoration(
                        color: AlpesColors.oroGuatemalteco,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      widget.item == null
                          ? 'Nuevo cliente'
                          : 'Editar cliente',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AlpesColors.cafeOscuro,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AlpesColors.oroGuatemalteco.withOpacity(0.18),
                    ),
                  ),
                  child: const Text(
                    'Puedes guardar aunque falten datos. Cualquier campo vacío se marcará como "Pendiente de completar" y aparecerá en el bloque de seguimiento.',
                    style: TextStyle(
                      fontSize: 11.8,
                      color: AlpesColors.nogalMedio,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _seccion('Identificación'),
                Row(
                  children: [
                    Expanded(child: _campo('Tipo doc.', 'tipo_documento')),
                    const SizedBox(width: 10),
                    Expanded(child: _campo('No. documento', 'num_documento')),
                  ],
                ),
                _seccion('Datos personales'),
                Row(
                  children: [
                    Expanded(child: _campo('Nombres', 'nombres')),
                    const SizedBox(width: 10),
                    Expanded(child: _campo('Apellidos', 'apellidos')),
                  ],
                ),
                _campo('Email', 'email', type: TextInputType.emailAddress),
                _campo('Teléfono', 'tel_celular', type: TextInputType.phone),
                _seccion('Ubicación'),
                _campo('País', 'pais'),
                Row(
                  children: [
                    Expanded(child: _campo('Departamento', 'departamento')),
                    const SizedBox(width: 10),
                    Expanded(child: _campo('Ciudad', 'ciudad')),
                  ],
                ),
                _campo('Dirección', 'direccion'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AlpesColors.cafeOscuro,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      elevation: 3,
                    ),
                    child: _guardando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'GUARDAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}