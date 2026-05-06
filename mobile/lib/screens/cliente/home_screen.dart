import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
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
  bool _loading = true;
  String _seccionActiva = 'inicio';
  bool _miCuentaOpen = true;
  bool _tiendaOpen = true;

  // KPIs
  int _totalPedidos = 0;
  int _enCamino = 0;
  int _entregados = 0;
  double _totalGastado = 0;

  // Datos
  List<Map<String, dynamic>> _ordenesRecientes = [];
  List<Map<String, dynamic>> _tarjetas = [];
  Map<String, dynamic>? _ultimoEnvio;

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
    if (auth.clienteId == null) {
      setState(() => _loading = false);
      return;
    }
    await Future.wait([
      _cargarOrdenes(auth.clienteId!),
      _cargarTarjetas(auth.clienteId!),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cargarOrdenes(int clienteId) async {
    try {
      final res = await http.get(Uri.parse(
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
            final e =
                (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
            return e != 'entregado' && e != 'cancelado';
          },
          orElse: () => {},
        );
        if (activa.isNotEmpty) {
          _ultimoEnvio = activa;
        }
        if (mounted)
          setState(() {
            _ordenesRecientes = list.take(5).toList();
            _totalPedidos = list.length;
            _enCamino = camino;
            _entregados = entregados;
            _totalGastado = gastado;
          });
      }
    } catch (_) {}
  }

  Future<void> _cargarTarjetas(int clienteId) async {
    try {
      final res = await http.get(Uri.parse(
          '${ApiConfig.baseUrl}/tarjetas-cliente/cliente/$clienteId'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        if (mounted)
          setState(
              () => _tarjetas = List<Map<String, dynamic>>.from(data['data']));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final carrito = context.watch<CarritoProvider>();
    final nombre = auth.nombreCompleto;
    final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
    final email = auth.usuario?['EMAIL'] ?? auth.usuario?['email'] ?? '';
    final w = MediaQuery.of(context).size.width;
    final hasSidebar = w >= 700;

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: Stack(
        children: [
          Row(
            children: [
              // ── SIDEBAR ──
              if (hasSidebar)
                _buildSidebar(context, auth, nombre, initial, email, carrito),

              // ── CONTENIDO ──
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(
                        context, auth, nombre, initial, carrito, !hasSidebar),
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
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
                                    _buildBuscadorProductos(context),
                                    const SizedBox(height: 12),
                                    _buildKpiRow(),
                                    const SizedBox(height: 20),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                            flex: 3,
                                            child: Column(children: [
                                              _buildPedidosRecientes(context),
                                            ])),
                                        if (w > 800) ...[
                                          const SizedBox(width: 16),
                                          Expanded(
                                              flex: 2,
                                              child: _buildTracking(context)),
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

          // ── ALPES BOT — burbuja flotante ──
          const Positioned(
            bottom: 24,
            right: 24,
            child: _AlpesBotBtn(),
          ),
        ],
      ),
      bottomNavigationBar:
          !hasSidebar ? const BottomNavCliente(currentIndex: 0) : null,
    );
  }

  // ── SIDEBAR ─────────────────────────────────────────────
  Widget _buildSidebar(BuildContext context, AuthProvider auth, String nombre,
      String initial, String email, CarritoProvider carrito) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AlpesColors.cafeOscuro,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(2, 0))
        ],
      ),
      child: Stack(children: [
        // Círculos decorativos
        Positioned(
            top: -30,
            right: -30,
            child: _circle(110, AlpesColors.oroGuatemalteco.withOpacity(0.07))),
        Positioned(
            bottom: 80,
            left: -30,
            child: _circle(90, AlpesColors.oroGuatemalteco.withOpacity(0.05))),
        Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: AlpesColors.oroGuatemalteco,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                            color: AlpesColors.oroGuatemalteco.withOpacity(0.4),
                            blurRadius: 8)
                      ]),
                  child: const Icon(Icons.chair_alt_rounded,
                      color: AlpesColors.cafeOscuro, size: 20),
                ),
                const SizedBox(width: 8),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Muebles de los Alpes',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                      Text('Portal del Cliente',
                          style: TextStyle(
                              color: AlpesColors.arenaCalida, fontSize: 9)),
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
                  Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: AlpesColors.oroGuatemalteco,
                          borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: Text(initial,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AlpesColors.cafeOscuro))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(nombre,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        if (email.isNotEmpty)
                          Text(email,
                              style: const TextStyle(
                                  color: AlpesColors.arenaCalida, fontSize: 9),
                              overflow: TextOverflow.ellipsis),
                      ])),
                ]),
              ),
            ]),
          ),
          const Divider(color: Colors.white12, height: 1),
          // ── MI CUENTA (colapsable) ──
          _sidebarGroupHeader('MI CUENTA', _miCuentaOpen,
              () => setState(() => _miCuentaOpen = !_miCuentaOpen)),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _miCuentaOpen
                ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(children: [
              _sidebarItem(Icons.home_rounded, 'Inicio', 'inicio', context),
              _sidebarItem(Icons.receipt_long_rounded, 'Mis pedidos',
                  'pedidos', context, route: '/mis-ordenes', badge: _enCamino),
              _sidebarItem(Icons.location_on_rounded, 'Tracking',
                  'tracking', context,
                  route: _ultimoEnvio != null
                      ? '/seguimiento/${_ultimoEnvio!["ORDEN_VENTA_ID"] ?? _ultimoEnvio!["orden_venta_id"]}'
                      : '/mis-ordenes'),
            ]),
          ),
          const Divider(color: Colors.white12, height: 1),
          // ── TIENDA (colapsable) ──
          _sidebarGroupHeader('TIENDA', _tiendaOpen,
              () => setState(() => _tiendaOpen = !_tiendaOpen)),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _tiendaOpen
                ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(children: [
              _sidebarItem(Icons.grid_view_rounded, 'Catálogo', 'catalogo',
                  context, route: '/catalogo'),
              _sidebarItem(Icons.history_rounded, 'Historial', 'historial',
                  context, route: '/mis-ordenes'),
              _sidebarItem(Icons.notifications_outlined, 'Notificaciones',
                  'notif', context, route: '/notificaciones'),
            ]),
          ),
          const Spacer(),
          const Divider(color: Colors.white12, height: 1),
          GestureDetector(
            onTap: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AlpesColors.rojoColonial.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AlpesColors.rojoColonial.withOpacity(0.3)),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.logout_rounded, color: AlpesColors.rojoColonial, size: 16),
                SizedBox(width: 8),
                Text('Cerrar sesión', style: TextStyle(
                    color: AlpesColors.rojoColonial, fontSize: 12,
                    fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 4),
        ]),
      ]),
    );
  }

  Widget _sidebarGroupHeader(String label, bool isOpen, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
          ),
          AnimatedRotation(
            turns: isOpen ? 0 : -0.25,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: Colors.white.withOpacity(0.4)),
          ),
        ]),
      ),
    );
  }

  Widget _sidebarSection(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
      );

  Widget _sidebarItem(
      IconData icon, String label, String seccion, BuildContext context,
      {String? route, int badge = 0}) {
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
          color: active
              ? AlpesColors.oroGuatemalteco.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active
              ? Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.3))
              : null,
        ),
        child: Row(children: [
          Icon(icon,
              size: 16,
              color: active
                  ? AlpesColors.oroGuatemalteco
                  : AlpesColors.arenaCalida),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active
                          ? Colors.white
                          : Colors.white.withOpacity(0.8)))),
          if (badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: AlpesColors.rojoColonial,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
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
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(height: 1, color: AlpesColors.pergamino)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            if (showHamburger)
              IconButton(
                icon: const Icon(Icons.menu_rounded,
                    color: AlpesColors.cafeOscuro),
                onPressed: () =>
                    _showMobileDrawer(context, auth, nombre, initial),
              ),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Bienvenida, $nombre',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AlpesColors.cafeOscuro)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: AlpesColors.oroGuatemalteco.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Cliente VIP',
                      style: TextStyle(
                          color: AlpesColors.oroGuatemalteco,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            )),
            // ── Campana con panel burbuja ──
            _NotifBellBtn(count: _enCamino),
            const SizedBox(width: 8),
            // ── Avatar → menú perfil ──
            _PerfilMenuBtn(initial: initial, nombre: nombre, auth: auth),
          ]),
        ),
      ]),
    );
  }

  void _showMobileDrawer(
      BuildContext context, AuthProvider auth, String nombre, String initial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AlpesColors.cafeOscuro,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          _buildSidebar(context, auth, nombre, initial, '',
              context.read<CarritoProvider>()),
        ]),
      ),
    );
  }

  // ── KPIs ─────────────────────────────────────────────────
  // Buscador inline
  final _searchCtrl2 = TextEditingController();
  String _searchQuery = '';

  Widget _buildBuscadorProductos(BuildContext context) {
    final productos = context.watch<ProductoProvider>();
    final query = _searchQuery.trim().toLowerCase();
    final resultados = query.isEmpty ? <Producto>[] :
        productos.productos.where((p) =>
            p.nombre.toLowerCase().contains(query) ||
            (p.descripcion ?? '').toLowerCase().contains(query) ||
            (p.tipo ?? '').toLowerCase().contains(query)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AlpesColors.pergamino),
          boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          const Icon(Icons.search_rounded, color: AlpesColors.arenaCalida, size: 20),
          const SizedBox(width: 10),
          Expanded(child: TextField(
            controller: _searchCtrl2,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontSize: 13, color: AlpesColors.cafeOscuro),
            decoration: const InputDecoration(
              hintText: 'Buscar muebles, salas, comedores\u2026',
              hintStyle: TextStyle(color: AlpesColors.arenaCalida, fontSize: 13),
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
            ),
          )),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () { _searchCtrl2.clear(); setState(() => _searchQuery = ''); },
              child: const Icon(Icons.close_rounded, color: AlpesColors.arenaCalida, size: 18),
            ),
        ]),
      ),
      if (resultados.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 6),
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AlpesColors.pergamino),
            boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ListView.separated(
              shrinkWrap: true, padding: EdgeInsets.zero,
              itemCount: resultados.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AlpesColors.pergamino),
              itemBuilder: (ctx, i) {
                final p = resultados[i];
                return GestureDetector(
                  onTap: () { setState(() => _searchQuery = ''); _searchCtrl2.clear(); ctx.push('/producto/${p.productoId}'); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8),
                        child: Container(width: 52, height: 52, color: AlpesColors.cremaFondo,
                          child: p.imagenUrl != null
                              ? Image.network(p.imagenUrl!, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.chair_alt_rounded, color: AlpesColors.arenaCalida, size: 24))
                              : const Icon(Icons.chair_alt_rounded, color: AlpesColors.arenaCalida, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (p.descripcion != null && p.descripcion!.isNotEmpty)
                          Text(p.descripcion!, style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (p.tipo != null)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.07), borderRadius: BorderRadius.circular(4)),
                            child: Text(p.tipo!, style: const TextStyle(fontSize: 9, color: AlpesColors.nogalMedio)),
                          ),
                      ])),
                      const SizedBox(width: 10),
                      if (p.precio != null)
                        Text('Q ${p.precio!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
                    ]),
                  ),
                );
              },
            ),
          ),
        )
      else if (_searchQuery.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AlpesColors.pergamino)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.search_off_rounded, color: AlpesColors.arenaCalida, size: 18),
            SizedBox(width: 8),
            Text('Sin resultados', style: TextStyle(color: AlpesColors.arenaCalida, fontSize: 13)),
          ]),
        ),
    ]);
  }

  Widget _buildKpiRow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _sectionLabel('Resumen de mi cuenta'),
        TextButton(
            onPressed: () => context.go('/perfil'),
            child: const Text('Ver perfil →',
                style: TextStyle(fontSize: 12, color: AlpesColors.nogalMedio))),
      ]),
      const SizedBox(height: 10),
      // ── 4 KPIs en una sola fila ──
      Row(children: [
        Expanded(child: _kpiCard(Icons.shopping_bag_rounded,
            '$_totalPedidos', 'PEDIDOS\nTOTALES', AlpesColors.cafeOscuro)),
        const SizedBox(width: 8),
        Expanded(child: _kpiCard(Icons.local_shipping_rounded,
            '$_enCamino', 'EN\nCAMINO', AlpesColors.verdeSelva)),
        const SizedBox(width: 8),
        Expanded(child: _kpiCard(Icons.check_circle_rounded,
            '$_entregados', 'ENTREGADOS', AlpesColors.oroGuatemalteco)),
        const SizedBox(width: 8),
        Expanded(child: _kpiCard(Icons.attach_money_rounded,
            'Q${_totalGastado >= 1000 ? '${(_totalGastado / 1000).toStringAsFixed(1)}k' : _totalGastado.toStringAsFixed(0)}',
            'TOTAL\nGASTADO', AlpesColors.rojoColonial)),
      ]),
    ]);
  }

  Widget _kpiCard(IconData icon, String value, String label, Color accent) =>
      Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AlpesColors.pergamino),
          boxShadow: [BoxShadow(
              color: AlpesColors.cafeOscuro.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: AlpesColors.cafeOscuro, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(
              fontSize: 8, color: AlpesColors.nogalMedio,
              fontWeight: FontWeight.w700, letterSpacing: 0.3, height: 1.2)),
        ]),
      );

  // ── PEDIDOS RECIENTES ────────────────────────────────────
  Widget _buildPedidosRecientes(BuildContext context) => _card(
        title: 'Mis pedidos recientes',
        action: TextButton(
            onPressed: () => context.go('/mis-ordenes'),
            child: const Text('Ver todos →',
                style: TextStyle(
                    fontSize: 12, color: AlpesColors.oroGuatemalteco))),
        child: _ordenesRecientes.isEmpty
            ? _emptyRow('Sin pedidos aún')
            : Column(children: [
                // Header tabla
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
                  child: Row(children: const [
                    Expanded(
                        flex: 2,
                        child: Text('PEDIDO',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AlpesColors.arenaCalida))),
                    Expanded(
                        flex: 3,
                        child: Text('PRODUCTO',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AlpesColors.arenaCalida))),
                    Expanded(
                        flex: 2,
                        child: Text('FECHA',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AlpesColors.arenaCalida))),
                    Expanded(
                        flex: 2,
                        child: Text('TOTAL',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AlpesColors.arenaCalida),
                            textAlign: TextAlign.right)),
                  ]),
                ),
                const Divider(height: 1, color: AlpesColors.pergamino),
                ..._ordenesRecientes.map((o) {
                  final id = o['ORDEN_VENTA_ID'] ?? o['orden_venta_id'];
                  final num = o['NUM_ORDEN'] ?? o['num_orden'] ?? '#$id';
                  final total =
                      double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0;
                  final fecha = (o['FECHA_ORDEN'] ?? o['fecha_orden'] ?? '')
                      .toString()
                      .split('T')
                      .first;
                  final prod = o['PRODUCTO'] ?? o['producto'] ?? 'Mueble Alpes';
                  return GestureDetector(
                    onTap: () => context.go('/orden/$id'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Expanded(
                            flex: 2,
                            child: Text('#$num',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AlpesColors.oroGuatemalteco))),
                        Expanded(
                            flex: 3,
                            child: Text(prod.toString(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AlpesColors.cafeOscuro),
                                overflow: TextOverflow.ellipsis)),
                        Expanded(
                            flex: 2,
                            child: Text(fecha,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AlpesColors.nogalMedio))),
                        Expanded(
                            flex: 2,
                            child: Text('Q${total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AlpesColors.cafeOscuro),
                                textAlign: TextAlign.right)),
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
                Text(
                    'Pedido #${_ultimoEnvio!['NUM_ORDEN'] ?? _ultimoEnvio!['num_orden'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AlpesColors.oroGuatemalteco)),
                const Text('Sofá Alpino — estimado',
                    style:
                        TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
                const SizedBox(height: 16),
                _trackingStep('Pedido confirmado', 'completado',
                    subtitle: 'Confirmado'),
                _trackingStep('En producción', 'activo',
                    subtitle: 'En proceso'),
                _trackingStep('En camino a la dirección', 'pendiente',
                    subtitle: 'Est. próximamente'),
                _trackingStep('Entregado', 'pendiente',
                    subtitle: 'Est. próximamente'),
              ]),
      );

  Widget _trackingStep(String label, String estado, {String? subtitle}) {
    final Color color;
    final Widget dot;
    switch (estado) {
      case 'completado':
        color = const Color(0xFF3B6D11);
        dot = Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
                color: Color(0xFF3B6D11), shape: BoxShape.circle),
            child:
                const Icon(Icons.check_rounded, color: Colors.white, size: 10));
        break;
      case 'activo':
        color = AlpesColors.oroGuatemalteco;
        dot = Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
                border:
                    Border.all(color: AlpesColors.oroGuatemalteco, width: 2),
                shape: BoxShape.circle),
            child: Center(
                child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: AlpesColors.oroGuatemalteco,
                        shape: BoxShape.circle))));
        break;
      default:
        color = AlpesColors.arenaCalida;
        dot = Container(
            width: 16,
            height: 16,
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
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          if (subtitle != null)
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 10, color: AlpesColors.nogalMedio)),
        ])),
      ]),
    );
  }

  // ── MÉTODOS DE PAGO ──────────────────────────────────────
  Widget _buildMetodosPago(BuildContext context) => _card(
        title: 'Mis métodos de pago',
        action: TextButton(
          onPressed: () => context.go('/mis-tarjetas'),
          child: const Text('Gestionar tarjetas',
              style: TextStyle(fontSize: 12, color: AlpesColors.nogalMedio)),
        ),
        child: _tarjetas.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Icon(Icons.credit_card_outlined,
                      color: AlpesColors.arenaCalida.withOpacity(0.5),
                      size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Sin tarjetas registradas',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AlpesColors.cafeOscuro)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => context.go('/mis-tarjetas'),
                          child: const Text('+ Agregar tarjeta',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AlpesColors.oroGuatemalteco,
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
    final marca = (t['MARCA'] ?? t['marca'] ?? 'VISA').toString();
    final ultimos = (t['ULTIMOS_4'] ?? t['ultimos_4'] ?? '****').toString();
    final titular = (t['TITULAR'] ?? t['titular'] ?? '').toString();
    final mes = t['MES_VENCIMIENTO'] ?? t['mes_vencimiento'] ?? '';
    final anio = t['ANIO_VENCIMIENTO'] ?? t['anio_vencimiento'] ?? '';
    final esPred = (t['PREDETERMINADA'] ?? t['predeterminada'] ?? 0) == 1;

    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 12, top: 8, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: esPred
              ? [AlpesColors.cafeOscuro, const Color(0xFF3D2416)]
              : [AlpesColors.nogalMedio, AlpesColors.cafeOscuro],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: AlpesColors.cafeOscuro.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(marca,
              style: const TextStyle(
                  color: AlpesColors.oroGuatemalteco,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
          if (esPred)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('✓ Principal',
                  style: TextStyle(
                      color: AlpesColors.oroGuatemalteco,
                      fontSize: 8,
                      fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 8),
        Text('•••• •••• •••• $ultimos',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(titular,
              style: const TextStyle(
                  color: AlpesColors.arenaCalida, fontSize: 10)),
          Text('Vence $mes/$anio',
              style: const TextStyle(
                  color: AlpesColors.arenaCalida, fontSize: 10)),
        ]),
      ]),
    );
  }

  // ── ACCESOS RÁPIDOS ──────────────────────────────────────
  Widget _buildAccesosRapidos(BuildContext context) {
    final accesos = [
      {
        'icon': Icons.grid_view_rounded,
        'label': 'Catálogo',
        'route': '/catalogo'
      },
      {
        'icon': Icons.receipt_long_rounded,
        'label': 'Mis pedidos',
        'route': '/mis-ordenes'
      },
      {
        'icon': Icons.favorite_rounded,
        'label': 'Favoritos',
        'route': '/favoritos'
      },
      {
        'icon': Icons.star_rate_rounded,
        'label': 'Mis reseñas',
        'route': '/mis-resenas'
      },
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('Accesos rápidos'),
      const SizedBox(height: 10),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.8,
        children: accesos
            .map((a) => GestureDetector(
                  onTap: () => context.go(a['route'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AlpesColors.pergamino),
                      boxShadow: [
                        BoxShadow(
                            color: AlpesColors.cafeOscuro.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(a['icon'] as IconData,
                              size: 18, color: AlpesColors.cafeOscuro),
                          const SizedBox(width: 6),
                          Text(a['label'] as String,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AlpesColors.cafeOscuro)),
                        ]),
                  ),
                ))
            .toList(),
      ),
    ]);
  }

  // ── HELPERS ─────────────────────────────────────────────
  Widget _card(
          {required String title, required Widget child, Widget? action}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AlpesColors.pergamino),
          boxShadow: [
            BoxShadow(
                color: AlpesColors.cafeOscuro.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
        Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AlpesColors.cafeOscuro)),
      ]);

  Widget _emptyRow(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: Text(msg,
                style: const TextStyle(
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
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : AlpesColors.cafeOscuro)),
        ),
      );

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ─────────────────────────────────────────────────────────
//  SIDEBAR GROUP HEADER — colapsable
// ─────────────────────────────────────────────────────────
// NOTE: defined inside the State class via extension below

