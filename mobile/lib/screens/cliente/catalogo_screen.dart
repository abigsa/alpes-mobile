import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/producto_provider.dart';
import '../../providers/favoritos_provider.dart';
import '../../providers/carrito_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_nav_cliente.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  CATALOGO SCREEN — tipos dinámicos desde BD, diseño editorial premium
// ═══════════════════════════════════════════════════════════════════════════

class CatalogoScreen extends StatefulWidget {
  final String? categoriaInicial;
  const CatalogoScreen({super.key, this.categoriaInicial});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen>
    with SingleTickerProviderStateMixin {
  late String _filtroTipo;
  String _busqueda = '';
  String _orden = 'nombre';
  bool _vistaGrid = true;
  final _searchCtrl = TextEditingController();
  TabController? _tabCtrl;
  List<String> _tipos = ['Todos'];

  final _ordenes = {
    'nombre': 'Nombre A–Z',
    'precio_asc': 'Precio menor',
    'precio_desc': 'Precio mayor',
  };

  @override
  void initState() {
    super.initState();
    _filtroTipo = widget.categoriaInicial?.trim().toUpperCase() ?? 'Todos';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos().then((_) {
        _inicializarTipos();
      });
    });
  }

  void _inicializarTipos() {
    final productos = context.read<ProductoProvider>().productos;
    // Extraer tipos únicos desde BD, ignorar nulls/vacíos
    final tiposSet = productos
        .map((p) => (p.tipo ?? '').trim().toUpperCase())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final nuevosTipos = ['Todos', ...tiposSet];

    if (!mounted) return;

    // Reconstruir TabController solo si cambian los tipos
    if (_tipos.length != nuevosTipos.length ||
        !_tipos.every((t) => nuevosTipos.contains(t))) {
      _tabCtrl?.dispose();
      final indexInicial = nuevosTipos.indexOf(_filtroTipo);
      _tabCtrl = TabController(
        length: nuevosTipos.length,
        vsync: this,
        initialIndex: indexInicial >= 0 ? indexInicial : 0,
      );
      if (indexInicial < 0) _filtroTipo = 'Todos';
      _tabCtrl!.addListener(() {
        if (!_tabCtrl!.indexIsChanging) {
          setState(() => _filtroTipo = _tipos[_tabCtrl!.index]);
        }
      });
      setState(() => _tipos = nuevosTipos);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl?.dispose();
    super.dispose();
  }

  List<Producto> _listaFiltrada(ProductoProvider provider) {
    var lista = _filtroTipo == 'Todos'
        ? provider.productos
        : provider.productos
            .where((p) => (p.tipo ?? '').toUpperCase() == _filtroTipo)
            .toList();

    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      lista = lista
          .where((p) =>
              p.nombre.toLowerCase().contains(q) ||
              (p.descripcion ?? '').toLowerCase().contains(q) ||
              (p.material ?? '').toLowerCase().contains(q))
          .toList();
    }

    lista = [...lista];
    switch (_orden) {
      case 'precio_asc':
        lista.sort((a, b) => (a.precio ?? 0).compareTo(b.precio ?? 0));
        break;
      case 'precio_desc':
        lista.sort((a, b) => (b.precio ?? 0).compareTo(a.precio ?? 0));
        break;
      default:
        lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoProvider>();
    final lista = _listaFiltrada(provider);
    final w = MediaQuery.of(context).size.width;
    final cols = w > 900
        ? 4
        : w > 600
            ? 3
            : 2;

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // ── APP BAR ──────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: AlpesColors.cafeOscuro,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 15),
              ),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
              title:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const Text('Catalogo',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3)),
                const SizedBox(width: 8),
                if (!provider.loading)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AlpesColors.oroGuatemalteco.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AlpesColors.oroGuatemalteco.withOpacity(0.35)),
                    ),
                    child: Text('${lista.length}',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AlpesColors.oroGuatemalteco,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
              ]),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D2416), AlpesColors.cafeOscuro],
                  ),
                ),
                child: Stack(children: [
                  Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AlpesColors.oroGuatemalteco
                                  .withOpacity(0.06)))),
                ]),
              ),
            ),
            actions: [
              // Vista grid/lista
              IconButton(
                onPressed: () => setState(() => _vistaGrid = !_vistaGrid),
                icon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Icon(
                      _vistaGrid
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 17),
                ),
              ),
              // Ordenar
              PopupMenuButton<String>(
                icon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 17),
                ),
                onSelected: (v) => setState(() => _orden = v),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                elevation: 8,
                itemBuilder: (_) => _ordenes.entries
                    .map((e) => PopupMenuItem(
                          value: e.key,
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _orden == e.key
                                    ? AlpesColors.cafeOscuro
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color: _orden == e.key
                                        ? AlpesColors.cafeOscuro
                                        : AlpesColors.arenaCalida),
                              ),
                              child: _orden == e.key
                                  ? const Icon(Icons.check_rounded,
                                      size: 11, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(e.value,
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: _orden == e.key
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: AlpesColors.cafeOscuro,
                                    fontSize: 13)),
                          ]),
                        ))
                    .toList(),
              ),
              const SizedBox(width: 6),
            ],
            // ── TABS DINÁMICOS DESDE BD ─────────────────────
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: _tabCtrl == null || provider.loading
                  ? Container(
                      height: 46,
                      color: AlpesColors.cafeOscuro,
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: AlpesColors.oroGuatemalteco,
                              strokeWidth: 1.5),
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF1C0F08),
                      child: TabBar(
                        controller: _tabCtrl!,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: AlpesColors.oroGuatemalteco,
                        indicatorWeight: 2.5,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.4),
                        labelStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8),
                        unselectedLabelStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w400),
                        dividerColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        tabs: _tipos.map((t) {
                          final count = t == 'Todos'
                              ? provider.productos.length
                              : provider.productos
                                  .where(
                                      (p) => (p.tipo ?? '').toUpperCase() == t)
                                  .length;
                          return Tab(
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(t == 'Todos' ? 'Todos' : _nombreAmigable(t)),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('$count',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 9,
                                        color: _filtroTipo == t
                                            ? AlpesColors.oroGuatemalteco
                                            : Colors.white.withOpacity(0.4),
                                        fontWeight: FontWeight.w600)),
                              ),
                            ]),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
        body: Column(children: [
          // ── BUSCADOR ───────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AlpesColors.cremaFondo,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AlpesColors.pergamino),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _busqueda = v),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AlpesColors.cafeOscuro),
                    decoration: InputDecoration(
                      hintText: 'Buscar muebles...',
                      hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AlpesColors.arenaCalida,
                          fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AlpesColors.arenaCalida, size: 19),
                      suffixIcon: _busqueda.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: AlpesColors.arenaCalida, size: 17),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _busqueda = '');
                              })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          Container(height: 0.5, color: AlpesColors.pergamino),

          // ── PRODUCTOS ──────────────────────────────────────
          Expanded(
            child: provider.loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AlpesColors.cafeOscuro, strokeWidth: 2))
                : lista.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AlpesColors.cafeOscuro,
                        onRefresh: () async {
                          await provider.cargarProductos();
                          _inicializarTipos();
                        },
                        child: _vistaGrid
                            ? _buildGrid(lista, cols)
                            : _buildLista(lista),
                      ),
          ),
        ]),
      ),
      bottomNavigationBar: const BottomNavCliente(currentIndex: 1),
    );
  }

  // ── Nombre amigable para el tipo ──
  String _nombreAmigable(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'INTERIOR':
        return 'Interior';
      case 'EXTERIOR':
        return 'Exterior';
      default:
        return tipo[0].toUpperCase() + tipo.substring(1).toLowerCase();
    }
  }

  // ── VISTA GRID ──────────────────────────────────────────
  Widget _buildGrid(List<Producto> lista, int cols) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.68,
      ),
      itemCount: lista.length,
      itemBuilder: (_, i) => _ProductoCardCatalogo(producto: lista[i]),
    );
  }

  // ── VISTA LISTA ─────────────────────────────────────────
  Widget _buildLista(List<Producto> lista) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ProductoCardLista(producto: lista[i]),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.chair_alt_rounded,
              size: 56, color: AlpesColors.arenaCalida.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Sin productos',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AlpesColors.cafeOscuro)),
          const SizedBox(height: 6),
          const Text('Intenta con otra busqueda o filtro',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AlpesColors.nogalMedio)),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  CARD GRID — diseño editorial
