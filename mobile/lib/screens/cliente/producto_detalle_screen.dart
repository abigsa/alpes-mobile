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
  bool _loading   = true;
  bool _agregando = false;
  int  _cantidad  = 1;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    final p = await context.read<ProductoProvider>().obtenerProducto(widget.productoId);
    if (mounted) setState(() { _producto = p; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.read<AuthProvider>();
    final carrito = context.read<CarritoProvider>();
    final favs    = context.watch<FavoritosProvider>();
    final esFav   = favs.esFavorito(widget.productoId);

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.canPop() ? context.pop() : context.go('/catalogo'),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: AlpesColors.cafeOscuro, size: 18),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              if (auth.clienteId != null) {
                favs.toggleFavorito(clienteId: auth.clienteId!,
                    productoId: widget.productoId);
              }
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(
                esFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: esFav ? AlpesColors.rojoColonial : AlpesColors.nogalMedio,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : _producto == null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 64, color: AlpesColors.arenaCalida),
                  const SizedBox(height: 12),
                  const Text('Producto no encontrado'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => context.go('/catalogo'),
                      child: const Text('Volver al catálogo')),
                ]))
              : Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Imagen hero ──
                          SizedBox(
                            height: 320,
                            width: double.infinity,
                            child: Stack(children: [
                              Container(
                                color: AlpesColors.pergamino,
                                child: _producto!.imagenUrl != null
                                    ? Image.network(_producto!.imagenUrl!,
                                        width: double.infinity, height: 320,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _imgPlaceholder())
                                    : _imgPlaceholder(),
                              ),
                              // Badge tipo
                              if (_producto!.tipo != null)
                                Positioned(bottom: 16, left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AlpesColors.cafeOscuro.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(_producto!.tipo!,
                                        style: const TextStyle(color: Colors.white,
                                            fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                            ]),
                          ),

                          // ── Info card principal ──
                          Container(
                            margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AlpesColors.pergamino),
                              boxShadow: [BoxShadow(
                                  color: AlpesColors.cafeOscuro.withOpacity(0.06),
                                  blurRadius: 10, offset: const Offset(0, 3))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_producto!.nombre,
                                    style: const TextStyle(fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AlpesColors.cafeOscuro)),
                                const SizedBox(height: 8),
                                if (_producto!.precio != null)
                                  Row(children: [
                                    Text('Q ${_producto!.precio!.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: AlpesColors.cafeOscuro,
                                            letterSpacing: -0.5)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AlpesColors.verdeSelva.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text('Disponible',
                                          style: TextStyle(fontSize: 11,
                                              color: AlpesColors.verdeSelva,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ]),
                                if (_producto!.descripcion != null) ...[
                                  const SizedBox(height: 12),
                                  const Divider(color: AlpesColors.pergamino),
                                  const SizedBox(height: 10),
                                  Text(_producto!.descripcion!,
                                      style: const TextStyle(fontSize: 14,
                                          color: AlpesColors.grafito, height: 1.6)),
                                ],
                              ],
                            ),
                          ),

                          // ── Especificaciones ──
                          const Padding(
                            padding: EdgeInsets.fromLTRB(14, 18, 14, 8),
                            child: Row(children: [
                              SizedBox(width: 3, height: 15,
                                  child: DecoratedBox(decoration: BoxDecoration(
                                      color: AlpesColors.oroGuatemalteco,
                                      borderRadius: BorderRadius.all(Radius.circular(2))))),
                              SizedBox(width: 8),
                              Text('Especificaciones',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                      color: AlpesColors.cafeOscuro)),
                            ]),
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AlpesColors.pergamino),
                            ),
                            child: Column(children: [
                              _specRow('Material',   _producto!.material,   Icons.category_rounded),
                              _specRow('Color',      _producto!.color,      Icons.palette_rounded),
                              _specRow('Tipo',       _producto!.tipo,       Icons.label_rounded),
                            ].where((w) => w is! SizedBox).toList()),
                          ),

                          // ── Selector cantidad ──
                          Container(
                            margin: const EdgeInsets.fromLTRB(14, 18, 14, 100),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AlpesColors.pergamino),
                            ),
                            child: Row(children: [
                              const Text('Cantidad',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                      color: AlpesColors.cafeOscuro)),
                              const Spacer(),
                              _qtyBtn(Icons.remove_rounded,
                                  () => setState(() { if (_cantidad > 1) _cantidad--; })),
                              Container(
                                width: 44, height: 36,
                                alignment: Alignment.center,
                                child: Text('$_cantidad',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                        color: AlpesColors.cafeOscuro)),
                              ),
                              _qtyBtn(Icons.add_rounded,
                                  () => setState(() => _cantidad++)),
                            ]),
                          ),
                        ],
                      ),
                    ),

                    // ── Bottom bar fijo ──
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16, offset: const Offset(0, -4))],
                        ),
                        child: Row(children: [
                          if (_producto!.precio != null)
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Total',
                                  style: TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
                              Text('Q ${(_producto!.precio! * _cantidad).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                                      color: AlpesColors.cafeOscuro)),
                            ]),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                icon: _agregando
                                    ? const SizedBox(width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.shopping_bag_rounded),
                                label: Text(_agregando ? 'Agregando…' : 'Agregar al carrito'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AlpesColors.cafeOscuro,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontSize: 14,
                                      fontWeight: FontWeight.w700),
                                ),
                                onPressed: _agregando ? null : () async {
                                  if (auth.clienteId == null) {
                                    context.go('/login'); return;
                                  }
                                  setState(() => _agregando = true);
                                  await carrito.agregarItem(
                                    clienteId: auth.clienteId!,
                                    productoId: _producto!.productoId,
                                    nombre: _producto!.nombre,
                                    precio: _producto!.precio ?? 0,
                                    imagenUrl: _producto!.imagenUrl,
                                    cantidad: _cantidad,
                                  );
                                  if (mounted) {
                                    setState(() => _agregando = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(children: [
                                          const Icon(Icons.check_circle_rounded,
                                              color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text('${_producto!.nombre} agregado'),
                                        ]),
                                        backgroundColor: AlpesColors.verdeSelva,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10)),
                                        action: SnackBarAction(
                                          label: 'Ver carrito',
                                          textColor: AlpesColors.oroGuatemalteco,
                                          onPressed: () => context.go('/carrito'),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _imgPlaceholder() => const Center(
      child: Icon(Icons.chair_alt_rounded, size: 80, color: AlpesColors.arenaCalida));

  Widget _specRow(String label, String? value, IconData icon) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: AlpesColors.cafeOscuro)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13,
              color: AlpesColors.nogalMedio, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro)),
        ]),
      ),
      const Divider(height: 1, indent: 16, endIndent: 16, color: AlpesColors.pergamino),
    ]);
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: AlpesColors.cafeOscuro.withOpacity(0.07),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 18, color: AlpesColors.cafeOscuro),
    ),
  );
}
