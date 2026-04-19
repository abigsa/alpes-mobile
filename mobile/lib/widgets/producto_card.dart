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
  bool _hovered   = false;
  bool _agregando = false;
  late AnimationController _favCtrl;
  late Animation<double>   _favAnim;

  @override
  void initState() {
    super.initState();
    _favCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 350));
    _favAnim = CurvedAnimation(parent: _favCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() { _favCtrl.dispose(); super.dispose(); }

  Color _tipoColor(String? tipo) {
    switch ((tipo ?? '').toLowerCase()) {
      case 'sala':       return const Color(0xFF185FA5);
      case 'comedor':    return const Color(0xFF854F0B);
      case 'dormitorio': return const Color(0xFF3B6D11);
      case 'oficina':    return const Color(0xFF533AB7);
      case 'exterior':   return const Color(0xFF0F6E56);
      default:           return AlpesColors.nogalMedio;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favs    = context.watch<FavoritosProvider>();
    final auth    = context.read<AuthProvider>();
    final carrito = context.read<CarritoProvider>();
    final p       = widget.producto;
    final esFav   = favs.esFavorito(p.productoId);
    final tc      = _tipoColor(p.tipo);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/producto/${p.productoId}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? AlpesColors.oroGuatemalteco.withOpacity(0.6)
                  : AlpesColors.pergamino,
              width: _hovered ? 1.5 : 1.0,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.14),
                        blurRadius: 20, offset: const Offset(0, 8)),
                    BoxShadow(color: AlpesColors.oroGuatemalteco.withOpacity(0.1),
                        blurRadius: 8, offset: const Offset(0, 2)),
                  ]
                : [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.06),
                    blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── IMAGEN ──────────────────────────────
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(fit: StackFit.expand, children: [
                    p.imagenUrl != null
                        ? Image.network(p.imagenUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),

                    // Badge tipo
                    if (p.tipo != null)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tc,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(p.tipo!.toUpperCase(),
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 8, fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8)),
                        ),
                      ),

                    // Botón favorito
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          if (auth.clienteId == null) return;
                          _favCtrl.forward(from: 0);
                          await favs.toggleFavorito(
                            clienteId: auth.clienteId!,
                            productoId: p.productoId,
                          );
                          if (mounted) setState(() {});
                        },
                        child: ScaleTransition(
                          scale: _favAnim,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: esFav
                                  ? AlpesColors.rojoColonial
                                  : Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Icon(
                              esFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: esFav
                                  ? Colors.white
                                  : AlpesColors.arenaCalida,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              // ── INFO ────────────────────────────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nombre,
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AlpesColors.cafeOscuro, height: 1.2),
                          maxLines: 2, overflow: TextOverflow.ellipsis),

                      if (p.descripcion != null &&
                          p.descripcion!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(p.descripcion!,
                            style: const TextStyle(fontSize: 10,
                                color: AlpesColors.nogalMedio, height: 1.3),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],

                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PRECIO',
                                  style: TextStyle(fontSize: 8,
                                      color: AlpesColors.arenaCalida,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8)),
                              Text(
                                p.precio != null
                                    ? 'Q ${p.precio!.toStringAsFixed(2)}'
                                    : 'Consultar',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AlpesColors.cafeOscuro,
                                    letterSpacing: -0.5),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _agregando ? null : () async {
                              if (auth.clienteId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Inicia sesión primero'),
                                        behavior: SnackBarBehavior.floating));
                                return;
                              }
                              setState(() => _agregando = true);
                              await carrito.agregarItem(
                                clienteId:  auth.clienteId!,
                                productoId: p.productoId,
                                nombre:     p.nombre,
                                precio:     p.precio ?? 0,
                              );
                              if (mounted) {
                                setState(() => _agregando = false);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content:
                                      Text('${p.nombre} agregado al carrito'),
                                  backgroundColor: AlpesColors.verdeSelva,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  duration: const Duration(seconds: 2),
                                ));
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: _agregando
                                    ? AlpesColors.cafeOscuro.withOpacity(0.6)
                                    : AlpesColors.cafeOscuro,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [BoxShadow(
                                    color: AlpesColors.cafeOscuro
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))],
                              ),
                              child: _agregando
                                  ? const Center(
                                      child: SizedBox(
                                          width: 14, height: 14,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2)))
                                  : const Icon(
                                      Icons.add_shopping_cart_rounded,
                                      color: AlpesColors.oroGuatemalteco,
                                      size: 12),
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

  Widget _placeholder() => Container(
        color: AlpesColors.cremaFondo,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chair_alt_rounded,
                  size: 32,
                  color: AlpesColors.arenaCalida.withOpacity(0.4)),
            ]),
      );
}