// ═══════════════════════════════════════════════════════════════════════════
class _ProductoCardCatalogo extends StatefulWidget {
  final Producto producto;
  const _ProductoCardCatalogo({required this.producto});
  @override
  State<_ProductoCardCatalogo> createState() => _ProductoCardCatalogoState();
}

class _ProductoCardCatalogoState extends State<_ProductoCardCatalogo> {
  bool _agregando = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final favs = context.watch<FavoritosProvider>();
    final auth = context.read<AuthProvider>();
    final carrito = context.read<CarritoProvider>();
    final esFav = favs.esFavorito(p.productoId);

    return GestureDetector(
      onTap: () => context.push('/producto/${p.productoId}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AlpesColors.pergamino, width: 0.8),
          boxShadow: [
            BoxShadow(
                color: AlpesColors.cafeOscuro.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── IMAGEN ──
          Expanded(
            flex: 5,
            child: Stack(fit: StackFit.expand, children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: p.imagenUrl != null && p.imagenUrl!.isNotEmpty
                    ? Image.network(p.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              // Badge tipo
              if (p.tipo != null && p.tipo!.isNotEmpty)
                Positioned(
                  top: 7,
                  left: 7,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AlpesColors.cafeOscuro.withOpacity(0.82),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(p.tipo!.toUpperCase(),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AlpesColors.oroGuatemalteco,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                  ),
                ),
              // Favorito
              Positioned(
                top: 7,
                right: 7,
                child: GestureDetector(
                  onTap: () async {
                    if (auth.clienteId == null) return;
                    await favs.toggleFavorito(
                        clienteId: auth.clienteId!, productoId: p.productoId);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4)
                      ],
                    ),
                    child: Icon(
                      esFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 14,
                      color: esFav
                          ? AlpesColors.rojoColonial
                          : AlpesColors.arenaCalida,
                    ),
                  ),
                ),
              ),
            ]),
          ),
          // ── INFO ──
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nombre
                  Text(p.nombre,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AlpesColors.grafito,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  // Precio + carrito
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.precio != null && p.precio! > 0
                                  ? 'Q ${p.precio!.toStringAsFixed(0)}'
                                  : 'Consultar',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AlpesColors.cafeOscuro),
                            ),
                            if (p.precio != null && p.precio! > 0)
                              Text(
                                '12c · Q ${(p.precio! / 12).toStringAsFixed(0)}/mes',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 8,
                                    color: AlpesColors.rojoColonial,
                                    fontWeight: FontWeight.w500),
                              ),
                          ],
                        ),
                      ),
                      // Botón carrito
                      GestureDetector(
                        onTap: _agregando
                            ? null
                            : () async {
                                if (auth.clienteId == null) return;
                                setState(() => _agregando = true);
                                await carrito.agregarItem(
                                  clienteId: auth.clienteId!,
                                  productoId: p.productoId,
                                  nombre: p.nombre,
                                  precio: p.precio ?? 0,
                                );
                                if (mounted) setState(() => _agregando = false);
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _agregando
                                ? AlpesColors.cafeOscuro.withOpacity(0.5)
                                : AlpesColors.cafeOscuro,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _agregando
                              ? const Center(
                                  child: SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 1.5)))
                              : const Icon(Icons.add_shopping_cart_rounded,
                                  color: AlpesColors.oroGuatemalteco, size: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AlpesColors.cremaFondo,
        child: Center(
          child: Icon(Icons.chair_outlined,
              size: 28, color: AlpesColors.arenaCalida.withOpacity(0.3)),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  CARD LISTA — vista horizontal más compacta
// ═══════════════════════════════════════════════════════════════════════════
class _ProductoCardLista extends StatefulWidget {
  final Producto producto;
  const _ProductoCardLista({required this.producto});
  @override
  State<_ProductoCardLista> createState() => _ProductoCardListaState();
}

class _ProductoCardListaState extends State<_ProductoCardLista> {
  bool _agregando = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final favs = context.watch<FavoritosProvider>();
    final auth = context.read<AuthProvider>();
    final carrito = context.read<CarritoProvider>();
    final esFav = favs.esFavorito(p.productoId);

    return GestureDetector(
      onTap: () => context.push('/producto/${p.productoId}'),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AlpesColors.pergamino, width: 0.8),
          boxShadow: [
            BoxShadow(
                color: AlpesColors.cafeOscuro.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          // Imagen
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(10)),
            child: SizedBox(
              width: 100,
              child: p.imagenUrl != null && p.imagenUrl!.isNotEmpty
                  ? Image.network(p.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: AlpesColors.cremaFondo,
                          child: const Center(
                              child: Icon(Icons.chair_outlined,
                                  color: AlpesColors.arenaCalida, size: 24))))
                  : Container(
                      color: AlpesColors.cremaFondo,
                      child: const Center(
                          child: Icon(Icons.chair_outlined,
                              color: AlpesColors.arenaCalida, size: 24))),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.tipo != null && p.tipo!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AlpesColors.cafeOscuro.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(p.tipo!.toUpperCase(),
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 8,
                                    color: AlpesColors.nogalMedio,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5)),
                          ),
                        Text(p.nombre,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AlpesColors.cafeOscuro),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (p.material != null && p.material!.isNotEmpty)
                          Text(p.material!,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: AlpesColors.nogalMedio),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.precio != null && p.precio! > 0
                            ? 'Q ${p.precio!.toStringAsFixed(0)}'
                            : 'Consultar',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AlpesColors.cafeOscuro),
                      ),
                      Row(children: [
                        // Favorito
                        GestureDetector(
                          onTap: () async {
                            if (auth.clienteId == null) return;
                            await favs.toggleFavorito(
                                clienteId: auth.clienteId!,
                                productoId: p.productoId);
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AlpesColors.cremaFondo,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AlpesColors.pergamino),
                            ),
                            child: Icon(
                              esFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 14,
                              color: esFav
                                  ? AlpesColors.rojoColonial
                                  : AlpesColors.arenaCalida,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Carrito
                        GestureDetector(
                          onTap: _agregando
                              ? null
                              : () async {
                                  if (auth.clienteId == null) return;
                                  setState(() => _agregando = true);
                                  await carrito.agregarItem(
                                    clienteId: auth.clienteId!,
                                    productoId: p.productoId,
                                    nombre: p.nombre,
                                    precio: p.precio ?? 0,
                                  );
                                  if (mounted)
                                    setState(() => _agregando = false);
                                },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AlpesColors.cafeOscuro,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _agregando
                                ? const Center(
                                    child: SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 1.5)))
                                : const Icon(Icons.add_shopping_cart_rounded,
                                    color: AlpesColors.oroGuatemalteco,
                                    size: 14),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