// ─────────────────────────────────────────────────────────
//  CAMPANA CON BURBUJA — OverlayEntry para Flutter Web
// ─────────────────────────────────────────────────────────
class _NotifBellBtn extends StatefulWidget {
  final int count;
  const _NotifBellBtn({required this.count});
  @override
  State<_NotifBellBtn> createState() => _NotifBellBtnState();
}

class _NotifBellBtnState extends State<_NotifBellBtn> {
  OverlayEntry? _overlay;
  final _key = GlobalKey();

  void _toggle() {
    if (_overlay != null) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Tap fuera para cerrar
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          // Panel
          Positioned(
            top: pos.dy + box.size.height + 6,
            right: 8,
            child: Material(
              color: Colors.transparent,
              child: _NotifPanel(onClose: _close),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(alignment: Alignment.topRight, children: [
          Icon(
            _overlay != null
                ? Icons.notifications_rounded
                : Icons.notifications_outlined,
            color: _overlay != null
                ? AlpesColors.oroGuatemalteco
                : AlpesColors.cafeOscuro,
            size: 22,
          ),
          if (widget.count > 0)
            Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(
                  color: AlpesColors.rojoColonial, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('${widget.count}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PANEL DE NOTIFICACIONES
// ─────────────────────────────────────────────────────────
class _NotifPanel extends StatefulWidget {
  final VoidCallback onClose;
  const _NotifPanel({required this.onClose});
  @override
  State<_NotifPanel> createState() => _NotifPanelState();
}

class _NotifPanelState extends State<_NotifPanel> {
  List<_NotifItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final lista = <_NotifItem>[];
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = data['data'] as List;
        final pend = list.where((o) =>
            (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase() == 'pendiente').length;
        if (pend > 0) lista.add(_NotifItem(
          id: 'pend', titulo: '$pend orden${pend > 1 ? "es" : ""} pendiente${pend > 1 ? "s" : ""}',
          sub: 'Requieren atención', icon: Icons.receipt_long_rounded,
          color: const Color(0xFF854F0B), route: '/admin/ordenes'));
        final proc = list.where((o) {
          final e = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
          return e == 'en proceso' || e == 'en camino' || e == 'enviado';
        }).length;
        if (proc > 0) lista.add(_NotifItem(
          id: 'proc', titulo: '$proc orden${proc > 1 ? "es" : ""} en proceso',
          sub: 'En preparación o camino', icon: Icons.local_shipping_rounded,
          color: const Color(0xFF185FA5), route: '/admin/ordenes'));
      }
    } catch (_) {}
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventarioProducto}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = data['data'] as List;
        final bajo = list.where((i) =>
            (int.tryParse('${i["CANTIDAD"] ?? i["cantidad"] ?? 0}') ?? 0) <= 5).length;
        if (bajo > 0) lista.add(_NotifItem(
          id: 'stock', titulo: '$bajo producto${bajo > 1 ? "s" : ""} con stock bajo',
          sub: 'Cantidad ≤ 5 unidades', icon: Icons.inventory_2_rounded,
          color: AlpesColors.rojoColonial, route: '/admin/inventario'));
      }
    } catch (_) {}
    if (lista.isEmpty) lista.add(_NotifItem(
      id: 'ok', titulo: 'Todo al día ✓', sub: 'Sin alertas pendientes',
      icon: Icons.check_circle_rounded, color: const Color(0xFF3B6D11)));
    if (mounted) setState(() { _items = lista; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18),
              blurRadius: 28, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: const BoxDecoration(
            color: AlpesColors.cafeOscuro,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(Icons.notifications_rounded,
                color: AlpesColors.oroGuatemalteco, size: 18),
            const SizedBox(width: 8),
            const Expanded(child: Text('Notificaciones',
                style: TextStyle(color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w700))),
            if (_items.any((n) => !n.leida))
              GestureDetector(
                onTap: () => setState(() { for (final n in _items) n.leida = true; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
                  ),
                  child: const Text('Marcar todas',
                      style: TextStyle(color: AlpesColors.oroGuatemalteco,
                          fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ),
          ]),
        ),
        // Lista
        _loading
            ? const Padding(padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(color: AlpesColors.cafeOscuro, strokeWidth: 2))
            : Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1,
                      indent: 16, endIndent: 16, color: AlpesColors.pergamino),
                  itemBuilder: (ctx, i) {
                    final n = _items[i];
                    return GestureDetector(
                      onTap: () {
                        setState(() => n.leida = true);
                        if (n.route != null) {
                          widget.onClose();
                          ctx.go(n.route!);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        color: n.leida ? Colors.transparent : n.color.withOpacity(0.04),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: n.leida ? AlpesColors.pergamino : n.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(n.icon,
                                color: n.leida ? AlpesColors.arenaCalida : n.color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(n.titulo, style: TextStyle(fontSize: 13,
                                fontWeight: n.leida ? FontWeight.w400 : FontWeight.w600,
                                color: n.leida ? AlpesColors.nogalMedio : AlpesColors.cafeOscuro)),
                            Text(n.sub, style: const TextStyle(fontSize: 11,
                                color: AlpesColors.nogalMedio)),
                          ])),
                          if (!n.leida)
                            Container(width: 8, height: 8,
                                decoration: BoxDecoration(color: n.color, shape: BoxShape.circle))
                          else if (n.route != null)
                            const Icon(Icons.chevron_right_rounded,
                                color: AlpesColors.arenaCalida, size: 16),
                        ]),
                      ),
                    );
                  },
                ),
              ),
        // Footer
        Container(
          decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AlpesColors.pergamino))),
          child: TextButton.icon(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Actualizar', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: AlpesColors.nogalMedio),
          ),
        ),
      ]),
    );
  }
}

