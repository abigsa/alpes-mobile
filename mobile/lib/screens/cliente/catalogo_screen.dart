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

class _CatalogoScreenState extends State<CatalogoScreen> {
  String _filtroTipo = 'Todos';
  String _busqueda = '';
  String _orden = 'nombre';
  final _searchCtrl = TextEditingController();
  final _tipos = ['Todos', 'INTERIOR', 'EXTERIOR'];
  final _ordenes = {
    'nombre': 'Nombre',
    'precio_asc': 'Precio ↑',
    'precio_desc': 'Precio ↓'
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productos = context.watch<ProductoProvider>();

    var lista = _filtroTipo == 'Todos'
        ? productos.productos
        : productos.productos.where((p) => p.tipo == _filtroTipo).toList();

    if (_busqueda.isNotEmpty) {
      lista = lista
          .where(
              (p) => p.nombre.toLowerCase().contains(_busqueda.toLowerCase()))
          .toList();
    }

    if (_orden == 'precio_asc') {
      lista = [...lista]
        ..sort((a, b) => (a.precio ?? 0).compareTo(b.precio ?? 0));
    } else if (_orden == 'precio_desc') {
      lista = [...lista]
        ..sort((a, b) => (b.precio ?? 0).compareTo(a.precio ?? 0));
    } else {
      lista = [...lista]..sort((a, b) => a.nombre.compareTo(b.nombre));
    }

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AlpesColors.cafeOscuro,
            leading: IconButton(
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 16),
              ),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Catálogo',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              background: Stack(children: [
                Container(color: AlpesColors.cafeOscuro),
                Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AlpesColors.oroGuatemalteco
                                .withOpacity(0.08)))),
                Positioned(
                    bottom: -10,
                    left: 60,
                    child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AlpesColors.oroGuatemalteco
                                .withOpacity(0.05)))),
              ]),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort_rounded, color: Colors.white),
                onSelected: (v) => setState(() => _orden = v),
                itemBuilder: (_) => _ordenes.entries
                    .map((e) => PopupMenuItem(
                        value: e.key,
                        child: Row(children: [
                          Icon(
                              _orden == e.key
                                  ? Icons.check_rounded
                                  : Icons.circle_outlined,
                              size: 16,
                              color: AlpesColors.cafeOscuro),
                          const SizedBox(width: 8),
                          Text(e.value),
                        ])))
                    .toList(),
              ),
            ],
          ),
        ],
        body: Column(
          children: [
            // Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _busqueda = v),
                decoration: InputDecoration(
                  hintText: 'Buscar productos…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _busqueda.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _busqueda = '');
                          })
                      : null,
                  filled: true,
                  fillColor: AlpesColors.cremaFondo,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            // Filtros tipo
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _tipos.length,
                  itemBuilder: (_, i) {
                    final t = _tipos[i];
                    final active = _filtroTipo == t;
                    return GestureDetector(
                      onTap: () => setState(() => _filtroTipo = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: active
                              ? AlpesColors.cafeOscuro
                              : AlpesColors.cremaFondo,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: active
                                  ? AlpesColors.cafeOscuro
                                  : AlpesColors.arenaCalida),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : AlpesColors.grafito)),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Contador
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(children: [
                Text('${lista.length} producto${lista.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AlpesColors.nogalMedio,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
            // Grid
            Expanded(
              child: productos.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AlpesColors.cafeOscuro))
                  : lista.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          color: AlpesColors.cafeOscuro,
                          onRefresh: () => productos.cargarProductos(),
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
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
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavCliente(currentIndex: 1),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: AlpesColors.arenaCalida.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('Sin resultados',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AlpesColors.nogalMedio)),
          const SizedBox(height: 4),
          const Text('Intenta con otro término o categoría',
              style: TextStyle(fontSize: 12, color: AlpesColors.arenaCalida)),
        ]),
      );
}
