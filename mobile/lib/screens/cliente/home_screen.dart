import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/carrito_provider.dart';
import '../../providers/producto_provider.dart';
import '../../providers/favoritos_provider.dart';
import '../../widgets/producto_card.dart';
import '../../widgets/bottom_nav_cliente.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _scrollCtrl   = ScrollController();
  final _searchCtrl   = TextEditingController();
  bool  _showTopBar   = true;
  bool  _drawerOpen   = false;
  String _searchText  = '';
  String _categoriaActiva = 'Todos';
  late AnimationController _drawerAnimCtrl;
  late Animation<double>   _drawerAnim;

  final _categorias = [
    {'label': 'Todos',       'icon': Icons.grid_view_rounded},
    {'label': 'Sala',        'icon': Icons.chair_alt_rounded},
    {'label': 'Comedor',     'icon': Icons.dining_rounded},
    {'label': 'Dormitorio',  'icon': Icons.bed_rounded},
    {'label': 'Oficina',     'icon': Icons.desk_rounded},
    {'label': 'Exterior',    'icon': Icons.deck_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _drawerAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _drawerAnim = CurvedAnimation(parent: _drawerAnimCtrl, curve: Curves.easeOutCubic);
    _scrollCtrl.addListener(() {
      final going = _scrollCtrl.position.userScrollDirection == ScrollDirection.forward;
      if (going != _showTopBar) setState(() => _showTopBar = going);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<ProductoProvider>().cargarProductos();
      if (auth.clienteId != null) {
        context.read<CarritoProvider>().cargarCarrito(auth.clienteId!);
        context.read<FavoritosProvider>().cargarFavoritos(auth.clienteId!);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _drawerAnimCtrl.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() => _drawerOpen = !_drawerOpen);
    _drawerOpen ? _drawerAnimCtrl.forward() : _drawerAnimCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final carrito   = context.watch<CarritoProvider>();
    final productos = context.watch<ProductoProvider>();
    final nombre    = auth.nombreCompleto;

    // Filtrado
    var lista = _categoriaActiva == 'Todos'
        ? productos.productos
        : productos.productos.where((p) =>
            (p.tipo ?? '').toLowerCase().contains(_categoriaActiva.toLowerCase())).toList();
    if (_searchText.isNotEmpty) {
      lista = lista.where((p) =>
          p.nombre.toLowerCase().contains(_searchText.toLowerCase())).toList();
    }

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: Stack(
        children: [
          // ── CONTENIDO PRINCIPAL ──
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, nombre, carrito),
                _buildSearchBar(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar categorías (siempre visible en web/tablet, toggle en móvil)
                      _buildSidebar(),
                      // Contenido
                      Expanded(
                        child: productos.loading
                            ? const Center(child: CircularProgressIndicator(
                                color: AlpesColors.cafeOscuro, strokeWidth: 2))
                            : RefreshIndicator(
                                color: AlpesColors.cafeOscuro,
                                onRefresh: () => productos.cargarProductos(),
                                child: CustomScrollView(
                                  controller: _scrollCtrl,
                                  slivers: [
                                    // Hero banner
                                    SliverToBoxAdapter(child: _buildHeroBanner(context, nombre)),
                                    // Sección recomendados
                                    if (productos.recomendados.isNotEmpty) ...[
                                      SliverToBoxAdapter(child: _buildSectionHeader(
                                          'Recomendados para ti', '/catalogo')),
                                      SliverToBoxAdapter(child: _buildHorizontalList(
                                          productos.recomendados)),
                                    ],
                                    // Banner promo
                                    SliverToBoxAdapter(child: _buildPromoBanner(context)),
                                    // Todos los productos
                                    SliverToBoxAdapter(child: _buildSectionHeader(
                                        'Todos los productos', '/catalogo')),
                                    SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 80),
                                      sliver: SliverGrid(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 10,
                                          crossAxisSpacing: 10,
                                          childAspectRatio: 0.75,
                                        ),
                                        delegate: SliverChildBuilderDelegate(
                                          (_, i) => ProductoCard(producto: lista[i]),
                                          childCount: lista.length,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── DRAWER OVERLAY (móvil) ──
          AnimatedBuilder(
            animation: _drawerAnim,
            builder: (_, __) {
              if (_drawerAnim.value == 0) return const SizedBox.shrink();
              return Stack(children: [
                GestureDetector(
                  onTap: _toggleDrawer,
                  child: Container(color: Colors.black.withOpacity(0.4 * _drawerAnim.value)),
                ),
                Transform.translate(
                  offset: Offset(-260 * (1 - _drawerAnim.value), 0),
                  child: _buildFullDrawer(context),
                ),
              ]);
            },
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavCliente(currentIndex: 0),
    );
  }

  // ── TOP BAR ─────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, String nombre, CarritoProvider carrito) {
    return Container(
      height: 52,
      color: AlpesColors.cafeOscuro,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        // Logo/hamburguesa
        GestureDetector(
          onTap: _toggleDrawer,
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: AlpesColors.oroGuatemalteco.withOpacity(0.4),
                    blurRadius: 8)],
              ),
              child: const Icon(Icons.chair_alt_rounded, color: AlpesColors.cafeOscuro, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Muebles de los Alpes',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
        const Spacer(),
        // Saludo pequeño
        Text('Hola, ${nombre.split(' ').first}',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        const SizedBox(width: 12),
        // Favoritos
        IconButton(
          icon: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 22),
          onPressed: () => context.go('/favoritos'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        // Carrito
        badges.Badge(
          badgeContent: Text('${carrito.totalItems}',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
          showBadge: carrito.totalItems > 0,
          badgeStyle: const badges.BadgeStyle(badgeColor: AlpesColors.rojoColonial),
          child: IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
            onPressed: () => context.go('/carrito'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
      ]),
    );
  }

  // ── BARRA DE BÚSQUEDA ────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: AlpesColors.cafeOscuro,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchText = v),
          style: const TextStyle(fontSize: 13, color: AlpesColors.cafeOscuro),
          decoration: InputDecoration(
            hintText: 'Buscar muebles, salas, comedores…',
            hintStyle: const TextStyle(fontSize: 12, color: AlpesColors.arenaCalida),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AlpesColors.nogalMedio),
            suffixIcon: _searchText.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 16, color: AlpesColors.arenaCalida),
                    onPressed: () { _searchCtrl.clear(); setState(() => _searchText = ''); })
                : IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 18, color: AlpesColors.nogalMedio),
                    onPressed: () => context.go('/catalogo'),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  // ── SIDEBAR CATEGORÍAS ───────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 72,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _categorias.length,
              itemBuilder: (_, i) {
                final cat    = _categorias[i];
                final active = _categoriaActiva == cat['label'];
                return GestureDetector(
                  onTap: () => setState(() => _categoriaActiva = cat['label'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? AlpesColors.cafeOscuro : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(cat['icon'] as IconData, size: 20,
                          color: active ? AlpesColors.oroGuatemalteco : AlpesColors.arenaCalida),
                      const SizedBox(height: 4),
                      Text(cat['label'] as String,
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600,
                              color: active ? Colors.white : AlpesColors.arenaCalida),
                          textAlign: TextAlign.center,
                          maxLines: 2),
                    ]),
                  ),
                );
              },
            ),
          ),
          // Ver catálogo completo
          GestureDetector(
            onTap: () => context.go('/catalogo'),
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.3)),
              ),
              child: const Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.apps_rounded, size: 18, color: AlpesColors.oroGuatemalteco),
                SizedBox(height: 3),
                Text('Ver más', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                    color: AlpesColors.nogalMedio), textAlign: TextAlign.center),
              ]),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── FULL DRAWER (móvil overlay) ──────────────────────────
  Widget _buildFullDrawer(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final nombre = auth.nombreCompleto;
    final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    return Container(
      width: 260,
      height: double.infinity,
      color: AlpesColors.cafeOscuro,
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(initial, style: const TextStyle(fontSize: 20,
                  fontWeight: FontWeight.w800, color: AlpesColors.cafeOscuro)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              const Text('Cliente', style: TextStyle(color: AlpesColors.arenaCalida, fontSize: 11)),
            ])),
          ]),
        ),
        const Divider(color: Colors.white12, height: 1),
        // Categorías
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(alignment: Alignment.centerLeft,
              child: Text('Categorías', style: TextStyle(color: Colors.white.withOpacity(0.5),
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
        ),
        ..._categorias.map((cat) => ListTile(
          leading: Icon(cat['icon'] as IconData, color: AlpesColors.arenaCalida, size: 20),
          title: Text(cat['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 13)),
          onTap: () { setState(() => _categoriaActiva = cat['label'] as String); _toggleDrawer(); },
        )),
        const Divider(color: Colors.white12, height: 1),
        ListTile(
          leading: const Icon(Icons.favorite_border_rounded, color: AlpesColors.arenaCalida, size: 20),
          title: const Text('Mis favoritos', style: TextStyle(color: Colors.white, fontSize: 13)),
          onTap: () { _toggleDrawer(); context.go('/favoritos'); },
        ),
        ListTile(
          leading: const Icon(Icons.receipt_long_rounded, color: AlpesColors.arenaCalida, size: 20),
          title: const Text('Mis pedidos', style: TextStyle(color: Colors.white, fontSize: 13)),
          onTap: () { _toggleDrawer(); context.go('/mis-ordenes'); },
        ),
        ListTile(
          leading: const Icon(Icons.person_outline_rounded, color: AlpesColors.arenaCalida, size: 20),
          title: const Text('Mi perfil', style: TextStyle(color: Colors.white, fontSize: 13)),
          onTap: () { _toggleDrawer(); context.go('/perfil'); },
        ),
        const Spacer(),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: AlpesColors.rojoColonial, size: 20),
          title: const Text('Cerrar sesión', style: TextStyle(color: AlpesColors.rojoColonial, fontSize: 13)),
          onTap: () async { await auth.logout(); if (context.mounted) context.go('/login'); },
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ── HERO BANNER ──────────────────────────────────────────
  Widget _buildHeroBanner(BuildContext context, String nombre) {
    return GestureDetector(
      onTap: () => context.go('/catalogo'),
      child: Container(
        margin: const EdgeInsets.all(10),
        height: 155,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF2C1810), Color(0xFF3D2416), Color(0xFF1E0E08)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF2C1810).withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(children: [
          Positioned(top: -20, right: -20, child: _circle(110, AlpesColors.oroGuatemalteco.withOpacity(0.08))),
          Positioned(bottom: -10, left: 80, child: _circle(60, AlpesColors.oroGuatemalteco.withOpacity(0.05))),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
                    ),
                    child: const Text('✦ Artesanía Guatemalteca',
                        style: TextStyle(color: AlpesColors.oroGuatemalteco, fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                  const Text('Muebles que\ntransforman tu hogar',
                      style: TextStyle(color: Colors.white, fontSize: 17,
                          fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AlpesColors.oroGuatemalteco,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Ver catálogo →',
                        style: TextStyle(color: AlpesColors.cafeOscuro, fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              )),
              // Ícono decorativo
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AlpesColors.oroGuatemalteco.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.25)),
                ),
                child: const Icon(Icons.chair_alt_rounded, size: 44,
                    color: AlpesColors.oroGuatemalteco),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── PROMO BANNER ─────────────────────────────────────────
  Widget _buildPromoBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/catalogo'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3A2A), Color(0xFF2C5040)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(children: [
          Positioned(right: -10, top: -10, child: _circle(80, Colors.white.withOpacity(0.05))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AlpesColors.oroGuatemalteco,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: Color(0xFF1A3A2A), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Oferta especial',
                        style: TextStyle(color: AlpesColors.oroGuatemalteco,
                            fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 3),
                  const Text('Envío gratis en tu primera compra',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              )),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String route) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 14, 8, 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Container(width: 3, height: 14,
            decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 7),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: AlpesColors.cafeOscuro)),
      ]),
      GestureDetector(
        onTap: () => context.go(route),
        child: const Text('Ver todos →',
            style: TextStyle(fontSize: 11, color: AlpesColors.nogalMedio,
                fontWeight: FontWeight.w500)),
      ),
    ]),
  );

  Widget _buildHorizontalList(List<dynamic> productos) => SizedBox(
    height: 195,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: productos.length,
      itemBuilder: (_, i) => SizedBox(
        width: 140,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ProductoCard(producto: productos[i]),
        ),
      ),
    ),
  );

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
