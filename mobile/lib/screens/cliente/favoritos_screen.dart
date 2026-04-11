import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/favoritos_provider.dart';
import '../../providers/producto_provider.dart';
import '../../widgets/producto_card.dart';

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
      appBar: AppBar(
        title: const Text('FAVORITOS'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop()),
      ),
      body: favList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_outline,
                      size: 80, color: AlpesColors.arenaCalida),
                  const SizedBox(height: 16),
                  Text('Sin favoritos aún',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Guarda productos que te gusten',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/catalogo'),
                    child: const Text('Explorar catálogo'),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: favList.length,
              itemBuilder: (_, i) => ProductoCard(producto: favList[i]),
            ),
    );
  }
}
