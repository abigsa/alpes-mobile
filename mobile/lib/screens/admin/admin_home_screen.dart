import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────
//  BREAKPOINTS
// ─────────────────────────────────────────────────────────
const double _kMobile  = 600;
const double _kTablet  = 900;

// ─────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────

class _KpiData {
  final String label;
  final IconData icon;
  final Color accent;
  final bool isUp;
  const _KpiData({
    required this.label,
    required this.icon,
    required this.accent,
    this.isUp = true,
  });
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
  final bool showBadge; // si true, usa el badge real de órdenes
  const _NavEntry({
    required this.label,
    required this.icon,
    this.route,
    this.children = const [],
    this.showBadge = false,
  });
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
    _NavEntry(label: 'Productos',   icon: Icons.chair_alt_rounded,      children: [
      _NavEntry(label: 'Lista de productos', icon: Icons.list_alt_rounded,  route: '/admin/productos'),
      _NavEntry(label: 'Inventario',         icon: Icons.warehouse_rounded, route: '/admin/inventario'),
    ]),
    _NavEntry(label: 'Órdenes',     icon: Icons.receipt_long_rounded,   route: '/admin/ordenes',  showBadge: true),
    _NavEntry(label: 'Clientes',    icon: Icons.people_alt_rounded,     route: '/admin/clientes'),
    _NavEntry(label: 'Marketing',   icon: Icons.campaign_rounded,       route: '/admin/marketing'),
    _NavEntry(label: 'Reportes',    icon: Icons.bar_chart_rounded,      route: '/admin/reportes'),
  ]),
  _NavSection(title: 'Operativa', entries: [
    _NavEntry(label: 'Empleados',   icon: Icons.badge_rounded,          route: '/admin/empleados'),
    _NavEntry(label: 'Nómina',      icon: Icons.payments_rounded,       route: '/admin/nomina'),
    _NavEntry(label: 'Proveedores', icon: Icons.local_shipping_rounded, children: [
      _NavEntry(label: 'Lista proveedores', icon: Icons.list_alt_rounded,     route: '/admin/proveedores'),
      _NavEntry(label: 'Órdenes compra',   icon: Icons.shopping_bag_rounded,  route: '/admin/compras'),
    ]),
    _NavEntry(label: 'Producción',  icon: Icons.factory_rounded,        route: '/admin/produccion'),
    _NavEntry(label: 'Config.',     icon: Icons.settings_rounded,       route: '/admin/configuracion'),
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

  // Badge real de órdenes pendientes
  int _ordenesCount = 0;

  @override
  void initState() {
    super.initState();
    _cargarOrdenesCount();
  }

  // ── Carga el conteo real de órdenes desde el API ──
  Future<void> _cargarOrdenesCount() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = data['data'] as List;
        // Filtramos solo las que no estén entregadas/cerradas
        final pendientes = list.where((o) {
          final estado = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
          return estado != 'entregado' && estado != 'cancelado' && estado != 'cerrado';
        }).length;
        if (mounted) setState(() => _ordenesCount = pendientes);
      }
    } catch (_) {
      // Si falla el API, dejamos en 0
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final username = auth.usuario?['USERNAME'] ?? auth.usuario?['username'] ?? 'Administrador';
    final initials = username.isNotEmpty ? username[0].toUpperCase() : 'A';
    final width    = MediaQuery.of(context).size.width;

    final isCompact  = width < _kMobile;
    final isMedium   = width >= _kMobile && width < _kTablet;
    final isExpanded = width >= _kTablet;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AlpesColors.cremaFondo,
      drawer: (isCompact || isMedium)
          ? _buildFullDrawer(context, auth, username, initials)
          : null,
      body: Row(
        children: [
          if (isMedium)   _buildRailCompact(context, auth, username, initials),
          if (isExpanded) _buildSidebarFull(context, auth, username, initials),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, auth, username, initials, !isExpanded),
                Expanded(child: _buildBody(context, width)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  TOP BAR
  // ─────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, AuthProvider auth,
      String username, String initials, bool showHamburger) {
    return Container(
      height: 56,
      color: AlpesColors.cafeOscuro,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                Text('Bienvenido, $username',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
                  ),
                  child: const Text('Administrador',
                      style: TextStyle(
                          color: AlpesColors.oroGuatemalteco,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
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
      onRefresh: _cargarOrdenesCount,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── RESUMEN ──
            Row(
              children: [
                Expanded(child: _sectionLabel('Resumen ejecutivo')),
                // Botón generar reporte
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
              ],
            ),
            const SizedBox(height: 12),
            _buildKpiGrid(totalWidth),
            const SizedBox(height: 24),

            // ── COMERCIAL ──
            _sectionLabel('Gestión comercial'),
            const SizedBox(height: 10),
            _buildModuleGrid(context, _modules.sublist(0, 6), totalWidth),
            const SizedBox(height: 24),

            // ── OPERATIVA ──
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generar reporte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
            const SizedBox(height: 4),
            const Text('Selecciona el tipo de reporte a exportar',
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

  Widget _reporteBtn(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: AlpesColors.cafeOscuro.withOpacity(0.08),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: AlpesColors.cafeOscuro),
      ),
      title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AlpesColors.arenaCalida),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  //  KPI GRID — valores en 0 (conectar a API cuando esté listo)
  // ─────────────────────────────────────────────────────────

  Widget _buildKpiGrid(double totalWidth) {
    final cw   = _contentWidth(totalWidth);
    final cols = cw > 560 ? 4 : (cw > 320 ? 2 : 1);

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
      itemBuilder: (_, i) => _buildKpiCard(_kpiDefs[i]),
    );
  }

  Widget _buildKpiCard(_KpiData k) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AlpesColors.pergamino.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: k.accent.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: k.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(k.icon, size: 17, color: k.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Valor siempre en 0 por ahora
                const Text(
                  '0',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AlpesColors.cafeOscuro,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  k.label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AlpesColors.nogalMedio,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
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
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  MODULE GRID — más compacto + sombra mejorada
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
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,   // más ancho que alto → cards menos altas
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildModuleTile(context, items[i]),
    );
  }

  Widget _buildModuleTile(BuildContext context, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => context.go(item['route'] as String),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AlpesColors.pergamino.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: AlpesColors.cafeOscuro.withOpacity(0.07),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AlpesColors.cafeOscuro.withOpacity(0.07),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: AlpesColors.cafeOscuro,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item['label'] as String,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AlpesColors.cafeOscuro,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  SIDEBAR COMPLETO (>= 900px)
  // ─────────────────────────────────────────────────────────

  Widget _buildSidebarFull(BuildContext context, AuthProvider auth,
      String username, String initials) {
    return Container(
      width: 220,
      color: AlpesColors.cafeOscuro,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AlpesColors.oroGuatemalteco,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chair_alt_rounded,
                      color: AlpesColors.cafeOscuro, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Muebles de los Alpes',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                      Text('Panel Administrativo',
                          style: TextStyle(color: AlpesColors.arenaCalida, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
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
          ),
        ],
      ),
    );
  }

  Widget _sidebarSectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 3),
    child: Text(label.toUpperCase(),
        style: const TextStyle(
            color: AlpesColors.arenaCalida,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2)),
  );

  Widget _buildFullNavEntry(BuildContext context, _NavEntry entry) {
    if (entry.children.isEmpty) {
      final badge = (entry.showBadge) ? _ordenesCount : 0;
      return _buildFullNavTile(
        icon: entry.icon,
        label: entry.label,
        badge: badge,
        onTap: () { if (entry.route != null) context.go(entry.route!); },
      );
    }
    final isOpen = _expanded.contains(entry.label);
    return Column(children: [
      InkWell(
        onTap: () => setState(() => isOpen
            ? _expanded.remove(entry.label)
            : _expanded.add(entry.label)),
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
    required IconData icon,
    required String label,
    int badge = 0,
    bool indent = false,
    Color? iconColor,
    Color? textColor,
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
                style: TextStyle(
                    color: textColor ?? Colors.white.withOpacity(0.88),
                    fontSize: 13))),
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
  //  RAIL COMPACTO — solo íconos (600–900px)
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

    return Container(
      width: 60,
      color: AlpesColors.cafeOscuro,
      child: Column(children: [
        const SizedBox(height: 48),
        Container(
          width: 36, height: 36,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: AlpesColors.oroGuatemalteco,
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.chair_alt_rounded,
              color: AlpesColors.cafeOscuro, size: 20),
        ),
        Container(height: 1,
            color: Colors.white.withOpacity(0.08),
            margin: const EdgeInsets.symmetric(vertical: 4)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: flat.map((e) => _buildRailIcon(context, e)).toList(),
          ),
        ),
        Container(height: 1, color: Colors.white.withOpacity(0.08)),
        _buildRailIconRaw(
          icon: Icons.logout_rounded,
          tooltip: 'Cerrar sesión',
          color: AlpesColors.rojoColonial,
          onTap: () async {
            await auth.logout();
            if (context.mounted) context.go('/login');
          },
        ),
        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _buildRailIcon(BuildContext context, _NavEntry entry) {
    final badge = entry.showBadge ? _ordenesCount : 0;
    return _buildRailIconRaw(
      icon: entry.icon,
      tooltip: entry.label,
      badge: badge,
      onTap: () { if (entry.route != null) context.go(entry.route!); },
    );
  }

  Widget _buildRailIconRaw({
    required IconData icon,
    required String tooltip,
    int badge = 0,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
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
                      style: const TextStyle(
                          color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  DRAWER HAMBURGUESA
  // ─────────────────────────────────────────────────────────

  Widget _buildFullDrawer(BuildContext context, AuthProvider auth,
      String username, String initials) {
    return Drawer(
      backgroundColor: AlpesColors.cafeOscuro,
      width: 260,
      child: Column(children: [
        DrawerHeader(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          decoration: const BoxDecoration(color: AlpesColors.cafeOscuro),
          child: Stack(children: [
            Positioned(
              top: -15, right: -15,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AlpesColors.oroGuatemalteco.withOpacity(0.07)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 36, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                          color: AlpesColors.oroGuatemalteco,
                          borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.chair_alt_rounded,
                          color: AlpesColors.cafeOscuro, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Muebles de los Alpes',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis),
                          Text('Panel Administrativo',
                              style: TextStyle(
                                  color: AlpesColors.arenaCalida, fontSize: 10)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                            color: AlpesColors.oroGuatemalteco,
                            borderRadius: BorderRadius.circular(6)),
                        alignment: Alignment.center,
                        child: Text(initials,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AlpesColors.cafeOscuro)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(username,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final sec in _navSections) ...[
                _sidebarSectionLabel(sec.title),
                for (final entry in sec.entries)
                  _buildDrawerNavEntry(context, entry),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08)))),
          child: _buildFullNavTile(
            icon: Icons.logout_rounded,
            label: 'Cerrar sesión',
            iconColor: AlpesColors.rojoColonial,
            textColor: AlpesColors.rojoColonial,
            onTap: () async {
              Navigator.pop(context);
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildDrawerNavEntry(BuildContext context, _NavEntry entry) {
    if (entry.children.isEmpty) {
      final badge = entry.showBadge ? _ordenesCount : 0;
      return _buildFullNavTile(
        icon: entry.icon,
        label: entry.label,
        badge: badge,
        onTap: () {
          Navigator.pop(context);
          if (entry.route != null) context.go(entry.route!);
        },
      );
    }
    final key   = 'drawer_${entry.label}';
    final isOpen = _expanded.contains(key);
    return Column(children: [
      InkWell(
        onTap: () => setState(() =>
            isOpen ? _expanded.remove(key) : _expanded.add(key)),
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
          child: Column(
            children: entry.children.map((c) => _buildFullNavTile(
              icon: c.icon, label: c.label, indent: true,
              onTap: () {
                Navigator.pop(context);
                if (c.route != null) context.go(c.route!);
              },
            )).toList(),
          ),
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
    Container(
      width: 3, height: 15,
      decoration: BoxDecoration(
          color: AlpesColors.oroGuatemalteco,
          borderRadius: BorderRadius.circular(2)),
    ),
    const SizedBox(width: 8),
    Text(label,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
  ]);
}
