import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ventas_chart_widget.dart';
import '../../widgets/notificaciones_widget.dart';

// ─────────────────────────────────────────────────────────
//  BREAKPOINTS
// ─────────────────────────────────────────────────────────
const double _kMobile = 600;
const double _kTablet = 900;

// ─────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────
class _KpiData {
  final String label;
  final IconData icon;
  final Color accent;
  final bool isUp;
  const _KpiData({required this.label, required this.icon, required this.accent, this.isUp = true});
}

class _NavSection {
  final String title;
  final List<_NavEntry> entries;
  const _NavSection({required this.title, required this.entries});
}

class _NavEntry {
  final String label;
  final IconData icon;
  final String? route;
  final List<_NavEntry> children;
  final bool showBadge;
  const _NavEntry({required this.label, required this.icon, this.route, this.children = const [], this.showBadge = false});
}

// ─────────────────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────────────────
const _kpiDefs = [
  _KpiData(label: 'Ventas del mes',   icon: Icons.trending_up_rounded,  accent: AlpesColors.cafeOscuro),
  _KpiData(label: 'Órdenes activas',  icon: Icons.receipt_long_rounded, accent: AlpesColors.oroGuatemalteco),
  _KpiData(label: 'Clientes activos', icon: Icons.people_alt_rounded,   accent: AlpesColors.verdeSelva),
  _KpiData(label: 'Stock bajo',       icon: Icons.inventory_2_rounded,  accent: AlpesColors.rojoColonial, isUp: false),
];

const _navSections = [
  _NavSection(title: 'Comercial', entries: [
    _NavEntry(label: 'Productos', icon: Icons.chair_alt_rounded, children: [
      _NavEntry(label: 'Lista de productos', icon: Icons.list_alt_rounded,  route: '/admin/productos'),
      _NavEntry(label: 'Inventario',         icon: Icons.warehouse_rounded, route: '/admin/inventario'),
    ]),
    _NavEntry(label: 'Órdenes',   icon: Icons.receipt_long_rounded, route: '/admin/ordenes',  showBadge: true),
    _NavEntry(label: 'Clientes',  icon: Icons.people_alt_rounded,   route: '/admin/clientes'),
    _NavEntry(label: 'Marketing', icon: Icons.campaign_rounded,     route: '/admin/marketing'),
    _NavEntry(label: 'Reportes',  icon: Icons.bar_chart_rounded,    route: '/admin/reportes'),
  ]),
  _NavSection(title: 'Operativa', entries: [
    _NavEntry(label: 'Empleados',   icon: Icons.badge_rounded,          route: '/admin/empleados'),
    _NavEntry(label: 'Nómina',      icon: Icons.payments_rounded,       route: '/admin/nomina'),
    _NavEntry(label: 'Proveedores', icon: Icons.local_shipping_rounded, children: [
      _NavEntry(label: 'Lista proveedores', icon: Icons.list_alt_rounded,    route: '/admin/proveedores'),
      _NavEntry(label: 'Órdenes compra',   icon: Icons.shopping_bag_rounded, route: '/admin/compras'),
    ]),
    _NavEntry(label: 'Producción', icon: Icons.factory_rounded,  route: '/admin/produccion'),
    _NavEntry(label: 'Config.',    icon: Icons.settings_rounded, route: '/admin/configuracion'),
  ]),
];

const _modules = [
  {'label': 'Productos',   'icon': Icons.chair_alt_rounded,      'route': '/admin/productos'},
  {'label': 'Inventario',  'icon': Icons.warehouse_rounded,       'route': '/admin/inventario'},
  {'label': 'Órdenes',     'icon': Icons.receipt_long_rounded,    'route': '/admin/ordenes'},
  {'label': 'Clientes',    'icon': Icons.people_alt_rounded,      'route': '/admin/clientes'},
  {'label': 'Marketing',   'icon': Icons.campaign_rounded,        'route': '/admin/marketing'},
  {'label': 'Reportes',    'icon': Icons.bar_chart_rounded,       'route': '/admin/reportes'},
  {'label': 'Empleados',   'icon': Icons.badge_rounded,           'route': '/admin/empleados'},
  {'label': 'Nómina',      'icon': Icons.payments_rounded,        'route': '/admin/nomina'},
  {'label': 'Proveedores', 'icon': Icons.local_shipping_rounded,  'route': '/admin/proveedores'},
  {'label': 'Compras',     'icon': Icons.shopping_bag_rounded,    'route': '/admin/compras'},
  {'label': 'Producción',  'icon': Icons.factory_rounded,         'route': '/admin/produccion'},
  {'label': 'Config.',     'icon': Icons.settings_rounded,        'route': '/admin/configuracion'},
];

