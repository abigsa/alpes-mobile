import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/producto_provider.dart';
import '../../widgets/producto_card.dart';
import '../../widgets/bottom_nav_cliente.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen>
    with SingleTickerProviderStateMixin {
  String _filtroTipo = 'Todos';
  String _busqueda   = '';
  String _orden      = 'nombre';
  final _searchCtrl = TextEditingController();
  late TabController _tabCtrl;

  final _tipos = ['Todos', 'INTERIOR', 'EXTERIOR'];
  final _ordenes = {
    'nombre':      'Nombre A–Z',
    'precio_asc':  'Precio ↑',
    'precio_desc': 'Precio ↓',
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tipos.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _filtroTipo = _tipos[_tabCtrl.index]);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productos = context.watch<ProductoProvider>();

    var lista = _filtroTipo == 'Todos'
        ? productos.productos
        : productos.productos
            .where((p) =>
                (p.tipo ?? '').toUpperCase() == _filtroTipo)
            .toList();

    if (_busqueda.isNotEmpty) {
      lista = lista
          .where((p) =>
              p.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
              (p.descripcion ?? '')
                  .toLowerCase()
                  .contains(_busqueda.toLowerCase()))
          .toList();
    }

    lista = [...lista];
    if (_orden == 'precio_asc') {
      lista.sort((a, b) => (a.precio ?? 0).compareTo(b.precio ?? 0));
    } else if (_orden == 'precio_desc') {
      lista.sort((a, b) => (b.precio ?? 0).compareTo(a.precio ?? 0));
    } else {
      lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    }

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: AlpesColors.cafeOscuro,
            leading: IconButton(
              icon: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 16),
              ),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
              title: Row(children: [
                const Text('Catálogo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(width: 10),
                if (!productos.loading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AlpesColors.oroGuatemalteco.withOpacity(0.4))),
                    child: Text('${lista.length}',
                        style: const TextStyle(
                            color: AlpesColors.oroGuatemalteco,
                            fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
              ]),
              background: Stack(children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3D2416), AlpesColors.cafeOscuro],
                    ),
                  ),
                ),
                Positioned(top: -20, right: -20,
                    child: Container(width: 110, height: 110,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: AlpesColors.oroGuatemalteco.withOpacity(0.07)))),
                Positioned(bottom: 0, left: 100,
                    child: Container(width: 60, height: 60,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: AlpesColors.oroGuatemalteco.withOpacity(0.04)))),
              ]),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 18),
                ),
                onSelected: (v) => setState(() => _orden = v),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                itemBuilder: (_) => _ordenes.entries.map((e) =>
                    PopupMenuItem(
                      value: e.key,
                      child: Row(children: [
                        Container(
                          width: 18, height: 18,
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
                                  size: 12, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(e.value,
                            style: TextStyle(
                                fontWeight: _orden == e.key
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: AlpesColors.cafeOscuro, fontSize: 13)),
                      ]),
                    )).toList(),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AlpesColors.cafeOscuro,
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AlpesColors.oroGuatemalteco,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.5),
                  labelStyle: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  unselectedLabelStyle: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w400),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tabs: _tipos.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ),
          ),
        ],
        body: Column(children: [
          // ── Buscador ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AlpesColors.cremaFondo,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AlpesColors.pergamino),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _busqueda = v),
                style: const TextStyle(fontSize: 13,
                    color: AlpesColors.cafeOscuro),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o descripción…',
                  hintStyle: const TextStyle(
                      color: AlpesColors.arenaCalida, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AlpesColors.arenaCalida, size: 20),
                  suffixIcon: _busqueda.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AlpesColors.arenaCalida, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _busqueda = '');
                          })
                      : null,
                  filled: false,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Grid ──
          Expanded(
            child: productos.loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AlpesColors.cafeOscuro, strokeWidth: 2))
                : lista.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AlpesColors.cafeOscuro,
                        onRefresh: () => productos.cargarProductos(),
                        child: GridView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(14, 12, 14, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: lista.length,
                          itemBuilder: (_, i) =>
                              ProductoCard(producto: lista[i]),
                        ),
                      ),
          ),
        ]),
      ),
      bottomNavigationBar: const BottomNavCliente(currentIndex: 1),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(Icons.chair_alt_rounded,
              size: 64, color: AlpesColors.arenaCalida.withOpacity(0.4)),
          const SizedBox(height: 14),
          const Text('Sin productos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: AlpesColors.cafeOscuro)),
          const SizedBox(height: 6),
          const Text('Intenta con otra búsqueda o categoría',
              style: TextStyle(fontSize: 12, color: AlpesColors.nogalMedio)),
        ]),
      );
}
