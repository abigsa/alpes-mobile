import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/favoritos_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/producto_provider.dart';
import '../providers/carrito_provider.dart';

class ProductoCard extends StatefulWidget {
  final Producto producto;
  const ProductoCard({super.key, required this.producto});
  @override
  State<ProductoCard> createState() => _ProductoCardState();
}

class _ProductoCardState extends State<ProductoCard>
    with SingleTickerProviderStateMixin {
  bool _hovered  = false;
  bool _pressed  = false;
  bool _agregando = false;
  late AnimationController _favCtrl;
  late Animation<double>   _favAnim;

  @override
  void initState() {
    super.initState();
    _favCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 300));
    _favAnim = CurvedAnimation(parent: _favCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() { _favCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final favs  = context.watch<FavoritosProvider>();
    final auth  = context.read<AuthProvider>();
    final esFav = favs.esFavorito(widget.producto.productoId);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) => setState(() => _pressed = false),
        onTapCancel: ()  => setState(() => _pressed = false),
        onTap: () => context.push('/producto/${widget.producto.productoId}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, _pressed ? 2.0 : _hovered ? -3.0 : 0.0)
            ..scale(_pressed ? 0.97 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? AlpesColors.oroGuatemalteco.withOpacity(0.5)
                  : AlpesColors.pergamino,
              width: _hovered ? 1.5 : 1.0,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.12),
                    blurRadius: 16, offset: const Offset(0, 6)),
                   BoxShadow(color: AlpesColors.oroGuatemalteco.withOpacity(0.08),
                    blurRadius: 6, offset: const Offset(0, 2))]
                : [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
                    blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Imagen ──
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  child: Stack(children: [
                    // Fondo imagen
                    Container(
                      width: double.infinity,
                      color: AlpesColors.cremaFondo,
                      child: widget.producto.imagenUrl != null
                          ? Image.network(
                              widget.producto.imagenUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    // Línea top dorada hover
                    if (_hovered)
                      Positioned(top: 0, left: 0, right: 0,
                        child: Container(height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              AlpesColors.oroGuatemalteco.withOpacity(0.8),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                    // Badge tipo
                    if (widget.producto.tipo != null)
                      Positioned(top: 7, left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AlpesColors.cafeOscuro.withOpacity(0.82),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(widget.producto.tipo!,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 8, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    // Botón favorito
                    Positioned(top: 5, right: 5,
                      child: GestureDetector(
                        onTap: () {
                          if (auth.clienteId != null) {
                            favs.toggleFavorito(clienteId: auth.clienteId!,
                                productoId: widget.producto.productoId);
                            context.read<ProductoProvider>()
                                .registrarFavorito(widget.producto.productoId);
                            _favCtrl.forward(from: 0);
                          }
                        },
                        child: ScaleTransition(
                          scale: Tween(begin: 1.0, end: 1.4).animate(_favAnim),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: esFav
                                  ? AlpesColors.rojoColonial
                                  : Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Icon(
                              esFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 14,
                              color: esFav ? Colors.white : AlpesColors.arenaCalida,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              // ── Info ──
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 6, 9, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.producto.nombre,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                            color: AlpesColors.cafeOscuro, height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.producto.precio != null)
                            Text('Q ${widget.producto.precio!.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AlpesColors.cafeOscuro)),
                          // Botón agregar rápido
                          GestureDetector(
                            onTap: _agregando ? null : () async {
                              final auth2  = context.read<AuthProvider>();
                              final carrito = context.read<CarritoProvider>();
                              if (auth2.clienteId == null) { context.go('/login'); return; }
                              setState(() => _agregando = true);
                              await carrito.agregarItem(
                                clienteId: auth2.clienteId!,
                                productoId: widget.producto.productoId,
                                nombre   : widget.producto.nombre,
                                precio   : widget.producto.precio ?? 0,
                                imagenUrl: widget.producto.imagenUrl,
                                cantidad : 1,
                              );
                              if (mounted) setState(() => _agregando = false);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 26, height: 26,
                              decoration: BoxDecoration(
                                color: _agregando
                                    ? AlpesColors.verdeSelva
                                    : AlpesColors.cafeOscuro,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: _agregando
                                  ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 1.5))
                                  : const Icon(Icons.add_rounded,
                                      color: Colors.white, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Center(
    child: Icon(Icons.chair_alt_rounded,
        size: 36,  // Reducido de 48 a 36
        color: AlpesColors.arenaCalida.withOpacity(0.4)),
  );
}
