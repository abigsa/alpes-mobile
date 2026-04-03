import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/producto_provider.dart';
import '../../providers/carrito_provider.dart';
import '../../providers/favoritos_provider.dart';
import '../../providers/auth_provider.dart';

class ProductoDetalleScreen extends StatefulWidget {
  final int productoId;
  const ProductoDetalleScreen({super.key, required this.productoId});
  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  Producto? _producto;
  bool _loading = true;
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final p = await context.read<ProductoProvider>().obtenerProducto(widget.productoId);
    setState(() { _producto = p; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final carrito = context.read<CarritoProvider>();
    final favs = context.watch<FavoritosProvider>();
    final esFav = favs.esFavorito(widget.productoId);

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: Text(_producto?.nombre ?? 'Producto'),
        actions: [
          IconButton(
            icon: Icon(esFav ? Icons.favorite : Icons.favorite_border,
                color: esFav ? AlpesColors.rojoColonial : AlpesColors.cremaFondo),
            onPressed: () {
              if (auth.clienteId != null) {
                favs.toggleFavorito(clienteId: auth.clienteId!, productoId: widget.productoId);
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : _producto == null
              ? const Center(child: Text('Producto no encontrado'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 280,
                        width: double.infinity,
                        color: AlpesColors.pergamino,
                        child: _producto!.imagenUrl != null
                            ? Image.network(_producto!.imagenUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.chair_alt, size: 80, color: AlpesColors.arenaCalida))
                            : const Center(child: Icon(Icons.chair_alt, size: 80, color: AlpesColors.arenaCalida)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_producto!.nombre, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 8),
                            if (_producto!.precio != null)
                              Text('Q${_producto!.precio!.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AlpesColors.cafeOscuro, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            if (_producto!.descripcion != null)
                              Text(_producto!.descripcion!, style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 16),
                            _infoRow('Material', _producto!.material),
                            _infoRow('Color', _producto!.color),
                            _infoRow('Tipo', _producto!.tipo),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => setState(() { if (_cantidad > 1) _cantidad--; }),
                                ),
                                Text('$_cantidad', style: Theme.of(context).textTheme.titleLarge),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => setState(() => _cantidad++),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.shopping_cart),
                                label: const Text('AGREGAR AL CARRITO'),
                                onPressed: () async {
                                  if (auth.clienteId == null) {
                                    context.go('/login');
                                    return;
                                  }
                                  await carrito.agregarItem(
                                    clienteId: auth.clienteId!,
                                    productoId: _producto!.productoId,
                                    nombre: _producto!.nombre,
                                    precio: _producto!.precio ?? 0,
                                    imagenUrl: _producto!.imagenUrl,
                                    cantidad: _cantidad,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Agregado al carrito'), backgroundColor: AlpesColors.verdeSelva),
                                    );
                                  }
                                },
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

  Widget _infoRow(String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: AlpesColors.nogalMedio)),
          Text(value),
        ],
      ),
    );
  }
}
