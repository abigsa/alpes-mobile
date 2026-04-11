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
      appBar: AppBar(
        title: Row(children: [
          const Text('Mi carrito'),
          if (carrito.totalItems > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${carrito.totalItems} item${carrito.totalItems != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 11, color: AlpesColors.oroGuatemalteco,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: carrito.isEmpty
          ? _emptyCart(context)
          : Column(children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  itemCount: carrito.items.length,
                  itemBuilder: (_, i) => _ItemCard(item: carrito.items[i], carrito: carrito),
                ),
              ),
              _buildResumen(context, carrito),
            ]),
    );
  }

  Widget _emptyCart(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: AlpesColors.pergamino,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.shopping_bag_outlined, size: 48, color: AlpesColors.arenaCalida),
      ),
      const SizedBox(height: 20),
      const Text('Tu carrito está vacío',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
      const SizedBox(height: 6),
      const Text('Agrega productos del catálogo',
          style: TextStyle(fontSize: 13, color: AlpesColors.nogalMedio)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        icon: const Icon(Icons.grid_view_rounded),
        label: const Text('Ir al catálogo'),
        onPressed: () => context.go('/catalogo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AlpesColors.cafeOscuro,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ]),
  );

  Widget _buildResumen(BuildContext context, CarritoProvider carrito) {
    final subtotal = carrito.total;
    final iva      = subtotal * 0.12;
    final total    = subtotal + iva;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 36, height: 3, margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: AlpesColors.pergamino,
                borderRadius: BorderRadius.circular(2))),
        _resumenRow('Subtotal', 'Q ${subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 6),
        _resumenRow('IVA (12%)', 'Q ${iva.toStringAsFixed(2)}'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(color: AlpesColors.pergamino),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: AlpesColors.cafeOscuro)),
          Text('Q ${total.toStringAsFixed(2)}', style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: AlpesColors.cafeOscuro,
              letterSpacing: -0.5)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.lock_rounded, size: 18),
            label: const Text('Proceder al pago'),
            onPressed: () => context.go('/checkout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AlpesColors.cafeOscuro,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _resumenRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AlpesColors.nogalMedio)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AlpesColors.cafeOscuro)),
    ],
  );
}

class _ItemCard extends StatelessWidget {
  final dynamic item;
  final CarritoProvider carrito;
  const _ItemCard({required this.item, required this.carrito});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          // Imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 74, height: 74,
              color: AlpesColors.pergamino,
              child: item.imagenUrl != null
                  ? Image.network(item.imagenUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.chair_alt_rounded,
                          color: AlpesColors.arenaCalida))
                  : const Icon(Icons.chair_alt_rounded, color: AlpesColors.arenaCalida),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AlpesColors.cafeOscuro), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('Q ${item.precioUnitario.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: AlpesColors.nogalMedio)),
              const SizedBox(height: 8),
              // Qty controls
              Row(children: [
                _qBtn(Icons.remove_rounded, () => item.cantidad > 1
                    ? carrito.actualizarCantidad(item.carritoDetId, item.cantidad - 1)
                    : carrito.eliminarItem(item.carritoDetId)),
                Container(
                  width: 36, height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AlpesColors.cremaFondo,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text('${item.cantidad}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AlpesColors.cafeOscuro)),
                ),
                _qBtn(Icons.add_rounded,
                    () => carrito.actualizarCantidad(item.carritoDetId, item.cantidad + 1)),
              ]),
            ],
          )),
          // Precio total + eliminar
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Q ${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                    color: AlpesColors.cafeOscuro)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => carrito.eliminarItem(item.carritoDetId),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AlpesColors.rojoColonial.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AlpesColors.rojoColonial, size: 16),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _qBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: AlpesColors.cafeOscuro.withOpacity(0.07),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 16, color: AlpesColors.cafeOscuro),
    ),
  );
}
