import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:badges/badges.dart' as badges;
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/carrito_provider.dart';
import '../../providers/producto_provider.dart';
import '../../providers/favoritos_provider.dart';
import '../../widgets/bottom_nav_cliente.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Estado ──
  bool   _loading        = true;
  String _seccionActiva  = 'inicio';

  // KPIs
  int    _totalPedidos   = 0;
  int    _enCamino       = 0;
  int    _entregados     = 0;
  double _totalGastado   = 0;

  // Datos
  List<Map<String, dynamic>> _ordenesRecientes = [];
  List<Map<String, dynamic>> _tarjetas         = [];
  Map<String, dynamic>?      _ultimoEnvio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
      final auth = context.read<AuthProvider>();
      if (auth.clienteId != null) {
        context.read<CarritoProvider>().cargarCarrito(auth.clienteId!);
        context.read<FavoritosProvider>().cargarFavoritos(auth.clienteId!);
      }
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    if (auth.clienteId == null) { setState(() => _loading = false); return; }
    await Future.wait([
      _cargarOrdenes(auth.clienteId!),
      _cargarTarjetas(auth.clienteId!),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cargarOrdenes(int clienteId) async {
    try {
      final res  = await http.get(Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.ordenVenta}/buscar?criterio=cli_id&valor=$clienteId'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = List<Map<String, dynamic>>.from(data['data']);
        double gastado = 0;
        int camino = 0, entregados = 0;
        for (final o in list) {
          gastado += double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0;
          final e = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
          if (e == 'entregado') entregados++;
          if (e == 'en proceso' || e == 'en camino' || e == 'enviado') camino++;
        }
        // Última orden con envío activo para tracking
        final activa = list.firstWhere(
          (o) {
            final e = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
            return e != 'entregado' && e != 'cancelado';
          },
          orElse: () => {},
        );
        if (activa.isNotEmpty) {
          _ultimoEnvio = activa;
        }
        if (mounted) setState(() {
          _ordenesRecientes = list.take(5).toList();
          _totalPedidos     = list.length;
          _enCamino         = camino;
          _entregados       = entregados;
          _totalGastado     = gastado;
        });
      }
    } catch (_) {}
  }

  Future<void> _cargarTarjetas(int clienteId) async {
    try {
      final res  = await http.get(Uri.parse(
          '${ApiConfig.baseUrl}/tarjetas-cliente/cliente/$clienteId'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        if (mounted) setState(() =>
            _tarjetas = List<Map<String, dynamic>>.from(data['data']));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final carrito = context.watch<CarritoProvider>();
    final nombre  = auth.nombreCompleto;
    final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
    final email   = auth.usuario?['EMAIL'] ?? auth.usuario?['email'] ?? '';
    final w       = MediaQuery.of(context).size.width;
    final hasSidebar = w >= 700;

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: Row(
        children: [
          // ── SIDEBAR ──
          if (hasSidebar)
            _buildSidebar(context, auth, nombre, initial, email, carrito),

          // ── CONTENIDO ──
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, auth, nombre, initial, carrito, !hasSidebar),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(
                          color: AlpesColors.cafeOscuro, strokeWidth: 2))
                      : RefreshIndicator(
                          color: AlpesColors.cafeOscuro,
                          onRefresh: _cargarDatos,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildKpiRow(),
                                const SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 3, child: Column(children: [
                                      _buildPedidosRecientes(context),
                                      const SizedBox(height: 16),
                                      _buildMetodosPago(context),
                                    ])),
                                    if (w > 800) ...[
                                      const SizedBox(width: 16),
                                      Expanded(flex: 2, child: _buildTracking(context)),
                                    ],
                                  ],
                                ),
                                if (w <= 800) ...[
                                  const SizedBox(height: 16),
                                  _buildTracking(context),
                                ],
                                const SizedBox(height: 16),
                                _buildAccesosRapidos(context),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !hasSidebar
          ? const BottomNavCliente(currentIndex: 0)
          : null,
    );
  }

  // ── SIDEBAR ─────────────────────────────────────────────
  Widget _buildSidebar(BuildContext context, AuthProvider auth,
      String nombre, String initial, String email, CarritoProvider carrito) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AlpesColors.cafeOscuro,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
            blurRadius: 12, offset: const Offset(2, 0))],
      ),
      child: Stack(children: [
        // Círculos decorativos
        Positioned(top: -30, right: -30, child: _circle(110, AlpesColors.oroGuatemalteco.withOpacity(0.07))),
        Positioned(bottom: 80, left: -30, child: _circle(90, AlpesColors.oroGuatemalteco.withOpacity(0.05))),
        Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [BoxShadow(color: AlpesColors.oroGuatemalteco.withOpacity(0.4),
                          blurRadius: 8)]),
                  child: const Icon(Icons.chair_alt_rounded, color: AlpesColors.cafeOscuro, size: 20),
                ),
                const SizedBox(width: 8),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Muebles de los Alpes', style: TextStyle(color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                  Text('Portal del Cliente', style: TextStyle(color: AlpesColors.arenaCalida, fontSize: 9)),
                ])),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(children: [
                  Container(width: 30, height: 30,
                      decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
                          borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: Text(initial, style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w800, color: AlpesColors.cafeOscuro))),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    if (email.isNotEmpty)
                      Text(email, style: const TextStyle(color: AlpesColors.arenaCalida,
                          fontSize: 9), overflow: TextOverflow.ellipsis),
                  ])),
                ]),
              ),
            ]),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Menú Mi Cuenta
          _sidebarSection('MI CUENTA'),
          _sidebarItem(Icons.home_rounded,          'Inicio',         'inicio',    context),
          _sidebarItem(Icons.person_outline_rounded, 'Mi perfil',     'perfil',    context, route: '/perfil'),
          _sidebarItem(Icons.credit_card_rounded,   'Mis tarjetas',  'tarjetas',  context, route: '/mis-tarjetas'),
          _sidebarItem(Icons.receipt_long_rounded,  'Mis pedidos',   'pedidos',   context,
              route: '/mis-ordenes', badge: _enCamino),
          _sidebarItem(Icons.location_on_rounded,   'Tracking',      'tracking',  context),
          const Divider(color: Colors.white12, height: 1),
          // Tienda
          _sidebarSection('TIENDA'),
          _sidebarItem(Icons.grid_view_rounded,       'Catálogo',      'catalogo',    context, route: '/catalogo'),
          _sidebarItem(Icons.history_rounded,         'Historial',     'historial',   context, route: '/mis-ordenes'),
          _sidebarItem(Icons.notifications_outlined,  'Notificaciones','notif',       context, route: '/notificaciones'),
          _sidebarItem(Icons.settings_outlined,       'Configuración', 'config',      context, route: '/perfil'),
          const Spacer(),
          const Divider(color: Colors.white12, height: 1),
          // User footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Container(width: 28, height: 28,
                  decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
                      borderRadius: BorderRadius.circular(7)),
                  alignment: Alignment.center,
                  child: Text(initial, style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w800, color: AlpesColors.cafeOscuro))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 10,
                    fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text(email, style: const TextStyle(color: AlpesColors.arenaCalida,
                    fontSize: 9), overflow: TextOverflow.ellipsis),
              ])),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AlpesColors.rojoColonial, size: 16),
                onPressed: () async { await auth.logout(); if (context.mounted) context.go('/login'); },
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
            ]),
          ),
          const SizedBox(height: 8),
        ]),
      ]),
    );
  }

  Widget _sidebarSection(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
    child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4),
        fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
  );

  Widget _sidebarItem(IconData icon, String label, String seccion,
      BuildContext context, {String? route, int badge = 0}) {
    final active = _seccionActiva == seccion;
    return GestureDetector(
      onTap: () {
        if (route != null && route != '') {
          context.go(route);
        } else {
          setState(() => _seccionActiva = seccion);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AlpesColors.oroGuatemalteco.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.3)) : null,
        ),
        child: Row(children: [
          Icon(icon, size: 16,
              color: active ? AlpesColors.oroGuatemalteco : AlpesColors.arenaCalida),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? Colors.white : Colors.white.withOpacity(0.8)))),
          if (badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: AlpesColors.rojoColonial,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$badge', style: const TextStyle(color: Colors.white,
                  fontSize: 9, fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    );
  }

  // ── TOP BAR ─────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, AuthProvider auth, String nombre,
      String initial, CarritoProvider carrito, bool showHamburger) {
    return SizedBox(
      height: 56,
      child: Stack(children: [
        Container(color: AlpesColors.cremaFondo),
        Positioned(bottom: 0, left: 0, right: 0,
            child: Container(height: 1, color: AlpesColors.pergamino)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            if (showHamburger)
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: AlpesColors.cafeOscuro),
                onPressed: () => _showMobileDrawer(context, auth, nombre, initial),
              ),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Bienvenida, $nombre',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: AlpesColors.cafeOscuro)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: AlpesColors.oroGuatemalteco.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Cliente VIP',
                      style: TextStyle(color: AlpesColors.oroGuatemalteco,
                          fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            )),
            // Campana
            badges.Badge(
              badgeContent: Text('$_enCamino', style: const TextStyle(
                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
              showBadge: _enCamino > 0,
              badgeStyle: const badges.BadgeStyle(badgeColor: AlpesColors.rojoColonial),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AlpesColors.cafeOscuro),
                onPressed: () => context.go('/notificaciones'),
              ),
            ),
            const SizedBox(width: 4),
            // Avatar
            GestureDetector(
              onTap: () => context.go('/perfil'),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AlpesColors.oroGuatemalteco,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [BoxShadow(color: AlpesColors.oroGuatemalteco.withOpacity(0.3),
                      blurRadius: 8)],
                ),
                alignment: Alignment.center,
                child: Text(initial, style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w800, color: AlpesColors.cafeOscuro)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _showMobileDrawer(BuildContext context, AuthProvider auth, String nombre, String initial) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AlpesColors.cafeOscuro,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(width: 36, height: 3, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          _buildSidebar(context, auth, nombre, initial, '', context.read<CarritoProvider>()),
        ]),
      ),
    );
  }

  // ── KPIs ─────────────────────────────────────────────────
  Widget _buildKpiRow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _sectionLabel('Resumen de mi cuenta'),
        TextButton(onPressed: () => context.go('/perfil'),
            child: const Text('Ver perfil →', style: TextStyle(fontSize: 12,
                color: AlpesColors.nogalMedio))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _kpiCard(Icons.shopping_bag_rounded,
            '$_totalPedidos', 'PEDIDOS\nTOTALES', AlpesColors.cafeOscuro)),
        const SizedBox(width: 10),
        Expanded(child: _kpiCard(Icons.local_shipping_rounded,
            '$_enCamino', 'EN\nCAMINO', AlpesColors.verdeSelva)),
        const SizedBox(width: 10),
        Expanded(child: _kpiCard(Icons.check_circle_rounded,
            '$_entregados', 'ENTREGADOS', AlpesColors.oroGuatemalteco)),
        const SizedBox(width: 10),
        Expanded(child: _kpiCard(Icons.attach_money_rounded,
            'Q${_totalGastado >= 1000 ? '${(_totalGastado/1000).toStringAsFixed(1)}k' : _totalGastado.toStringAsFixed(0)}',
            'TOTAL\nGASTADO', AlpesColors.rojoColonial)),
      ]),
    ]);
  }

  Widget _kpiCard(IconData icon, String value, String label, Color accent) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AlpesColors.pergamino),
          boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
              color: AlpesColors.cafeOscuro, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: AlpesColors.nogalMedio,
              fontWeight: FontWeight.w600, height: 1.3)),
        ]),
      );

  // ── PEDIDOS RECIENTES ────────────────────────────────────
  Widget _buildPedidosRecientes(BuildContext context) => _card(
    title: 'Mis pedidos recientes',
    action: TextButton(onPressed: () => context.go('/mis-ordenes'),
        child: const Text('Ver todos →', style: TextStyle(fontSize: 12,
            color: AlpesColors.oroGuatemalteco))),
    child: _ordenesRecientes.isEmpty
        ? _emptyRow('Sin pedidos aún')
        : Column(children: [
            // Header tabla
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
              child: Row(children: const [
                Expanded(flex: 2, child: Text('PEDIDO', style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w700, color: AlpesColors.arenaCalida))),
                Expanded(flex: 3, child: Text('PRODUCTO', style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w700, color: AlpesColors.arenaCalida))),
                Expanded(flex: 2, child: Text('FECHA', style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w700, color: AlpesColors.arenaCalida))),
                Expanded(flex: 2, child: Text('TOTAL', style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w700, color: AlpesColors.arenaCalida),
                    textAlign: TextAlign.right)),
              ]),
            ),
            const Divider(height: 1, color: AlpesColors.pergamino),
            ..._ordenesRecientes.map((o) {
              final id     = o['ORDEN_VENTA_ID'] ?? o['orden_venta_id'];
              final num    = o['NUM_ORDEN'] ?? o['num_orden'] ?? '#$id';
              final total  = double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0;
              final fecha  = (o['FECHA_ORDEN'] ?? o['fecha_orden'] ?? '').toString().split('T').first;
              final prod   = o['PRODUCTO'] ?? o['producto'] ?? 'Mueble Alpes';
              return GestureDetector(
                onTap: () => context.go('/orden/$id'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Expanded(flex: 2, child: Text('#$num',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: AlpesColors.oroGuatemalteco))),
                    Expanded(flex: 3, child: Text(prod.toString(),
                        style: const TextStyle(fontSize: 12, color: AlpesColors.cafeOscuro),
                        overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2, child: Text(fecha,
                        style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio))),
                    Expanded(flex: 2, child: Text('Q${total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: AlpesColors.cafeOscuro), textAlign: TextAlign.right)),
                  ]),
                ),
              );
            }).toList(),
          ]),
  );

  // ── TRACKING ─────────────────────────────────────────────
  Widget _buildTracking(BuildContext context) => _card(
    title: 'Tracking activo',
    action: Row(children: [
      _smallBtn('Detalle', () => context.go('/mis-ordenes'), filled: true),
      const SizedBox(width: 6),
      _smallBtn('Líneas', () {}),
    ]),
    child: _ultimoEnvio == null
        ? _emptyRow('Sin envíos activos')
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Text('Pedido #${_ultimoEnvio!['NUM_ORDEN'] ?? _ultimoEnvio!['num_orden'] ?? ''}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AlpesColors.oroGuatemalteco)),
            const Text('Sofá Alpino — estimado',
                style: TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
            const SizedBox(height: 16),
            _trackingStep('Pedido confirmado', 'completado', subtitle: 'Confirmado'),
            _trackingStep('En producción', 'activo', subtitle: 'En proceso'),
            _trackingStep('En camino a la dirección', 'pendiente',
                subtitle: 'Est. próximamente'),
            _trackingStep('Entregado', 'pendiente', subtitle: 'Est. próximamente'),
          ]),
  );

  Widget _trackingStep(String label, String estado, {String? subtitle}) {
    final Color color;
    final Widget dot;
    switch (estado) {
      case 'completado':
        color = const Color(0xFF3B6D11);
        dot = Container(width: 16, height: 16,
            decoration: const BoxDecoration(color: Color(0xFF3B6D11), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 10));
        break;
      case 'activo':
        color = AlpesColors.oroGuatemalteco;
        dot = Container(width: 16, height: 16,
            decoration: BoxDecoration(
                border: Border.all(color: AlpesColors.oroGuatemalteco, width: 2),
                shape: BoxShape.circle),
            child: Center(child: Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: AlpesColors.oroGuatemalteco,
                    shape: BoxShape.circle))));
        break;
      default:
        color = AlpesColors.arenaCalida;
        dot = Container(width: 16, height: 16,
            decoration: BoxDecoration(
                border: Border.all(color: AlpesColors.pergamino, width: 2),
                shape: BoxShape.circle));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          dot,
          if (label != 'Entregado')
            Container(width: 1, height: 28, color: AlpesColors.pergamino),
        ]),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          if (subtitle != null)
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AlpesColors.nogalMedio)),
        ])),
      ]),
    );
  }

  // ── MÉTODOS DE PAGO ──────────────────────────────────────
  Widget _buildMetodosPago(BuildContext context) => _card(
    title: 'Mis métodos de pago',
    action: TextButton(
      onPressed: () => context.go('/mis-tarjetas'),
      child: const Text('Gestionar tarjetas', style: TextStyle(fontSize: 12,
          color: AlpesColors.nogalMedio)),
    ),
    child: _tarjetas.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Icon(Icons.credit_card_outlined, color: AlpesColors.arenaCalida.withOpacity(0.5), size: 32),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Sin tarjetas registradas',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AlpesColors.cafeOscuro)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.go('/mis-tarjetas'),
                  child: const Text('+ Agregar tarjeta',
                      style: TextStyle(fontSize: 12, color: AlpesColors.oroGuatemalteco,
                          fontWeight: FontWeight.w600)),
                ),
              ])),
            ]),
          )
        : SizedBox(
            height: 105,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tarjetas.length,
              itemBuilder: (_, i) => _buildTarjetaCard(_tarjetas[i]),
            ),
          ),
  );

  Widget _buildTarjetaCard(Map<String, dynamic> t) {
    final marca    = (t['MARCA'] ?? t['marca'] ?? 'VISA').toString();
    final ultimos  = (t['ULTIMOS_4'] ?? t['ultimos_4'] ?? '****').toString();
    final titular  = (t['TITULAR'] ?? t['titular'] ?? '').toString();
    final mes      = t['MES_VENCIMIENTO'] ?? t['mes_vencimiento'] ?? '';
    final anio     = t['ANIO_VENCIMIENTO'] ?? t['anio_vencimiento'] ?? '';
    final esPred   = (t['PREDETERMINADA'] ?? t['predeterminada'] ?? 0) == 1;

    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 12, top: 8, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: esPred
              ? [AlpesColors.cafeOscuro, const Color(0xFF3D2416)]
              : [AlpesColors.nogalMedio, AlpesColors.cafeOscuro],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.25),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(marca, style: const TextStyle(color: AlpesColors.oroGuatemalteco,
              fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          if (esPred) Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: const Text('✓ Principal', style: TextStyle(color: AlpesColors.oroGuatemalteco,
                fontSize: 8, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        Text('•••• •••• •••• $ultimos',
            style: const TextStyle(color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(titular, style: const TextStyle(color: AlpesColors.arenaCalida, fontSize: 10)),
          Text('Vence $mes/$anio', style: const TextStyle(color: AlpesColors.arenaCalida, fontSize: 10)),
        ]),
      ]),
    );
  }

  // ── ACCESOS RÁPIDOS ──────────────────────────────────────
  Widget _buildAccesosRapidos(BuildContext context) {
    final accesos = [
      {'icon': Icons.grid_view_rounded,      'label': 'Catálogo',    'route': '/catalogo'},
      {'icon': Icons.receipt_long_rounded,   'label': 'Mis pedidos', 'route': '/mis-ordenes'},
      {'icon': Icons.favorite_rounded,       'label': 'Favoritos',   'route': '/favoritos'},
      {'icon': Icons.credit_card_rounded,    'label': 'Tarjetas',    'route': '/mis-tarjetas'},
      {'icon': Icons.help_outline_rounded,   'label': 'Soporte',     'route': '/soporte'},
      {'icon': Icons.star_rate_rounded,      'label': 'Mis reseñas', 'route': '/mis-resenas'},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('Accesos rápidos'),
      const SizedBox(height: 10),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10, crossAxisSpacing: 10,
        childAspectRatio: 2.2,
        children: accesos.map((a) => GestureDetector(
          onTap: () => context.go(a['route'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AlpesColors.pergamino),
              boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.04),
                  blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(a['icon'] as IconData, size: 18, color: AlpesColors.cafeOscuro),
              const SizedBox(width: 6),
              Text(a['label'] as String, style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro)),
            ]),
          ),
        )).toList(),
      ),
    ]);
  }

  // ── HELPERS ─────────────────────────────────────────────
  Widget _card({required String title, required Widget child, Widget? action}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AlpesColors.pergamino),
          boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: AlpesColors.cafeOscuro)),
              if (action != null) action,
            ]),
            const SizedBox(height: 4),
            const Divider(color: AlpesColors.pergamino),
            child,
          ]),
        ),
      );

  Widget _sectionLabel(String label) => Row(children: [
    Container(width: 3, height: 14,
        decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
        color: AlpesColors.cafeOscuro)),
  ]);

  Widget _emptyRow(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(child: Text(msg, style: const TextStyle(
        color: AlpesColors.arenaCalida, fontSize: 13))),
  );

  Widget _smallBtn(String label, VoidCallback onTap, {bool filled = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: filled ? AlpesColors.cafeOscuro : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: filled ? null : Border.all(color: AlpesColors.pergamino),
          ),
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: filled ? Colors.white : AlpesColors.cafeOscuro)),
        ),
      );

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
