import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/carrito_provider.dart';
import '../../providers/producto_provider.dart';
import '../../providers/favoritos_provider.dart';
import '../../widgets/bottom_nav_cliente.dart';
import 'mis_tarjetas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _sidebarIndex = 0;
  bool _sidebarCollapsed = false;
  bool _miCuentaExpanded = true;
  bool _tiendaExpanded = true;
  List<_TarjetaItem> _tarjetas = [];
  bool _loadingTarjetas = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<ProductoProvider>().cargarProductos();
      if (auth.clienteId != null) {
        context.read<CarritoProvider>().cargarCarrito(auth.clienteId!);
        context.read<FavoritosProvider>().cargarFavoritos(auth.clienteId!);
        _cargarTarjetas(auth.clienteId!);
      }
    });
  }

  Future<void> _cargarTarjetas(int cliId) async {
    setState(() => _loadingTarjetas = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/tarjetas-cliente/cliente/$cliId'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final lista = List<Map<String, dynamic>>.from(data['data']);
        setState(() {
          _tarjetas = lista.map((t) {
            final marca = (t['MARCA'] ?? t['marca'] ?? 'VISA').toString();
            final ultimos4 = (t['ULTIMOS_4'] ?? t['ultimos_4'] ?? '****').toString();
            final titular = (t['TITULAR'] ?? t['titular'] ?? '').toString();
            final mes = t['MES_VENCIMIENTO'] ?? t['mes_vencimiento'] ?? '';
            final anio = t['ANIO_VENCIMIENTO'] ?? t['anio_vencimiento'] ?? '';
            final esPred = (t['PREDETERMINADA'] ?? t['predeterminada'] ?? 0) == 1;
            return _TarjetaItem(
              brand: marca, brandLabel: marca.toUpperCase(),
              number: '**** **** **** $ultimos4', holder: titular.toUpperCase(),
              expiry: 'Vence $mes/$anio',
              bgColor: esPred ? const Color(0xFF2C1A0E) : const Color(0xFF5C3D1E),
            );
          }).toList();
        });
      }
    } catch (_) {}
    setState(() => _loadingTarjetas = false);
  }

  final List<_PedidoItem> _pedidos = const [
    _PedidoItem('#ORD-0042', 'Sofá 3 plazas Alpino', '12 Abr 2026', 'Q1,890'),
    _PedidoItem('#ORD-0039', 'Mesa de comedor 8p.', '28 Mar 2026', 'Q950'),
    _PedidoItem('#ORD-0035', 'Silla ejecutiva Pro', '15 Mar 2026', 'Q620'),
    _PedidoItem('#ORD-0031', 'Estante modular 4 niv.', '01 Mar 2026', 'Q380'),
    _PedidoItem('#ORD-0028', 'Cama matrimonial Noble', '20 Feb 2026', 'Q1,200'),
  ];

  final List<_TrackStep> _trackSteps = const [
    _TrackStep('Pedido confirmado', '12 Abr · 10:30 AM', _StepStatus.done),
    _TrackStep('En producción', 'Inicio: 13 Abr · 08:00 AM', _StepStatus.active),
    _TrackStep('En camino a la dirección', 'Est. 18 Abr 2026', _StepStatus.pending),
    _TrackStep('Entregado', 'Est. 20 Abr 2026', _StepStatus.pending),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final carrito = context.watch<CarritoProvider>();
    final usuario = auth.usuario ?? {};
    final String nombre = _obtenerNombre(usuario);
    final String correo = _obtenerCorreo(usuario);
    final bool isWide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F2),
      // Burbuja flotante de Soporte/Chat
      floatingActionButton: _SoporteFAB(onTap: () => context.go('/soporte')),
      body: isWide
          ? Row(children: [
              _Sidebar(
                selectedIndex: _sidebarIndex,
                nombre: nombre,
                correo: correo,
                collapsed: _sidebarCollapsed,
                miCuentaExpanded: _miCuentaExpanded,
                tiendaExpanded: _tiendaExpanded,
                onToggleCollapse: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                onToggleMiCuenta: () => setState(() => _miCuentaExpanded = !_miCuentaExpanded),
                onToggleTienda: () => setState(() => _tiendaExpanded = !_tiendaExpanded),
                onSelect: (i) => setState(() => _sidebarIndex = i),
                onNavigate: (ruta) => context.go(ruta),
              ),
              Expanded(
                child: _MainContent(
                  nombre: nombre, correo: correo, carrito: carrito,
                  pedidos: _pedidos, trackSteps: _trackSteps,
                  tarjetas: _tarjetas, loadingTarjetas: _loadingTarjetas,
                  onNavigate: (ruta) => context.go(ruta),
                  onAgregarTarjeta: () => _irATarjetas(context, auth),
                ),
              ),
            ])
          : Scaffold(
              backgroundColor: const Color(0xFFFAF6F2),
              appBar: _buildMobileAppBar(context, carrito),
              body: _MainContent(
                nombre: nombre, correo: correo, carrito: carrito,
                pedidos: _pedidos, trackSteps: _trackSteps,
                tarjetas: _tarjetas, loadingTarjetas: _loadingTarjetas,
                onNavigate: (ruta) => context.go(ruta),
                onAgregarTarjeta: () => _irATarjetas(context, auth),
              ),
              bottomNavigationBar: const BottomNavCliente(currentIndex: 0),
            ),
    );
  }

  void _irATarjetas(BuildContext context, AuthProvider auth) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MisTarjetasScreen()))
        .then((_) { if (auth.clienteId != null) _cargarTarjetas(auth.clienteId!); });
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, CarritoProvider carrito) {
    return AppBar(
      backgroundColor: const Color(0xFF2C1A0E),
      title: const Text('MUEBLES DE LOS ALPES', style: TextStyle(fontSize: 13, letterSpacing: 0.5)),
      actions: [
        badges.Badge(
          badgeContent: Text('${carrito.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 10)),
          showBadge: carrito.totalItems > 0,
          child: IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () => context.go('/carrito')),
        ),
        IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.go('/notificaciones')),
        const SizedBox(width: 4),
      ],
    );
  }

  String _obtenerNombre(Map usuario) {
    return (usuario['NOMBRE_COMPLETO'] ?? usuario['nombre_completo'] ??
            usuario['NOMBRE'] ?? usuario['nombre'] ??
            usuario['USERNAME'] ?? usuario['username'] ?? 'Bienvenido').toString();
  }

  String _obtenerCorreo(Map usuario) {
    return (usuario['CORREO'] ?? usuario['correo'] ??
            usuario['EMAIL'] ?? usuario['email'] ?? 'correo@cliente.com').toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FAB SOPORTE — burbuja flotante
// ═══════════════════════════════════════════════════════════════════════════════
class _SoporteFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _SoporteFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF2C1A0E),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIDEBAR COLAPSABLE
// ═══════════════════════════════════════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final String nombre;
  final String correo;
  final bool collapsed;
  final bool miCuentaExpanded;
  final bool tiendaExpanded;
  final VoidCallback onToggleCollapse;
  final VoidCallback onToggleMiCuenta;
  final VoidCallback onToggleTienda;
  final void Function(int) onSelect;
  final void Function(String) onNavigate;

  const _Sidebar({
    required this.selectedIndex, required this.nombre, required this.correo,
    required this.collapsed, required this.miCuentaExpanded, required this.tiendaExpanded,
    required this.onToggleCollapse, required this.onToggleMiCuenta, required this.onToggleTienda,
    required this.onSelect, required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: collapsed ? 58 : 230,
      color: const Color(0xFF2C1A0E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
              child: Row(
                children: [
                  if (!collapsed) ...[
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Muebles de los Alpes', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('Portal del Cliente', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 9)),
                        ],
                      ),
                    ),
                  ],
                  GestureDetector(
                    onTap: onToggleCollapse,
                    child: Icon(collapsed ? Icons.menu : Icons.menu_open, color: Colors.white.withOpacity(0.7), size: 18),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.08)),

          // MI CUENTA
          if (!collapsed)
            _SidebarSectionHeader(label: 'MI CUENTA', expanded: miCuentaExpanded, onTap: onToggleMiCuenta),
          if (miCuentaExpanded || collapsed) ...[
            _SidebarItem(icon: Icons.grid_view_rounded, label: 'Inicio', isActive: selectedIndex == 0, collapsed: collapsed,
                onTap: () { onSelect(0); onNavigate('/home'); }),
            _SidebarItem(icon: Icons.person_outline, label: 'Mi perfil', isActive: selectedIndex == 1, collapsed: collapsed,
                onTap: () { onSelect(1); onNavigate('/perfil'); }),
            _SidebarItem(icon: Icons.credit_card_outlined, label: 'Mis tarjetas', isActive: selectedIndex == 2, collapsed: collapsed,
                onTap: () { onSelect(2); onNavigate('/mis-tarjetas'); }),
            _SidebarItem(icon: Icons.shopping_bag_outlined, label: 'Mis pedidos', badge: '3', isActive: selectedIndex == 3, collapsed: collapsed,
                onTap: () { onSelect(3); onNavigate('/mis-ordenes'); }),
            _SidebarItem(icon: Icons.location_on_outlined, label: 'Tracking', isActive: selectedIndex == 4, collapsed: collapsed,
                onTap: () { onSelect(4); onNavigate('/seguimiento'); }),
          ],

          // TIENDA
          if (!collapsed)
            _SidebarSectionHeader(label: 'TIENDA', expanded: tiendaExpanded, onTap: onToggleTienda),
          if (tiendaExpanded || collapsed) ...[
            _SidebarItem(icon: Icons.store_outlined, label: 'Catálogo', isActive: selectedIndex == 5, collapsed: collapsed,
                onTap: () { onSelect(5); onNavigate('/catalogo'); }),
            _SidebarItem(icon: Icons.history, label: 'Historial', isActive: selectedIndex == 6, collapsed: collapsed,
                onTap: () { onSelect(6); onNavigate('/mis-ordenes'); }),
            _SidebarItem(icon: Icons.notifications_outlined, label: 'Notificaciones', badge: '2', isActive: selectedIndex == 7, collapsed: collapsed,
                onTap: () { onSelect(7); onNavigate('/notificaciones'); }),
            _SidebarItem(icon: Icons.settings_outlined, label: 'Configuración', isActive: selectedIndex == 8, collapsed: collapsed,
                onTap: () => onSelect(8)),
          ],

          const Spacer(),
          Divider(height: 1, color: Colors.white.withOpacity(0.08)),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFFC8922A),
                    child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Color(0xFF2C1A0E), fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                        Text(correo, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0x55FFFFFF), fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFC8922A),
                  child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Color(0xFF2C1A0E), fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(collapsed ? 0 : 14, 4, 14, 14),
              child: GestureDetector(
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/login');
                },
                child: collapsed
                    ? const Center(child: Icon(Icons.logout, size: 14, color: Color(0x44FFFFFF)))
                    : const Row(children: [
                        Icon(Icons.logout, size: 12, color: Color(0x44FFFFFF)),
                        SizedBox(width: 6),
                        Text('Cerrar sesión', style: TextStyle(color: Color(0x44FFFFFF), fontSize: 11)),
                      ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSectionHeader extends StatelessWidget {
  final String label;
  final bool expanded;
  final VoidCallback onTap;
  const _SidebarSectionHeader({required this.label, required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        child: Row(
          children: [
            Expanded(child: Text(label,
                style: const TextStyle(color: Color(0x44FFFFFF), fontSize: 9, letterSpacing: 0.8, fontWeight: FontWeight.w500))),
            Icon(expanded ? Icons.expand_less : Icons.expand_more, color: const Color(0x44FFFFFF), size: 14),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool collapsed;
  final String? badge;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon, required this.label, required this.isActive,
    required this.collapsed, required this.onTap, this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: collapsed ? label : '',
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 10, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFC8922A).withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: collapsed
              ? Center(child: Icon(icon, size: 16,
                  color: isActive ? const Color(0xFFF0D5A0) : Colors.white.withOpacity(0.5)))
              : Row(children: [
                  Icon(icon, size: 15, color: isActive ? const Color(0xFFF0D5A0) : Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 9),
                  Expanded(child: Text(label,
                      style: TextStyle(fontSize: 12, color: isActive ? const Color(0xFFF0D5A0) : Colors.white.withOpacity(0.55)))),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFC86428), borderRadius: BorderRadius.circular(99)),
                      child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONTENIDO PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════
class _MainContent extends StatelessWidget {
  final String nombre;
  final String correo;
  final CarritoProvider carrito;
  final List<_PedidoItem> pedidos;
  final List<_TrackStep> trackSteps;
  final List<_TarjetaItem> tarjetas;
  final bool loadingTarjetas;
  final void Function(String) onNavigate;
  final VoidCallback onAgregarTarjeta;

  const _MainContent({
    required this.nombre, required this.correo, required this.carrito,
    required this.pedidos, required this.trackSteps, required this.tarjetas,
    required this.loadingTarjetas, required this.onNavigate, required this.onAgregarTarjeta,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1000;
    final bool isTablet = MediaQuery.of(context).size.width >= 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 20 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Wrap(
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bienvenida, $nombre',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFC8922A), borderRadius: BorderRadius.circular(99)),
                    child: const Text('Cliente VIP', style: TextStyle(color: Color(0xFF2C1A0E), fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  badges.Badge(
                    badgeContent: Text('${carrito.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    showBadge: carrito.totalItems > 0,
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Color(0xFF2C1A0E)),
                      onPressed: () => onNavigate('/notificaciones'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFFC8922A),
                    child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Color(0xFF2C1A0E), fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // RESUMEN
          _SectionCard(
            header: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Resumen de mi cuenta',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E))),
                OutlinedButton(
                  onPressed: () => onNavigate('/perfil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2C1A0E),
                    side: const BorderSide(color: Color(0x335C3D1E)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Ver perfil'),
                ),
              ],
            ),
            child: const Wrap(
              spacing: 10, runSpacing: 10,
              children: [
                _StatBox(icon: Icons.shopping_bag_outlined, iconColor: Color(0xFF1E5FA0), valor: '8', label: 'PEDIDOS\nTOTALES'),
                _StatBox(icon: Icons.local_shipping_outlined, iconColor: Color(0xFF1E8C5F), valor: '2', label: 'EN CAMINO'),
                _StatBox(icon: Icons.check_circle_outline, iconColor: Color(0xFF2A7A4B), valor: '5', label: 'ENTREGADOS'),
                _StatBox(icon: Icons.attach_money, iconColor: Color(0xFFC8922A), valor: 'Q4,250', label: 'TOTAL\nGASTADO', valorSize: 18),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // PEDIDOS + TRACKING
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 55, child: _PedidosSection(pedidos: pedidos, onNavigate: onNavigate)),
                const SizedBox(width: 16),
                Expanded(flex: 45, child: _TrackingSection(trackSteps: trackSteps)),
              ],
            )
          else
            Column(children: [
              _PedidosSection(pedidos: pedidos, onNavigate: onNavigate),
              const SizedBox(height: 16),
              _TrackingSection(trackSteps: trackSteps),
            ]),
          const SizedBox(height: 16),

          // TARJETAS
          _SectionCard(
            header: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mis métodos de pago',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E))),
                OutlinedButton(
                  onPressed: onAgregarTarjeta,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2C1A0E),
                    side: const BorderSide(color: Color(0x335C3D1E)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Gestionar tarjetas'),
                ),
              ],
            ),
            child: loadingTarjetas
                ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: Color(0xFF2C1A0E), strokeWidth: 2)))
                : tarjetas.isEmpty
                    ? Center(child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(children: [
                          const Icon(Icons.credit_card_off, size: 36, color: Color(0xFFA0714F)),
                          const SizedBox(height: 8),
                          const Text('No tienes tarjetas registradas.',
                              style: TextStyle(color: Color(0xFFA0714F), fontSize: 12)),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Agregar tarjeta'),
                            onPressed: onAgregarTarjeta,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2C1A0E),
                              side: const BorderSide(color: Color(0xFF2C1A0E)),
                            ),
                          ),
                        ]),
                      ))
                    : Wrap(
                        spacing: 12, runSpacing: 12,
                        children: tarjetas.map((t) => SizedBox(
                          width: isTablet ? 320 : double.infinity,
                          child: _PayCard(brand: t.brand, brandLabel: t.brandLabel,
                              number: t.number, holder: t.holder, expiry: t.expiry, bgColor: t.bgColor),
                        )).toList(),
                      ),
          ),
          const SizedBox(height: 16),

          // ACCESOS RÁPIDOS — más compactos (sin Soporte que ahora es FAB)
          _SectionCard(
            header: const Text('Accesos rápidos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E))),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 5 : 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: [
                _QuickTile(icon: Icons.person_outline, label: 'Editar perfil', onTap: () => onNavigate('/perfil')),
                _QuickTile(icon: Icons.credit_card_outlined, label: 'Mis tarjetas', onTap: onAgregarTarjeta),
                _QuickTile(icon: Icons.notifications_outlined, label: 'Notificaciones', onTap: () => onNavigate('/notificaciones')),
                _QuickTile(icon: Icons.attach_money, label: 'Historial de pagos', onTap: () => onNavigate('/mis-ordenes')),
                _QuickTile(icon: Icons.star_outline, label: 'Mis reseñas', onTap: () => onNavigate('/mis-resenas')),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ═══ SECCIONES ════════════════════════════════════════════════════════════════
class _PedidosSection extends StatelessWidget {
  final List<_PedidoItem> pedidos;
  final void Function(String) onNavigate;
  const _PedidosSection({required this.pedidos, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Mis pedidos recientes',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E))),
          GestureDetector(
            onTap: () => onNavigate('/mis-ordenes'),
            child: const Text('Ver todos →', style: TextStyle(fontSize: 11, color: Color(0xFFC8922A), fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: const [
            Expanded(flex: 3, child: _TabHead('PEDIDO')),
            Expanded(flex: 5, child: _TabHead('PRODUCTO')),
            Expanded(flex: 3, child: _TabHead('FECHA')),
            Expanded(flex: 2, child: _TabHead('TOTAL', align: TextAlign.right)),
          ]),
        ),
        const Divider(height: 1, color: Color(0x155C3D1E)),
        ...pedidos.map((p) => _PedidoRow(pedido: p, onTap: () => onNavigate('/mis-ordenes'))),
      ]),
    );
  }
}

class _TrackingSection extends StatelessWidget {
  final List<_TrackStep> trackSteps;
  const _TrackingSection({required this.trackSteps});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Tracking activo',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E))),
          Row(children: [
            _TabToggle(label: 'Detalle', isActive: true, onTap: () {}),
            const SizedBox(width: 6),
            _TabToggle(label: 'Línea', isActive: false, onTap: () {}),
          ]),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pedido #ORD-0042\nSofá 3 plazas Alpino',
              style: TextStyle(fontSize: 11, color: Color(0xFFC8922A), fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          ...List.generate(trackSteps.length,
              (i) => _TrackStepWidget(step: trackSteps[i], isLast: i == trackSteps.length - 1)),
        ],
      ),
    );
  }
}

// ═══ WIDGETS ══════════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final Widget header;
  final Widget child;
  const _SectionCard({required this.header, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A5C3D1E)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [header, const SizedBox(height: 14), child]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String valor;
  final String label;
  final double valorSize;
  const _StatBox({required this.icon, required this.iconColor, required this.valor, required this.label, this.valorSize = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x1A5C3D1E)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(valor, style: TextStyle(fontSize: valorSize, fontWeight: FontWeight.w700, color: const Color(0xFF2C1A0E))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFFA0714F), height: 1.3)),
        ]),
      ),
    );
  }
}

