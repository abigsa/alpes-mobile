import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/favoritos_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/producto_provider.dart';

class ProductoCard extends StatelessWidget {
  final Producto producto;
  const ProductoCard({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final favs = context.watch<FavoritosProvider>();
    final auth = context.read<AuthProvider>();
    final esFav = favs.esFavorito(producto.productoId);

    return GestureDetector(
      onTap: () => context.push('/producto/${producto.productoId}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: AlpesColors.pergamino,
                    child: producto.imagenUrl != null
                        ? Image.network(
                            producto.imagenUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.chair_alt,
                              size: 48,
                              color: AlpesColors.arenaCalida,
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.chair_alt, size: 48, color: AlpesColors.arenaCalida),
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(
                        esFav ? Icons.favorite : Icons.favorite_border,
                        color: esFav ? AlpesColors.rojoColonial : Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        if (auth.clienteId != null) {
                          favs.toggleFavorito(
                            clienteId: auth.clienteId!,
                            productoId: producto.productoId,
                          );
                          context.read<ProductoProvider>().registrarFavorito(producto.productoId);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (producto.precio != null)
                    Text(
                      'Q${producto.precio!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AlpesColors.cafeOscuro,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
