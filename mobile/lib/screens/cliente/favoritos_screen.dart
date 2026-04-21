import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/favoritos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/producto_provider.dart';
import '../../widgets/producto_card.dart';
import '../../widgets/bottom_nav_cliente.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favs     = context.watch<FavoritosProvider>();
    final auth     = context.read<AuthProvider>();
    final productos = context.watch<ProductoProvider>();

    // Filtrar productos que están en favoritosIds
    final lista = productos.productos
        .where((p) => favs.favoritosIds.contains(p.productoId))
        .toList();

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
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
              titlePadding:
                  const EdgeInsets.only(left: 56, bottom: 14),
              title: Row(children: [
                const Text('Favoritos',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AlpesColors.rojoColonial.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${lista.length}',
                      style: const TextStyle(color: Colors.white,
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
                    child: Container(width: 100, height: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: AlpesColors.rojoColonial.withOpacity(0.08)))),
              ]),
            ),
          ),
        ],
        body: lista.isEmpty
            ? _emptyState(context)
            : RefreshIndicator(
                color: AlpesColors.cafeOscuro,
                onRefresh: () async { if (auth.clienteId != null) await favs.cargarFavoritos(auth.clienteId!); },
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: lista.length,
                  itemBuilder: (_, i) =>
                      ProductoCard(producto: lista[i]),
                ),
              ),
      ),
      bottomNavigationBar: const BottomNavCliente(currentIndex: 2),
    );
  }

  Widget _emptyState(BuildContext context) => Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AlpesColors.rojoColonial.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_border_rounded,
                size: 38, color: AlpesColors.rojoColonial.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          const Text('Sin favoritos aún',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: AlpesColors.cafeOscuro)),
          const SizedBox(height: 8),
          const Text('Guarda los productos que más te gusten\ncon el ♡ en cada tarjeta',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AlpesColors.nogalMedio,
                  height: 1.5)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('Ver catálogo'),
            onPressed: () => context.go('/catalogo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AlpesColors.cafeOscuro,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ]),
      );
}