class _TabHead extends StatelessWidget {
  final String texto;
  final TextAlign align;
  const _TabHead(this.texto, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(texto, textAlign: align,
        style: const TextStyle(fontSize: 9, color: Color(0xFFA0714F), fontWeight: FontWeight.w500, letterSpacing: 0.4));
  }
}

class _PedidoRow extends StatelessWidget {
  final _PedidoItem pedido;
  final VoidCallback onTap;
  const _PedidoRow({required this.pedido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Expanded(flex: 3, child: Text(pedido.id, style: const TextStyle(color: Color(0xFFC8922A), fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(flex: 5, child: Text(pedido.producto, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF2C1A0E)))),
          Expanded(flex: 3, child: Text(pedido.fecha, style: const TextStyle(fontSize: 11, color: Color(0xFFA0714F)))),
          Expanded(flex: 2, child: Text(pedido.total, textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E)))),
        ]),
      ),
    );
  }
}

class _TabToggle extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabToggle({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2C1A0E) : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: isActive ? const Color(0xFF2C1A0E) : const Color(0x335C3D1E)),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, color: isActive ? Colors.white : const Color(0xFFA0714F))),
      ),
    );
  }
}

class _TrackStepWidget extends StatelessWidget {
  final _TrackStep step;
  final bool isLast;
  const _TrackStepWidget({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    Widget? dotInner;
    Color labelColor;

    switch (step.status) {
      case _StepStatus.done:
        dotColor = const Color(0xFF2A7A4B);
        dotInner = const Icon(Icons.check, size: 8, color: Colors.white);
        labelColor = const Color(0xFF2C1A0E);
        break;
      case _StepStatus.active:
        dotColor = const Color(0xFFC8922A);
        dotInner = Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white));
        labelColor = const Color(0xFFC8922A);
        break;
      case _StepStatus.pending:
        dotColor = const Color(0x225C3D1E);
        dotInner = null;
        labelColor = const Color(0xFFA0714F);
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(children: [
              Container(
                width: 16, height: 16,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                child: Center(child: dotInner ?? const SizedBox.shrink()),
              ),
              if (!isLast)
                Expanded(child: Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 3), color: const Color(0x1A5C3D1E))),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(step.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: labelColor)),
                const SizedBox(height: 2),
                Text(step.time, style: const TextStyle(fontSize: 10, color: Color(0xFFA0714F))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayCard extends StatelessWidget {
  final String brand;
  final String? brandLabel;
  final String number;
  final String holder;
  final String expiry;
  final Color bgColor;
  const _PayCard({required this.brand, this.brandLabel, required this.number, required this.holder, required this.expiry, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(brandLabel ?? brand, style: const TextStyle(color: Color(0x88FFFFFF), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(brand, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(number, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11, letterSpacing: 2, fontFamily: 'monospace')),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(holder, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0x88FFFFFF), fontSize: 9, letterSpacing: 0.5))),
            const SizedBox(width: 10),
            Text(expiry, style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 9)),
          ],
        ),
      ]),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5EDE4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x0F5C3D1E)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF5C3D1E)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: Color(0xFF5C3D1E), height: 1.3)),
          ],
        ),
      ),
    );
  }
}

// ═══ MODELOS ══════════════════════════════════════════════════════════════════
class _PedidoItem {
  final String id, producto, fecha, total;
  const _PedidoItem(this.id, this.producto, this.fecha, this.total);
}

class _TrackStep {
  final String label, time;
  final _StepStatus status;
  const _TrackStep(this.label, this.time, this.status);
}

class _TarjetaItem {
  final String brand, number, holder, expiry;
  final String? brandLabel;
  final Color bgColor;
  const _TarjetaItem({required this.brand, this.brandLabel, required this.number, required this.holder, required this.expiry, required this.bgColor});
}

enum _StepStatus { done, active, pending }