class _NotifItem {
  final String id, titulo, sub;
  final IconData icon;
  final Color color;
  final String? route;
  bool leida;
  _NotifItem({required this.id, required this.titulo, required this.sub,
      required this.icon, required this.color, this.route, this.leida = false});
}

// ─────────────────────────────────────────────────────────
//  AVATAR → MENÚ PERFIL (popup)
// ─────────────────────────────────────────────────────────
class _PerfilMenuBtn extends StatelessWidget {
  final String initial, nombre;
  final AuthProvider auth;
  const _PerfilMenuBtn({required this.initial, required this.nombre, required this.auth});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      onSelected: (val) async {
        if (val == 'perfil') context.go('/perfil');
        if (val == 'tarjetas') context.go('/mis-tarjetas');
        if (val == 'logout') {
          await auth.logout();
          if (context.mounted) context.go('/login');
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
                    borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: Text(initial, style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w800, color: AlpesColors.cafeOscuro))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AlpesColors.cafeOscuro), overflow: TextOverflow.ellipsis),
                const Text('Cliente', style: TextStyle(fontSize: 11,
                    color: AlpesColors.nogalMedio)),
              ])),
            ]),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AlpesColors.pergamino),
          ]),
        ),
        PopupMenuItem(value: 'perfil',
          child: Row(children: [
            Container(width: 30, height: 30,
                decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.person_outline_rounded, size: 16,
                    color: AlpesColors.cafeOscuro)),
            const SizedBox(width: 10),
            const Text('Mi perfil', style: TextStyle(fontSize: 13, color: AlpesColors.cafeOscuro)),
          ]),
        ),
        PopupMenuItem(value: 'tarjetas',
          child: Row(children: [
            Container(width: 30, height: 30,
                decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.credit_card_rounded, size: 16,
                    color: AlpesColors.cafeOscuro)),
            const SizedBox(width: 10),
            const Text('Mis tarjetas', style: TextStyle(fontSize: 13, color: AlpesColors.cafeOscuro)),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'logout',
          child: Row(children: [
            Container(width: 30, height: 30,
                decoration: BoxDecoration(color: AlpesColors.rojoColonial.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.logout_rounded, size: 16,
                    color: AlpesColors.rojoColonial)),
            const SizedBox(width: 10),
            const Text('Cerrar sesión', style: TextStyle(fontSize: 13,
                color: AlpesColors.rojoColonial)),
          ]),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AlpesColors.oroGuatemalteco,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [BoxShadow(color: AlpesColors.oroGuatemalteco.withOpacity(0.3), blurRadius: 8)],
        ),
        width: 34, height: 34,
        alignment: Alignment.center,
        child: Text(initial, style: const TextStyle(fontSize: 14,
            fontWeight: FontWeight.w800, color: AlpesColors.cafeOscuro)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  ALPES BOT — Burbuja flotante con chat inline
// ─────────────────────────────────────────────────────────
class _AlpesBotBtn extends StatefulWidget {
  const _AlpesBotBtn();
  @override
  State<_AlpesBotBtn> createState() => _AlpesBotBtnState();
}

class _AlpesBotBtnState extends State<_AlpesBotBtn>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _typing  = false;

  final List<_BotMsg> _msgs = [
    const _BotMsg('¡Hola! 👋 Soy **AlpesBot**.\n¿En qué te puedo ayudar?', false),
  ];

  final _quickReplies = ['¿Cuál es su horario?', '¿Dónde están?', 'Ver productos', 'Mi pedido'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 260));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() { _animCtrl.dispose(); _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _animCtrl.forward() : _animCtrl.reverse();
  }

  String _responder(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('horario') || m.contains('hora') || m.contains('abren'))
      return '🕐 **Horarios:**\n• Lun–Vie: 8AM–6PM\n• Sáb: 9AM–5PM\n• Dom: 10AM–2PM';
    if (m.contains('ubica') || m.contains('donde') || m.contains('direcci'))
      return '📍 **Sucursales:**\n• Zona 10, Ciudad de Guatemala\n• Zona 18, Ciudad de Guatemala\n• Antigua Guatemala';
    if (m.contains('product') || m.contains('mueble') || m.contains('cat') || m.contains('ver'))
      return '🛋️ ¡Tenemos salas, comedores, dormitorios y más!\n\n¿Te llevo al catálogo?';
    if (m.contains('pedido') || m.contains('orden') || m.contains('seguim'))
      return '📦 Revisa tus pedidos en **"Mis pedidos"** del menú lateral o en la sección Tracking.';
    if (m.contains('si') || m.contains('sí') || m.contains('claro') || m.contains('dale'))
      return '¡Perfecto! Ve a **Catálogo** en el menú. 🛋️';
    if (m.contains('gracias') || m.contains('ok') || m.contains('listo'))
      return '😊 ¡Con gusto! Aquí estaré si necesitas algo más.';
    return '🤖 Puedo ayudarte con horarios, ubicaciones, productos o pedidos.\n¿Qué necesitas?';
  }

  void _enviar([String? texto]) {
    final msg = (texto ?? _ctrl.text).trim();
    if (msg.isEmpty) return;
    final now = DateTime.now();
    final hora = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
    setState(() { _msgs.add(_BotMsg(msg, true, hora: hora)); _ctrl.clear(); _typing = true; });
    _scrollFinal();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _msgs.add(_BotMsg(_responder(msg), false,
            hora: '${DateTime.now().hour.toString().padLeft(2,'0')}:${DateTime.now().minute.toString().padLeft(2,'0')}'));
      });
      _scrollFinal();
    });
  }

  void _scrollFinal() => Future.delayed(const Duration(milliseconds: 100), () {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Panel chat
        if (_open)
          ScaleTransition(
            scale: _scaleAnim,
            alignment: Alignment.bottomRight,
            child: Container(
              width: 320,
              height: 420,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18),
                    blurRadius: 28, offset: const Offset(0, 8))],
              ),
              child: Column(children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  decoration: const BoxDecoration(
                    color: AlpesColors.cafeOscuro,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(children: [
                    Container(width: 34, height: 34,
                        decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
                            borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.support_agent_rounded,
                            color: AlpesColors.cafeOscuro, size: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('AlpesBot', style: TextStyle(color: Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w700)),
                      Row(children: [
                        Container(width: 6, height: 6,
                            decoration: const BoxDecoration(color: Color(0xFF4CAF50),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('En línea', style: TextStyle(
                            color: AlpesColors.arenaCalida, fontSize: 10)),
                      ]),
                    ])),
                    GestureDetector(onTap: _toggle,
                        child: const Icon(Icons.close_rounded, color: Colors.white54, size: 20)),
                  ]),
                ),
                // Mensajes
                Expanded(child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(10),
                  itemCount: _msgs.length + (_typing ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_typing && i == _msgs.length) return _buildTyping();
                    final m = _msgs[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: m.esUsuario
                            ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!m.esUsuario) ...[
                            Container(width: 22, height: 22,
                                decoration: const BoxDecoration(
                                    color: AlpesColors.cafeOscuro, shape: BoxShape.circle),
                                child: const Icon(Icons.support_agent_rounded,
                                    color: AlpesColors.oroGuatemalteco, size: 12)),
                            const SizedBox(width: 6),
                          ],
                          Flexible(child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            constraints: const BoxConstraints(maxWidth: 230),
                            decoration: BoxDecoration(
                              color: m.esUsuario ? AlpesColors.cafeOscuro : AlpesColors.cremaFondo,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: Radius.circular(m.esUsuario ? 12 : 3),
                                bottomRight: Radius.circular(m.esUsuario ? 3 : 12),
                              ),
                              border: !m.esUsuario ? Border.all(color: AlpesColors.pergamino) : null,
                            ),
                            child: Text(m.texto, style: TextStyle(fontSize: 12, height: 1.4,
                                color: m.esUsuario ? Colors.white : AlpesColors.cafeOscuro)),
                          )),
                        ],
                      ),
                    );
                  },
                )),
                // Quick replies
                SizedBox(height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    itemCount: _quickReplies.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _enviar(_quickReplies[i]),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AlpesColors.cafeOscuro.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AlpesColors.cafeOscuro.withOpacity(0.15)),
                        ),
                        child: Text(_quickReplies[i], style: const TextStyle(
                            fontSize: 10, color: AlpesColors.cafeOscuro, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),
                // Input
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AlpesColors.pergamino)),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  ),
                  child: Row(children: [
                    Expanded(child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _enviar(),
                      textInputAction: TextInputAction.send,
                      style: const TextStyle(fontSize: 12, color: AlpesColors.cafeOscuro),
                      decoration: InputDecoration(
                        hintText: 'Escribe tu pregunta…',
                        hintStyle: const TextStyle(color: AlpesColors.arenaCalida, fontSize: 12),
                        filled: true, fillColor: AlpesColors.cremaFondo,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                    )),
                    const SizedBox(width: 8),
                    GestureDetector(onTap: _enviar,
                      child: Container(width: 36, height: 36,
                        decoration: const BoxDecoration(
                            color: AlpesColors.cafeOscuro, shape: BoxShape.circle),
                        child: const Icon(Icons.send_rounded,
                            color: AlpesColors.oroGuatemalteco, size: 16)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),

        // Botón burbuja
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _open ? AlpesColors.rojoColonial : AlpesColors.cafeOscuro,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: AlpesColors.cafeOscuro.withOpacity(0.4),
                  blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Icon(
              _open ? Icons.close_rounded : Icons.chat_bubble_rounded,
              color: AlpesColors.oroGuatemalteco, size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTyping() => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Container(width: 22, height: 22,
          decoration: const BoxDecoration(color: AlpesColors.cafeOscuro, shape: BoxShape.circle),
          child: const Icon(Icons.support_agent_rounded,
              color: AlpesColors.oroGuatemalteco, size: 12)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AlpesColors.cremaFondo,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AlpesColors.pergamino)),
        child: Row(mainAxisSize: MainAxisSize.min, children: const [
          _BotDot(delay: 0), SizedBox(width: 4),
          _BotDot(delay: 200), SizedBox(width: 4),
          _BotDot(delay: 400),
        ]),
      ),
    ]),
  );
}

class _BotDot extends StatefulWidget {
  final int delay;
  const _BotDot({required this.delay});
  @override State<_BotDot> createState() => _BotDotState();
}
class _BotDotState extends State<_BotDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(width: 6, height: 6,
        decoration: const BoxDecoration(color: AlpesColors.arenaCalida, shape: BoxShape.circle)),
  );
}

class _BotMsg {
  final String texto;
  final bool esUsuario;
  final String? hora;
  const _BotMsg(this.texto, this.esUsuario, {this.hora});
}
