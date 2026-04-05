import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/carrito_provider.dart';

class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(title: const Text('MI CARRITO')),
      body: carrito.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: AlpesColors.arenaCalida),
                  const SizedBox(height: 16),
                  Text('Tu carrito está vacío', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => context.go('/catalogo'), child: const Text('Ver catálogo')),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: carrito.items.length,
                    itemBuilder: (_, i) {
                      final item = carrito.items[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 70, height: 70,
                                decoration: BoxDecoration(color: AlpesColors.pergamino, borderRadius: BorderRadius.circular(8)),
                                child: item.imagenUrl != null
                                    ? Image.network(item.imagenUrl!, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.chair_alt, color: AlpesColors.arenaCalida))
                                    : const Icon(Icons.chair_alt, color: AlpesColors.arenaCalida),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.nombre, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    Text('Q${item.precioUnitario.toStringAsFixed(2)}', style: const TextStyle(color: AlpesColors.nogalMedio)),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 18),
                                          onPressed: () => item.cantidad > 1
                                              ? carrito.actualizarCantidad(item.carritoDetId, item.cantidad - 1)
                                              : carrito.eliminarItem(item.carritoDetId),
                                        ),
                                        Text('${item.cantidad}'),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 18),
                                          onPressed: () => carrito.actualizarCantidad(item.carritoDetId, item.cantidad + 1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text('Q${item.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AlpesColors.rojoColonial),
                                    onPressed: () => carrito.eliminarItem(item.carritoDetId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:', style: Theme.of(context).textTheme.titleLarge),
                          Text('Q${carrito.total.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AlpesColors.cafeOscuro)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go('/checkout'),
                          child: const Text('PROCEDER AL PAGO'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
