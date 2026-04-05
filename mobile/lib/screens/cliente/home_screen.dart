import 'package:flutter/material.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final carrito = context.watch<CarritoProvider>();
    final productos = context.watch<ProductoProvider>();

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('MUEBLES DE LOS ALPES'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => context.go('/busqueda')),
          badges.Badge(
            badgeContent: Text('${carrito.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 10)),
            showBadge: carrito.totalItems > 0,
            child: IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () => context.go('/carrito')),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: productos.loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : RefreshIndicator(
              onRefresh: () => productos.cargarProductos(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AlpesColors.cafeOscuro, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${auth.usuario?['USERNAME'] ?? auth.usuario?['username'] ?? 'bienvenido'} 👋',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AlpesColors.cremaFondo),
                          ),
                          const SizedBox(height: 4),
                          Text('Descubre nuestros muebles artesanales',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AlpesColors.arenaCalida)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.go('/catalogo'),
                            style: ElevatedButton.styleFrom(backgroundColor: AlpesColors.oroGuatemalteco, foregroundColor: AlpesColors.cafeOscuro),
                            child: const Text('Ver catálogo completo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (productos.recomendados.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recomendados para ti', style: Theme.of(context).textTheme.titleLarge),
                            TextButton(onPressed: () => context.go('/catalogo'), child: const Text('Ver todos')),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 240,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: productos.recomendados.length,
                          itemBuilder: (_, i) => SizedBox(width: 160, child: ProductoCard(producto: productos.recomendados[i])),
                        ),
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Todos los productos', style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ProductoCard(producto: productos.productos[i]),
                        childCount: productos.productos.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNavCliente(currentIndex: 0),
    );
  }
}
