import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/favoritos_provider.dart';
import '../../providers/producto_provider.dart';
import '../../widgets/producto_card.dart';
import '../../widgets/bottom_nav_cliente.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritos = context.watch<FavoritosProvider>();
    final productos = context.watch<ProductoProvider>();
    final favList = productos.productos
        .where((p) => favoritos.esFavorito(p.productoId))
        .toList();

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: AlpesColors.cafeOscuro,
            // ── Botón regresar funcional ──
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
              title: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.favorite_rounded,
                    color: AlpesColors.rojoColonial, size: 16),
                const SizedBox(width: 6),
                const Text('Mis favoritos',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                if (favList.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: AlpesColors.rojoColonial.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${favList.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
              centerTitle: false,
              titlePadding: const EdgeInsets.fromLTRB(52, 0, 16, 14),
              background: Stack(children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2C1810), Color(0xFF3D2416)],
                    ),
                  ),
                ),
                Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                AlpesColors.rojoColonial.withOpacity(0.08)))),
                Positioned(
                    bottom: 0,
                    left: 100,
                    child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AlpesColors.oroGuatemalteco
                                .withOpacity(0.06)))),
              ]),
            ),
          ),
        ],
        body: favList.isEmpty
            ? _emptyState(context)
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 80),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: favList.length,
                itemBuilder: (_, i) => ProductoCard(producto: favList[i]),
              ),
      ),
      bottomNavigationBar: const BottomNavCliente(currentIndex: 2),
    );
  }

  Widget _emptyState(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AlpesColors.rojoColonial.withOpacity(0.08),
                      AlpesColors.rojoColonial.withOpacity(0.04)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AlpesColors.rojoColonial.withOpacity(0.2)),
                ),
                child: const Icon(Icons.favorite_border_rounded,
                    size: 44, color: AlpesColors.rojoColonial),
              ),
              const SizedBox(height: 20),
              const Text('Sin favoritos aún',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AlpesColors.cafeOscuro)),
              const SizedBox(height: 8),
              const Text(
                  'Toca el ♥ en los productos que te gusten\npara guardarlos aquí',
                  style: TextStyle(
                      fontSize: 13, color: AlpesColors.nogalMedio, height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: const Text('Explorar catálogo'),
                onPressed: () => context.go('/catalogo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AlpesColors.cafeOscuro,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
                child: const Text('← Volver al inicio',
                    style:
                        TextStyle(color: AlpesColors.nogalMedio, fontSize: 13)),
              ),
            ],
          ),
        ),
      );
}