// ─────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<String> _expanded = {};

  // KPI reales
  int    _ordenesCount    = 0;
  double _ventasMes       = 0;
  int    _ordenesActivas  = 0;
  int    _clientesActivos = 0;
  int    _stockBajo       = 0;

  @override
  void initState() {
    super.initState();
    _cargarKpis();
  }

  Future<void> _cargarKpis() async {
    await Future.wait([
      _cargarOrdenes(),
      _cargarClientes(),
      _cargarInventario(),
    ]);
  }

  Future<void> _cargarOrdenes() async {
    try {
      final res  = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = data['data'] as List;
        final ahora  = DateTime.now();
        double ventas = 0;
        int activas   = 0;
        int pendientes = 0;
        for (final o in list) {
          final estado = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
          final total  = double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0;
          // Ventas del mes actual
          final fecha = o['FECHA_ORDEN'] ?? o['fecha_orden'] ?? '';
          if (fecha.toString().contains('${ahora.year}') &&
              fecha.toString().contains('-${ahora.month.toString().padLeft(2, '0')}-')) {
            ventas += total;
          }
          if (estado != 'entregado' && estado != 'cancelado' && estado != 'cerrado') {
            activas++;
            pendientes++;
          }
        }
        if (mounted) setState(() {
          _ventasMes      = ventas;
          _ordenesActivas = activas;
          _ordenesCount   = pendientes;
        });
      }
    } catch (_) {}
  }

  Future<void> _cargarClientes() async {
    try {
      final res  = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cliente}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = data['data'] as List;
        if (mounted) setState(() => _clientesActivos = list.length);
      }
    } catch (_) {}
  }

  Future<void> _cargarInventario() async {
    try {
      final res  = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventarioProducto}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = data['data'] as List;
        // Stock bajo = items con cantidad <= 5
        final bajo = list.where((i) {
          final qty = int.tryParse('${i['CANTIDAD'] ?? i['cantidad'] ?? i['STOCK'] ?? i['stock'] ?? 0}') ?? 0;
          return qty <= 5;
        }).length;
        if (mounted) setState(() => _stockBajo = bajo);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth        = context.watch<AuthProvider>();
    final nombreMostrar = auth.nombreCompleto;
    final username    = auth.usuario?['USERNAME'] ?? auth.usuario?['username'] ?? 'Administrador';
    final initials    = nombreMostrar.isNotEmpty ? nombreMostrar[0].toUpperCase() : 'A';
    final width       = MediaQuery.of(context).size.width;
    final isCompact  = width < _kMobile;
    final isMedium   = width >= _kMobile && width < _kTablet;
    final isExpanded = width >= _kTablet;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AlpesColors.cremaFondo,
      drawer: (isCompact || isMedium)
          ? _buildFullDrawer(context, auth, nombreMostrar, initials)
          : null,
      body: Row(
        children: [
          if (isMedium)   _buildRailCompact(context, auth, nombreMostrar, initials),
          if (isExpanded) _buildSidebarFull(context, auth, nombreMostrar, initials),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, auth, nombreMostrar, username, initials, !isExpanded),
                Expanded(child: _buildBody(context, width)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  TOP BAR con menú de usuario
  // ─────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, AuthProvider auth,
      String nombreMostrar, String username, String initials, bool showHamburger) {
    return SizedBox(
      height: 58,
      child: Stack(
        children: [
          // Fondo base
          Container(color: AlpesColors.cafeOscuro),
          // Círculos decorativos premium (mismo estilo que sidebar)
          Positioned(top: -30, right: 120,
              child: _circle(80, AlpesColors.oroGuatemalteco.withOpacity(0.07))),
          Positioned(top: -20, right: 60,
              child: _circle(50, AlpesColors.oroGuatemalteco.withOpacity(0.05))),
          Positioned(bottom: -20, left: 200,
              child: _circle(60, AlpesColors.oroGuatemalteco.withOpacity(0.04))),
          Positioned(top: -10, left: 300,
              child: _circle(40, AlpesColors.oroGuatemalteco.withOpacity(0.06))),
          // Línea dorada sutil en la base
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  AlpesColors.oroGuatemalteco.withOpacity(0.4),
                  AlpesColors.oroGuatemalteco.withOpacity(0.4),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (showHamburger)
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Bienvenido, $nombreMostrar',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(
                          color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
                        ),
                        child: const Text('Administrador',
                            style: TextStyle(
                                color: AlpesColors.oroGuatemalteco,
                                fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                      ),
                    ],
                  ),
                ),
                // Notificaciones con panel
                NotificacionesBtn(count: _ordenesCount),
                const SizedBox(width: 6),
                // Menú de usuario
                _UserMenuBtn(
                  initials: initials,
                  nombreMostrar: nombreMostrar,
                  username: username,
                  auth: auth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  BODY
  // ─────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, double totalWidth) {
    return RefreshIndicator(
      color: AlpesColors.cafeOscuro,
      onRefresh: _cargarKpis,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: _sectionLabel('Resumen ejecutivo')),
              OutlinedButton.icon(
                onPressed: () => _mostrarReporte(context),
                icon: const Icon(Icons.download_rounded, size: 15),
                label: const Text('Generar reporte', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AlpesColors.cafeOscuro,
                  side: const BorderSide(color: AlpesColors.nogalMedio),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _buildKpiGrid(totalWidth),
            const SizedBox(height: 20),

            // ── GRÁFICA DE VENTAS ──
            _sectionLabel('Ventas acumuladas'),
            const SizedBox(height: 10),
            const VentasMensualesChart(),
            const SizedBox(height: 24),
            _sectionLabel('Gestión comercial'),
            const SizedBox(height: 10),
            _buildModuleGrid(context, _modules.sublist(0, 6), totalWidth),
            const SizedBox(height: 24),
            _sectionLabel('Gestión operativa'),
            const SizedBox(height: 10),
            _buildModuleGrid(context, _modules.sublist(6), totalWidth),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _mostrarReporte(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generar reporte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
            const SizedBox(height: 4),
            const Text('Selecciona el módulo a exportar',
                style: TextStyle(fontSize: 13, color: AlpesColors.nogalMedio)),
            const SizedBox(height: 20),
            _reporteBtn(context, Icons.receipt_long_rounded, 'Reporte de ventas',     '/admin/reportes'),
            _reporteBtn(context, Icons.inventory_2_rounded,  'Reporte de inventario', '/admin/inventario'),
            _reporteBtn(context, Icons.people_alt_rounded,   'Reporte de clientes',   '/admin/clientes'),
            _reporteBtn(context, Icons.payments_rounded,     'Reporte de nómina',     '/admin/nomina'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _reporteBtn(BuildContext context, IconData icon, String label, String route) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: AlpesColors.cafeOscuro.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 18, color: AlpesColors.cafeOscuro),
        ),
        title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AlpesColors.arenaCalida),
        onTap: () { Navigator.pop(context); context.go(route); },
      );

  // ─────────────────────────────────────────────────────────
  //  KPI GRID
  // ─────────────────────────────────────────────────────────
  Widget _buildKpiGrid(double totalWidth) {
    final cw   = _contentWidth(totalWidth);
    final cols = cw > 560 ? 4 : (cw > 320 ? 2 : 1);

    // Valores reales mapeados a cada KPI
    final valores = [
      'Q ${_ventasMes >= 1000 ? '${(_ventasMes / 1000).toStringAsFixed(1)}k' : _ventasMes.toStringAsFixed(0)}',
      '$_ordenesActivas',
      '$_clientesActivos',
      '$_stockBajo',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: cols >= 4 ? 2.2 : 2.4,
      ),
      itemCount: _kpiDefs.length,
      itemBuilder: (_, i) => _HoverKpiCard(kpi: _kpiDefs[i], valor: valores[i]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  MODULE GRID
  // ─────────────────────────────────────────────────────────
  Widget _buildModuleGrid(BuildContext context,
      List<Map<String, dynamic>> items, double totalWidth) {
    final cw   = _contentWidth(totalWidth);
    final cols = cw > 700 ? 6 : cw > 460 ? 4 : cw > 320 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _HoverModuleTile(item: items[i]),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SIDEBAR PREMIUM con círculos decorativos
  // ─────────────────────────────────────────────────────────
  Widget _buildSidebarFull(BuildContext context, AuthProvider auth,
      String username, String initials) {
    return Container(
      width: 220,
      child: Stack(
        children: [
          // Fondo base
          Container(color: AlpesColors.cafeOscuro),
          // Círculos decorativos premium
          Positioned(top: -40, right: -40,
              child: _circle(130, AlpesColors.oroGuatemalteco.withOpacity(0.07))),
          Positioned(top: 80, left: -50,
              child: _circle(100, AlpesColors.oroGuatemalteco.withOpacity(0.04))),
          Positioned(bottom: 100, right: -30,
              child: _circle(120, AlpesColors.oroGuatemalteco.withOpacity(0.05))),
          Positioned(bottom: -30, left: -20,
              child: _circle(90, AlpesColors.oroGuatemalteco.withOpacity(0.06))),
          // Contenido
          Column(
            children: [
              _buildSidebarHeader(username, initials),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final sec in _navSections) ...[
                      _sidebarSectionLabel(sec.title),
                      for (final entry in sec.entries)
                        _buildFullNavEntry(context, entry),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
              _buildSidebarFooter(context, auth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _buildSidebarHeader(String username, String initials) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AlpesColors.oroGuatemalteco,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(
                color: AlpesColors.oroGuatemalteco.withOpacity(0.4),
                blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.chair_alt_rounded, color: AlpesColors.cafeOscuro, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Muebles de los Alpes',
                    style: TextStyle(color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                Text('Panel Administrativo',
                    style: TextStyle(color: AlpesColors.arenaCalida, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter(BuildContext context, AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08)))),
      child: _buildFullNavTile(
        icon: Icons.logout_rounded,
        label: 'Cerrar sesión',
        iconColor: AlpesColors.rojoColonial,
        textColor: AlpesColors.rojoColonial,
        onTap: () async {
          await auth.logout();
          if (context.mounted) context.go('/login');
        },
      ),
    );
  }

  Widget _sidebarSectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: Text(label.toUpperCase(),
        style: TextStyle(
            color: AlpesColors.arenaCalida.withOpacity(0.7),
            fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
  );

  Widget _buildFullNavEntry(BuildContext context, _NavEntry entry) {
    if (entry.children.isEmpty) {
      final badge = entry.showBadge ? _ordenesCount : 0;
      return _buildFullNavTile(
        icon: entry.icon, label: entry.label, badge: badge,
        onTap: () { if (entry.route != null) context.go(entry.route!); },
      );
    }
    final isOpen = _expanded.contains(entry.label);
    return Column(children: [
      InkWell(
        onTap: () => setState(() =>
            isOpen ? _expanded.remove(entry.label) : _expanded.add(entry.label)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(children: [
              Icon(entry.icon, size: 16, color: AlpesColors.arenaCalida),
              const SizedBox(width: 10),
              Expanded(child: Text(entry.label,
                  style: const TextStyle(color: Colors.white, fontSize: 13))),
              AnimatedRotation(
                turns: isOpen ? 0.25 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AlpesColors.arenaCalida),
              ),
            ]),
          ),
        ),
      ),
      AnimatedCrossFade(
        duration: const Duration(milliseconds: 180),
        crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: const SizedBox.shrink(),
        secondChild: Container(
          color: Colors.black.withOpacity(0.15),
          child: Column(children: entry.children
              .map((c) => _buildFullNavTile(
                    icon: c.icon, label: c.label, indent: true,
                    onTap: () { if (c.route != null) context.go(c.route!); },
                  ))
              .toList()),
        ),
      ),
    ]);
  }

  Widget _buildFullNavTile({
    required IconData icon, required String label,
    int badge = 0, bool indent = false,
    Color? iconColor, Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: indent ? 6 : 10, vertical: 1),
        child: Container(
          padding: EdgeInsets.only(left: indent ? 28 : 8, right: 8, top: 9, bottom: 9),
          child: Row(children: [
            Icon(icon, size: 16, color: iconColor ?? AlpesColors.arenaCalida),
            const SizedBox(width: 10),
            Expanded(child: Text(label,
                style: TextStyle(color: textColor ?? Colors.white.withOpacity(0.88), fontSize: 13))),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: AlpesColors.rojoColonial,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  RAIL COMPACTO
  // ─────────────────────────────────────────────────────────
  Widget _buildRailCompact(BuildContext context, AuthProvider auth,
      String username, String initials) {
    final flat = [
      for (final s in _navSections)
        for (final e in s.entries) ...[
          if (e.route != null) e,
          for (final c in e.children) if (c.route != null) c,
        ]
    ];
    return SizedBox(
      width: 60,
      child: Stack(children: [
        Container(color: AlpesColors.cafeOscuro),
        Positioned(top: -20, right: -20, child: _circle(80, AlpesColors.oroGuatemalteco.withOpacity(0.08))),
        Positioned(bottom: 60, left: -30, child: _circle(90, AlpesColors.oroGuatemalteco.withOpacity(0.05))),
        Column(children: [
          const SizedBox(height: 48),
          Container(
            width: 36, height: 36,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AlpesColors.oroGuatemalteco,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [BoxShadow(color: AlpesColors.oroGuatemalteco.withOpacity(0.4), blurRadius: 10)],
            ),
            child: const Icon(Icons.chair_alt_rounded, color: AlpesColors.cafeOscuro, size: 18),
          ),
          Container(height: 1, color: Colors.white.withOpacity(0.08),
              margin: const EdgeInsets.symmetric(vertical: 4)),
          Expanded(child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: flat.map((e) => _buildRailIcon(context, e)).toList(),
          )),
          Container(height: 1, color: Colors.white.withOpacity(0.08)),
          _buildRailIconRaw(icon: Icons.logout_rounded, tooltip: 'Cerrar sesión',
              color: AlpesColors.rojoColonial,
              onTap: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              }),
          const SizedBox(height: 12),
        ]),
      ]),
    );
  }

  Widget _buildRailIcon(BuildContext context, _NavEntry entry) {
    final badge = entry.showBadge ? _ordenesCount : 0;
    return _buildRailIconRaw(icon: entry.icon, tooltip: entry.label, badge: badge,
        onTap: () { if (entry.route != null) context.go(entry.route!); });
  }

  Widget _buildRailIconRaw({required IconData icon, required String tooltip,
      int badge = 0, Color? color, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip, preferBelow: false,
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          child: Stack(alignment: Alignment.topRight, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: color ?? AlpesColors.arenaCalida),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: AlpesColors.rojoColonial, shape: BoxShape.circle),
                child: Text('$badge',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  DRAWER HAMBURGUESA con círculos premium
  // ─────────────────────────────────────────────────────────
  Widget _buildFullDrawer(BuildContext context, AuthProvider auth,
      String username, String initials) {
    return Drawer(
      width: 260,
      child: Stack(children: [
        Container(color: AlpesColors.cafeOscuro),
        Positioned(top: -30, right: -30, child: _circle(120, AlpesColors.oroGuatemalteco.withOpacity(0.08))),
        Positioned(top: 120, left: -40, child: _circle(100, AlpesColors.oroGuatemalteco.withOpacity(0.04))),
        Positioned(bottom: 80, right: -20, child: _circle(110, AlpesColors.oroGuatemalteco.withOpacity(0.05))),
        Positioned(bottom: -20, left: -30, child: _circle(90, AlpesColors.oroGuatemalteco.withOpacity(0.06))),
        Column(children: [
          DrawerHeader(
            margin: EdgeInsets.zero, padding: EdgeInsets.zero,
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 36, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AlpesColors.oroGuatemalteco,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(
                            color: AlpesColors.oroGuatemalteco.withOpacity(0.4),
                            blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.chair_alt_rounded, color: AlpesColors.cafeOscuro, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Muebles de los Alpes',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                        Text('Panel Administrativo',
                            style: TextStyle(color: AlpesColors.arenaCalida, fontSize: 10)),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                            color: AlpesColors.oroGuatemalteco,
                            borderRadius: BorderRadius.circular(7)),
                        alignment: Alignment.center,
                        child: Text(initials,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                color: AlpesColors.cafeOscuro)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(username,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final sec in _navSections) ...[
                _sidebarSectionLabel(sec.title),
                for (final entry in sec.entries)
                  _buildDrawerNavEntry(context, entry),
                const SizedBox(height: 4),
              ],
            ],
          )),
          Container(
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08)))),
            child: _buildFullNavTile(
              icon: Icons.logout_rounded, label: 'Cerrar sesión',
              iconColor: AlpesColors.rojoColonial, textColor: AlpesColors.rojoColonial,
              onTap: () async {
                Navigator.pop(context);
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildDrawerNavEntry(BuildContext context, _NavEntry entry) {
    if (entry.children.isEmpty) {
      final badge = entry.showBadge ? _ordenesCount : 0;
      return _buildFullNavTile(
        icon: entry.icon, label: entry.label, badge: badge,
        onTap: () { Navigator.pop(context); if (entry.route != null) context.go(entry.route!); },
      );
    }
    final key    = 'drawer_${entry.label}';
    final isOpen = _expanded.contains(key);
    return Column(children: [
      InkWell(
        onTap: () => setState(() => isOpen ? _expanded.remove(key) : _expanded.add(key)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(children: [
              Icon(entry.icon, size: 16, color: AlpesColors.arenaCalida),
              const SizedBox(width: 10),
              Expanded(child: Text(entry.label,
                  style: const TextStyle(color: Colors.white, fontSize: 13))),
              AnimatedRotation(
                turns: isOpen ? 0.25 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(Icons.chevron_right_rounded, size: 16, color: AlpesColors.arenaCalida),
              ),
            ]),
          ),
        ),
      ),
      AnimatedCrossFade(
        duration: const Duration(milliseconds: 180),
        crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: const SizedBox.shrink(),
        secondChild: Container(
          color: Colors.black.withOpacity(0.15),
          child: Column(children: entry.children.map((c) => _buildFullNavTile(
            icon: c.icon, label: c.label, indent: true,
            onTap: () { Navigator.pop(context); if (c.route != null) context.go(c.route!); },
          )).toList()),
        ),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────
  double _contentWidth(double totalWidth) {
    if (totalWidth >= _kTablet) return totalWidth - 220;
    if (totalWidth >= _kMobile) return totalWidth - 60;
    return totalWidth;
  }

  Widget _sectionLabel(String label) => Row(children: [
    Container(width: 3, height: 15,
        decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
        color: AlpesColors.cafeOscuro)),
  ]);
}

// ─────────────────────────────────────────────────────────
//  WIDGET: TOP ICON BUTTON con badge
// ─────────────────────────────────────────────────────────
class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  const _TopIconBtn({required this.icon, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(alignment: Alignment.topRight, children: [
          Icon(icon, color: Colors.white.withOpacity(0.85), size: 22),
          if (badge > 0)
            Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(
                  color: AlpesColors.rojoColonial, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  WIDGET: USER MENU DROPDOWN
// ─────────────────────────────────────────────────────────
class _UserMenuBtn extends StatelessWidget {
  final String initials;
  final String nombreMostrar;
  final String username;
  final AuthProvider auth;
  const _UserMenuBtn({
    required this.initials,
    required this.nombreMostrar,
    required this.username,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      onSelected: (val) async {
        if (val == 'perfil') {
          _abrirPerfil(context);
        } else if (val == 'logout') {
          await auth.logout();
          if (context.mounted) context.go('/login');
        } else if (val == 'config') {
          context.go('/admin/configuracion');
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: AlpesColors.oroGuatemalteco,
                      borderRadius: BorderRadius.circular(9)),
                  alignment: Alignment.center,
                  child: Text(initials,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: AlpesColors.cafeOscuro)),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nombreMostrar,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AlpesColors.cafeOscuro)),
                  Text('@$username',
                      style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
                ]),
              ]),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AlpesColors.pergamino),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'perfil',
          child: Row(children: [
            Container(width: 30, height: 30,
                decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.person_outline_rounded, size: 16, color: AlpesColors.cafeOscuro)),
            const SizedBox(width: 10),
            const Text('Mi perfil', style: TextStyle(fontSize: 13, color: AlpesColors.cafeOscuro)),
          ]),
        ),
        PopupMenuItem(
          value: 'config',
          child: Row(children: [
            Container(width: 30, height: 30,
                decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.settings_outlined, size: 16, color: AlpesColors.cafeOscuro)),
            const SizedBox(width: 10),
            const Text('Configuración', style: TextStyle(fontSize: 13, color: AlpesColors.cafeOscuro)),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(children: [
            Container(width: 30, height: 30,
                decoration: BoxDecoration(color: AlpesColors.rojoColonial.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.logout_rounded, size: 16, color: AlpesColors.rojoColonial)),
            const SizedBox(width: 10),
            const Text('Cerrar sesión',
                style: TextStyle(fontSize: 13, color: AlpesColors.rojoColonial)),
          ]),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco,
                borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(initials,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AlpesColors.cafeOscuro)),
          ),
          const SizedBox(width: 8),
          Text(nombreMostrar,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
        ]),
      ),
    );
  }

  void _abrirPerfil(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PerfilSheet(auth: auth),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SHEET: PERFIL DE USUARIO
// ─────────────────────────────────────────────────────────
class _PerfilSheet extends StatefulWidget {
  final AuthProvider auth;
  const _PerfilSheet({required this.auth});
  @override
  State<_PerfilSheet> createState() => _PerfilSheetState();
}

class _PerfilSheetState extends State<_PerfilSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passActualCtrl;
  late final TextEditingController _passNuevaCtrl;
  late final TextEditingController _passConfirmaCtrl;

  bool _verActual = false;
  bool _verNueva  = false;
  bool _verConfirma = false;
  bool _guardando = false;
  bool _cambiarPass = false;

  @override
  void initState() {
    super.initState();
    final u = widget.auth.usuario;
    _nombreCtrl   = TextEditingController(text: u?['NOMBRE']   ?? u?['nombre']   ?? '');
    _apellidoCtrl = TextEditingController(text: u?['APELLIDO'] ?? u?['apellido'] ?? '');
    _emailCtrl    = TextEditingController(text: u?['EMAIL']    ?? u?['email']    ?? '');
    _passActualCtrl  = TextEditingController();
    _passNuevaCtrl   = TextEditingController();
    _passConfirmaCtrl= TextEditingController();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _apellidoCtrl.dispose(); _emailCtrl.dispose();
    _passActualCtrl.dispose(); _passNuevaCtrl.dispose(); _passConfirmaCtrl.dispose();
    super.dispose();
  }

  String get _username {
    final u = widget.auth.usuario;
    return u?['USERNAME'] ?? u?['username'] ?? 'sin usuario';
  }

  String get _initials => _username.isNotEmpty ? _username[0].toUpperCase() : 'A';

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cambiarPass && _passNuevaCtrl.text != _passConfirmaCtrl.text) {
      _snack('Las contraseñas no coinciden', isError: true);
      return;
    }
    setState(() => _guardando = true);
    try {
      final u  = widget.auth.usuario;
      final id = u?['USU_ID'] ?? u?['usu_id'] ?? u?['ID'] ?? u?['id'];

      // Actualizar datos del perfil en el API
      if (id != null) {
        final body = {
          'nombre'  : _nombreCtrl.text.trim(),
          'apellido': _apellidoCtrl.text.trim(),
          'email'   : _emailCtrl.text.trim(),
        };
        await http.put(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarios}/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      }

      // Cambiar contraseña si se activó
      if (_cambiarPass && _passNuevaCtrl.text.isNotEmpty) {
        final res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/autenticacion/cambiar-contrasena'),
          headers: {
            'Content-Type': 'application/json',
            if (widget.auth.token != null) 'Authorization': 'Bearer ${widget.auth.token}',
          },
          body: jsonEncode({
            'contrasenaAnterior': _passActualCtrl.text,
            'contrasenaNueva'   : _passNuevaCtrl.text,
          }),
        );
        final data = jsonDecode(res.body);
        if (data['ok'] != true) {
          _snack(data['mensaje'] ?? 'Error al cambiar contraseña', isError: true);
          return;
        }
      }

      // ── Actualizar en memoria y SharedPreferences ──
      // Esto hace que el topbar y el menú se actualicen inmediatamente
      await widget.auth.updatePerfil(
        nombre  : _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        email   : _emailCtrl.text.trim(),
      );

      if (mounted) {
        _snack('Perfil actualizado correctamente');
        Navigator.pop(context);
      }
    } catch (e) {
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AlpesColors.rojoColonial : AlpesColors.verdeSelva,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(child: Container(
                  width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: AlpesColors.pergamino,
                      borderRadius: BorderRadius.circular(2)))),

                // Avatar + username (no editable)
                Row(children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                        color: AlpesColors.oroGuatemalteco,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                            color: AlpesColors.oroGuatemalteco.withOpacity(0.3),
                            blurRadius: 12, offset: const Offset(0, 4))]),
                    alignment: Alignment.center,
                    child: Text(_initials,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                            color: AlpesColors.cafeOscuro)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mi perfil',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                              color: AlpesColors.cafeOscuro)),
                      const SizedBox(height: 4),
                      // Username — solo lectura, no modificable
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: AlpesColors.cafeOscuro.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 13, color: AlpesColors.nogalMedio),
                          const SizedBox(width: 5),
                          Text('@$_username',
                              style: const TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600, color: AlpesColors.nogalMedio)),
                        ]),
                      ),
                      const SizedBox(height: 2),
                      const Text('El usuario no puede modificarse',
                          style: TextStyle(fontSize: 10, color: AlpesColors.arenaCalida)),
                    ],
                  )),
                ]),
                const SizedBox(height: 24),

                // ── Datos personales ──
                _sectionTitle('Datos personales'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _campo('Nombre', _nombreCtrl,
                      icon: Icons.person_outline_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _campo('Apellido', _apellidoCtrl,
                      icon: Icons.person_outline_rounded)),
                ]),
                _campo('Correo electrónico', _emailCtrl,
                    icon: Icons.email_outlined,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 20),

                // ── Cambio de contraseña ──
                GestureDetector(
                  onTap: () => setState(() => _cambiarPass = !_cambiarPass),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _cambiarPass
                          ? AlpesColors.cafeOscuro.withOpacity(0.06)
                          : AlpesColors.cremaFondo,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _cambiarPass
                            ? AlpesColors.oroGuatemalteco.withOpacity(0.4)
                            : AlpesColors.pergamino,
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.lock_reset_rounded,
                          size: 18, color: _cambiarPass
                              ? AlpesColors.cafeOscuro : AlpesColors.nogalMedio),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Cambiar contraseña',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: _cambiarPass
                                  ? AlpesColors.cafeOscuro : AlpesColors.nogalMedio))),
                      Icon(_cambiarPass
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                          color: AlpesColors.arenaCalida),
                    ]),
                  ),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _cambiarPass
                      ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(children: [
                      _campoPass('Contraseña actual', _passActualCtrl,
                          _verActual, () => setState(() => _verActual = !_verActual)),
                      _campoPass('Nueva contraseña', _passNuevaCtrl,
                          _verNueva, () => setState(() => _verNueva = !_verNueva),
                          validator: (v) {
                            if (_cambiarPass && (v == null || v.length < 8)) {
                              return 'Mínimo 8 caracteres';
                            }
                            return null;
                          }),
                      _campoPass('Confirmar nueva contraseña', _passConfirmaCtrl,
                          _verConfirma, () => setState(() => _verConfirma = !_verConfirma)),
                    ]),
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardarPerfil,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AlpesColors.cafeOscuro,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _guardando
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('GUARDAR CAMBIOS',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
                                letterSpacing: 0.8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Row(children: [
    Container(width: 3, height: 14,
        decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
        color: AlpesColors.cafeOscuro)),
  ]);

  Widget _campo(String label, TextEditingController ctrl,
      {IconData? icon, TextInputType? type, String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: AlpesColors.nogalMedio) : null,
          ),
          validator: validator,
        ),
      );

  Widget _campoPass(String label, TextEditingController ctrl,
      bool ver, VoidCallback toggle, {String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          obscureText: !ver,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                size: 18, color: AlpesColors.nogalMedio),
            suffixIcon: IconButton(
              icon: Icon(ver ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18, color: AlpesColors.arenaCalida),
              onPressed: toggle,
            ),
          ),
          validator: validator,
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  HOVER: KPI CARD
// ─────────────────────────────────────────────────────────
class _HoverKpiCard extends StatefulWidget {
  final _KpiData kpi;
  final String valor;
  const _HoverKpiCard({required this.kpi, required this.valor});
  @override
  State<_HoverKpiCard> createState() => _HoverKpiCardState();
}

