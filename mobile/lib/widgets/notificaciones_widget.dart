import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../config/theme.dart';
import '../config/api_config.dart';

// ─────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────
class _Notificacion {
  final String id;
  final String titulo;
  final String subtitulo;
  final IconData icon;
  final Color color;
  final String tipo;
  final String? route;
  bool leida;
  _Notificacion({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.icon,
    required this.color,
    required this.tipo,
    this.route,
    this.leida = false,
  });
}

// ─────────────────────────────────────────────────────────
//  BOTÓN — campana con burbuja
// ─────────────────────────────────────────────────────────
class NotificacionesBtn extends StatefulWidget {
  final int count;
  const NotificacionesBtn({super.key, required this.count});
  @override
  State<NotificacionesBtn> createState() => _NotificacionesBtnState();
}

class _NotificacionesBtnState extends State<NotificacionesBtn>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _animCtrl.forward() : _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Campana
        GestureDetector(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Stack(alignment: Alignment.topRight, children: [
              Icon(
                _open
                    ? Icons.notifications_rounded
                    : Icons.notifications_outlined,
                color: _open
                    ? AlpesColors.oroGuatemalteco
                    : Colors.white,
                size: 22,
              ),
              if (widget.count > 0)
                Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                      color: AlpesColors.rojoColonial, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('${widget.count}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
        ),

        // Burbuja panel — desplegable animado
        if (_open)
          Positioned(
            top: 40, right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                alignment: Alignment.topRight,
                child: Material(
                  color: Colors.transparent,
                  child: _BurbujaPanel(
                    onClose: _toggle,
                  ),
                ),
              ),
            ),
          ),

        // Overlay para cerrar al tocar fuera
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggle,
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  BURBUJA PANEL
// ─────────────────────────────────────────────────────────
class _BurbujaPanel extends StatefulWidget {
  final VoidCallback onClose;
  const _BurbujaPanel({required this.onClose});
  @override
  State<_BurbujaPanel> createState() => _BurbujaPanelState();
}

class _BurbujaPanelState extends State<_BurbujaPanel> {
  List<_Notificacion> _notificaciones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final lista = <_Notificacion>[];

    // Promociones activas
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.promocion}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = data['data'] as List;
        if (list.isNotEmpty) {
          lista.add(_Notificacion(
            id: 'promo',
            titulo: '🎉 ${list.length} oferta${list.length > 1 ? 's' : ''} disponible${list.length > 1 ? 's' : ''}',
            subtitulo: 'Ver productos en promoción',
            icon: Icons.local_offer_rounded,
            color: const Color(0xFF854F0B),
            tipo: 'promo',
            route: '/catalogo',
          ));
        }
      }
    } catch (_) {}

    // Estados de pedidos del cliente
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = data['data'] as List;

        final aprobadas = list.where((o) {
          final e = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
          return e == 'aprobado' || e == 'aprobada' || e == 'confirmado' || e == 'confirmada';
        }).length;
        if (aprobadas > 0) {
          lista.add(_Notificacion(
            id: 'aprobada',
            titulo: '✅ ${aprobadas == 1 ? "Tu orden fue aprobada" : "$aprobadas órdenes aprobadas"}',
            subtitulo: 'Ya estamos preparando tu pedido',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF3B6D11),
            tipo: 'orden',
            route: '/mis-ordenes',
          ));
        }

        final enProceso = list.where((o) {
          final e = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
          return e == 'en proceso' || e == 'preparando' || e == 'pendiente';
        }).length;
        if (enProceso > 0) {
          lista.add(_Notificacion(
            id: 'proceso',
            titulo: '🔨 ${enProceso == 1 ? "Pedido en preparación" : "$enProceso pedidos en proceso"}',
            subtitulo: 'Estamos trabajando en tu orden',
            icon: Icons.build_rounded,
            color: const Color(0xFF854F0B),
            tipo: 'orden',
            route: '/mis-ordenes',
          ));
        }

        final enRuta = list.where((o) {
          final e = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
          return e == 'en camino' || e == 'en ruta' || e == 'enviado' || e == 'despachado';
        }).length;
        if (enRuta > 0) {
          lista.add(_Notificacion(
            id: 'ruta',
            titulo: '🚚 ${enRuta == 1 ? "Tu pedido está en camino" : "$enRuta pedidos en ruta"}',
            subtitulo: 'Camino a tu dirección',
            icon: Icons.local_shipping_rounded,
            color: const Color(0xFF185FA5),
            tipo: 'orden',
            route: '/mis-ordenes',
          ));
        }

        final entregados = list.where((o) {
          final e = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
          return e == 'entregado' || e == 'entregada';
        }).length;
        if (entregados > 0) {
          lista.add(_Notificacion(
            id: 'entregado',
            titulo: '📦 ${entregados == 1 ? "Pedido entregado" : "$entregados pedidos entregados"}',
            subtitulo: 'Califica tu experiencia',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF3B6D11),
            tipo: 'orden',
            route: '/mis-resenas',
          ));
        }
      }
    } catch (_) {}

    if (lista.isEmpty) {
      lista.add(_Notificacion(
        id: 'ok',
        titulo: 'Todo al día ✓',
        subtitulo: 'Sin notificaciones pendientes',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF3B6D11),
        tipo: 'info',
      ));
    }

    if (mounted) setState(() { _notificaciones = lista; _loading = false; });
  }

  void _marcarLeida(String id) {
    setState(() {
      final n = _notificaciones.firstWhere((n) => n.id == id, orElse: () => _notificaciones.first);
      n.leida = true;
    });
  }

  void _marcarTodasLeidas() {
    setState(() {
      for (final n in _notificaciones) { n.leida = true; }
    });
  }

  int get _noLeidas => _notificaciones.where((n) => !n.leida).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18),
              blurRadius: 28, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 6, offset: const Offset(0, 2)),
        ],
        // Triangulito superior derecho (burbuja)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: const BoxDecoration(
              color: AlpesColors.cafeOscuro,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.notifications_rounded,
                  color: AlpesColors.oroGuatemalteco, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Notificaciones',
                    style: TextStyle(color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
              if (_noLeidas > 0)
                GestureDetector(
                  onTap: _marcarTodasLeidas,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
                    ),
                    child: const Text('Marcar todas',
                        style: TextStyle(color: AlpesColors.oroGuatemalteco,
                            fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF3B6D11).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Al día ✓',
                      style: TextStyle(color: Color(0xFF3B6D11),
                          fontSize: 10, fontWeight: FontWeight.w600)),
                ),
            ]),
          ),

          // ── Lista ──
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                      color: AlpesColors.cafeOscuro, strokeWidth: 2))
              : Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _notificaciones.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 16, endIndent: 16,
                        color: AlpesColors.pergamino),
                    itemBuilder: (ctx, i) {
                      final n = _notificaciones[i];
                      return GestureDetector(
                        onTap: () {
                          _marcarLeida(n.id);
                          if (n.route != null) {
                            widget.onClose();
                            ctx.go(n.route!);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          color: n.leida
                              ? Colors.transparent
                              : n.color.withOpacity(0.04),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: n.leida
                                    ? AlpesColors.pergamino
                                    : n.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(n.icon,
                                  color: n.leida
                                      ? AlpesColors.arenaCalida
                                      : n.color,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.titulo,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: n.leida
                                            ? FontWeight.w400
                                            : FontWeight.w600,
                                        color: n.leida
                                            ? AlpesColors.nogalMedio
                                            : AlpesColors.cafeOscuro)),
                                Text(n.subtitulo,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AlpesColors.nogalMedio)),
                              ],
                            )),
                            // Indicador no leída
                            if (!n.leida)
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                    color: n.color, shape: BoxShape.circle),
                              )
                            else if (n.route != null)
                              const Icon(Icons.chevron_right_rounded,
                                  color: AlpesColors.arenaCalida, size: 18),
                          ]),
                        ),
                      );
                    },
                  ),
                ),

          // ── Footer ──
          Container(
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AlpesColors.pergamino))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Actualizar', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: AlpesColors.nogalMedio),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