class _HoverKpiCardState extends State<_HoverKpiCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final k = widget.kpi;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _hovered ? -4.0 : 0.0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: _hovered
                ? [Colors.white, AlpesColors.oroGuatemalteco.withOpacity(0.06)]
                : [Colors.white, const Color(0xFFF7F3EE)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? AlpesColors.oroGuatemalteco.withOpacity(0.5)
                : AlpesColors.pergamino.withOpacity(0.8),
            width: _hovered ? 1.5 : 1.0,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: k.accent.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
                 BoxShadow(color: AlpesColors.oroGuatemalteco.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(color: k.accent.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3)),
                 BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: k.accent.withOpacity(_hovered ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(k.icon, size: 17, color: k.accent),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.valor,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AlpesColors.cafeOscuro, letterSpacing: -0.5)),
              Text(k.label, style: const TextStyle(fontSize: 10.5,
                  color: AlpesColors.nogalMedio, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ],
          )),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: k.isUp ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              k.isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 11,
              color: k.isUp ? const Color(0xFF3B6D11) : AlpesColors.rojoColonial,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  HOVER: MODULE TILE — estilo Premium + Minimalista
// ─────────────────────────────────────────────────────────
class _HoverModuleTile extends StatefulWidget {
  final Map<String, dynamic> item;
  const _HoverModuleTile({required this.item});
  @override
  State<_HoverModuleTile> createState() => _HoverModuleTileState();
}

class _HoverModuleTileState extends State<_HoverModuleTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _pressed;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(widget.item['route'] as String),
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) => setState(() => _pressed = false),
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, _pressed ? 1.0 : _hovered ? -5.0 : 0.0)
            ..scale(_pressed ? 0.97 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: active
                  ? [Colors.white, AlpesColors.oroGuatemalteco.withOpacity(0.08)]
                  : [
                      AlpesColors.cafeOscuro.withOpacity(0.03),
                      AlpesColors.oroGuatemalteco.withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? AlpesColors.oroGuatemalteco.withOpacity(0.6)
                  : AlpesColors.oroGuatemalteco.withOpacity(0.2),
              width: active ? 1.5 : 1.0,
            ),
            boxShadow: active
                ? [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.14), blurRadius: 18, offset: const Offset(0, 8)),
                   BoxShadow(color: AlpesColors.oroGuatemalteco.withOpacity(0.10), blurRadius: 6, offset: const Offset(0, 2))]
                : [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Stack(children: [
            // Brillo esquina
            Positioned(top: -15, right: -15,
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AlpesColors.oroGuatemalteco.withOpacity(active ? 0.14 : 0.08),
                ),
              ),
            ),
            // Línea dorada top
            Positioned(top: 0, left: 14, right: 14,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: active ? 2 : 0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    AlpesColors.oroGuatemalteco.withOpacity(0.8),
                    Colors.transparent,
                  ]),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                ),
              ),
            ),
            // Contenido
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: active
                        ? AlpesColors.cafeOscuro.withOpacity(0.12)
                        : AlpesColors.cafeOscuro.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AlpesColors.cafeOscuro.withOpacity(0.06)),
                  ),
                  child: Icon(widget.item['icon'] as IconData,
                      color: AlpesColors.cafeOscuro,
                      size: 19),
                ),
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: AlpesColors.cafeOscuro.withOpacity(active ? 1.0 : 0.8),
                    ),
                    child: Text(widget.item['label'] as String,
                        textAlign: TextAlign.center, maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
