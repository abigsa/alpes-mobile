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
//  Usa OverlayEntry + CompositedTransformFollower para que el
//  panel siempre aparezca encima de todo el árbol de widgets.
// ─────────────────────────────────────────────────────────
class NotificacionesBtn extends StatefulWidget {
  final int count;
  final bool isAdmin;
  const NotificacionesBtn({
    super.key,
    required this.count,
    this.isAdmin = false,
  });
  @override
  State<NotificacionesBtn> createState() => _NotificacionesBtnState();
}

class _NotificacionesBtnState extends State<NotificacionesBtn>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

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
    _cerrarOverlay();
    _animCtrl.dispose();
    super.dispose();
  }

  void _cerrarOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _cerrar() {
    if (!_open) return;
    _animCtrl.reverse().then((_) {
      _cerrarOverlay();
      if (mounted) setState(() => _open = false);
    });
  }

  void _toggle() {
    if (_open) {
      _cerrar();
    } else {
      setState(() => _open = true);
      _overlayEntry = _buildOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _animCtrl.forward();
    }
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Área transparente que cierra el panel al tocar fuera
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _cerrar,
              child: const SizedBox.expand(),
            ),
          ),
          // Panel anclado a la campana mediante LayerLink
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(-286, 46),
            child: Align(
              alignment: Alignment.topLeft,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  alignment: Alignment.topRight,
                  child: Material(
                    color: Colors.transparent,
                    child: widget.isAdmin
                        ? _BurbujaPanelAdmin(onClose: _cerrar)
                        : _BurbujaPanel(onClose: _cerrar),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Stack(alignment: Alignment.topRight, children: [
            Icon(
              _open
                  ? Icons.notifications_rounded
                  : Icons.notifications_outlined,
              color: _open ? AlpesColors.oroGuatemalteco : Colors.white,
              size: 22,
            ),
            if (widget.count > 0)
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                    color: AlpesColors.rojoColonial, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('${widget.count}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PANEL CLIENTE
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

    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.promocion}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = data['data'] as List;
        if (list.isNotEmpty) {
          lista.add(_Notificacion(
            id: 'promo',
            titulo:
                '🎉 ${list.length} oferta${list.length > 1 ? 's' : ''} disponible${list.length > 1 ? 's' : ''}',
            subtitulo: 'Ver productos en promoción',
            icon: Icons.local_offer_rounded,
            color: const Color(0xFF854F0B),
            tipo: 'promo',
            route: '/catalogo',
          ));
        }
      }
    } catch (_) {}

    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = data['data'] as List;

        final aprobadas = list.where((o) {
          final e = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
          return e == 'aprobado' ||
              e == 'aprobada' ||
              e == 'confirmado' ||
              e == 'confirmada';
        }).length;
        if (aprobadas > 0) {
          lista.add(_Notificacion(
            id: 'aprobada',
            titulo:
                '✅ ${aprobadas == 1 ? "Tu orden fue aprobada" : "$aprobadas órdenes aprobadas"}',
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
            titulo:
                '🔨 ${enProceso == 1 ? "Pedido en preparación" : "$enProceso pedidos en proceso"}',
            subtitulo: 'Estamos trabajando en tu orden',
            icon: Icons.build_rounded,
            color: const Color(0xFF854F0B),
            tipo: 'orden',
            route: '/mis-ordenes',
          ));
        }

        final enRuta = list.where((o) {
          final e = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
          return e == 'en camino' ||
              e == 'en ruta' ||
              e == 'enviado' ||
              e == 'despachado';
        }).length;
        if (enRuta > 0) {
          lista.add(_Notificacion(
            id: 'ruta',
            titulo:
                '🚚 ${enRuta == 1 ? "Tu pedido está en camino" : "$enRuta pedidos en ruta"}',
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
            titulo:
                '📦 ${entregados == 1 ? "Pedido entregado" : "$entregados pedidos entregados"}',
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

    if (mounted)
      setState(() {
        _notificaciones = lista;
        _loading = false;
      });
  }

  void _marcarLeida(String id) {
    setState(() {
      final n = _notificaciones.firstWhere((n) => n.id == id,
          orElse: () => _notificaciones.first);
      n.leida = true;
    });
  }

  void _marcarTodasLeidas() {
    setState(() {
      for (final n in _notificaciones) {
        n.leida = true;
      }
    });
  }

  int get _noLeidas => _notificaciones.where((n) => !n.leida).length;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      titulo: 'Notificaciones',
      noLeidas: _noLeidas,
      loading: _loading,
      onMarcarTodas: _marcarTodasLeidas,
      onRefresh: _cargar,
      notificaciones: _notificaciones,
      onTap: (n) {
        _marcarLeida(n.id);
        if (n.route != null) {
          widget.onClose();
          context.go(n.route!);
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  PANEL ADMIN
// ─────────────────────────────────────────────────────────
class _BurbujaPanelAdmin extends StatefulWidget {
  final VoidCallback onClose;
  const _BurbujaPanelAdmin({required this.onClose});
  @override
  State<_BurbujaPanelAdmin> createState() => _BurbujaPanelAdminState();
}

class _BurbujaPanelAdminState extends State<_BurbujaPanelAdmin> {
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

    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'));
      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        final list = data['data'] as List;

        String est(dynamic o) =>
            (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase().trim();

        final nuevos = list.where((o) {
          final e = est(o);
          return e == 'nuevo' ||
              e == 'nueva' ||
              e == 'pendiente' ||
              e == 'recibido';
        }).toList();
        if (nuevos.isNotEmpty) {
          lista.add(_Notificacion(
            id: 'admin_nuevos',
            titulo:
                '🆕 ${nuevos.length} pedido${nuevos.length > 1 ? 's' : ''} nuevo${nuevos.length > 1 ? 's' : ''}',
            subtitulo: 'Requieren aprobación',
            icon: Icons.inbox_rounded,
            color: const Color(0xFFB04500),
            tipo: 'admin_orden',
            route: '/admin/ordenes',
          ));
        }

        final porAprobar = list.where((o) {
          final e = est(o);
          return e == 'por aprobar' || e == 'en revision' || e == 'en revisión';
        }).toList();
        if (porAprobar.isNotEmpty) {
          lista.add(_Notificacion(
            id: 'admin_aprobar',
            titulo:
                '⏳ ${porAprobar.length} orden${porAprobar.length > 1 ? 'es' : ''} por aprobar',
            subtitulo: 'Pendientes de tu confirmación',
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFF854F0B),
            tipo: 'admin_orden',
            route: '/admin/ordenes',
          ));
        }

        final aprobadas = list.where((o) {
          final e = est(o);
          return e == 'aprobado' ||
              e == 'aprobada' ||
              e == 'confirmado' ||
              e == 'confirmada';
        }).toList();
        if (aprobadas.isNotEmpty) {
          lista.add(_Notificacion(
            id: 'admin_aprobadas',
            titulo:
                '✅ ${aprobadas.length} orden${aprobadas.length > 1 ? 'es' : ''} aprobada${aprobadas.length > 1 ? 's' : ''}',
            subtitulo: 'Listas para preparar',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF3B6D11),
            tipo: 'admin_orden',
            route: '/admin/ordenes',
          ));
        }

        final enProceso = list.where((o) {
          final e = est(o);
          return e == 'en proceso' ||
              e == 'preparando' ||
              e == 'en preparacion' ||
              e == 'en preparación';
        }).toList();
        if (enProceso.isNotEmpty) {
          lista.add(_Notificacion(
            id: 'admin_proceso',
            titulo:
                '🔨 ${enProceso.length} pedido${enProceso.length > 1 ? 's' : ''} en preparación',
            subtitulo: 'En bodega o producción',
            icon: Icons.build_rounded,
            color: const Color(0xFF854F0B),
            tipo: 'admin_orden',
            route: '/admin/ordenes',
          ));
        }

        final enRuta = list.where((o) {
          final e = est(o);
          return e == 'en camino' ||
              e == 'en ruta' ||
              e == 'enviado' ||
              e == 'despachado';
        }).toList();
        if (enRuta.isNotEmpty) {
          lista.add(_Notificacion(
            id: 'admin_ruta',
            titulo:
                '🚚 ${enRuta.length} pedido${enRuta.length > 1 ? 's' : ''} en ruta',
            subtitulo: 'Camino al cliente',
            icon: Icons.local_shipping_rounded,
            color: const Color(0xFF185FA5),
            tipo: 'admin_orden',
            route: '/admin/ordenes',
          ));
        }

        final entregados = list.where((o) {
          final e = est(o);
          return e == 'entregado' || e == 'entregada';
        }).toList();
        if (entregados.isNotEmpty) {
          lista.add(_Notificacion(
            id: 'admin_entregados',
            titulo:
                '📦 ${entregados.length} pedido${entregados.length > 1 ? 's' : ''} entregado${entregados.length > 1 ? 's' : ''}',
            subtitulo: 'Completados exitosamente',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF3B6D11),
            tipo: 'admin_orden',
            route: '/admin/ordenes',
          ));
        }

        final cancelados = list.where((o) {
          final e = est(o);
          return e == 'cancelado' ||
              e == 'cancelada' ||
              e == 'rechazado' ||
              e == 'rechazada';
        }).toList();
        if (cancelados.isNotEmpty) {
          lista.add(_Notificacion(
            id: 'admin_cancelados',
            titulo:
                '❌ ${cancelados.length} orden${cancelados.length > 1 ? 'es' : ''} cancelada${cancelados.length > 1 ? 's' : ''}',
            subtitulo: 'Revisar motivo de cancelación',
            icon: Icons.cancel_rounded,
            color: const Color(0xFF8B0000),
            tipo: 'admin_orden',
            route: '/admin/ordenes',
          ));
        }

        if (lista.isNotEmpty) {
          lista.insert(
              0,
              _Notificacion(
                id: 'admin_resumen',
                titulo:
                    '📋 Total: ${list.length} orden${list.length > 1 ? 'es' : ''} en el sistema',
                subtitulo: 'Ver todas las órdenes',
                icon: Icons.list_alt_rounded,
                color: const Color(0xFF2C2C2C),
                tipo: 'admin_resumen',
                route: '/admin/ordenes',
                leida: true,
              ));
        }
      }
    } catch (_) {}

    if (lista.isEmpty) {
      lista.add(_Notificacion(
        id: 'admin_ok',
        titulo: 'Sin pedidos pendientes ✓',
        subtitulo: 'No hay órdenes en el sistema',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF3B6D11),
        tipo: 'info',
      ));
    }

    if (mounted)
      setState(() {
        _notificaciones = lista;
        _loading = false;
      });
  }

  void _marcarLeida(String id) {
    setState(() {
      final n = _notificaciones.firstWhere((n) => n.id == id,
          orElse: () => _notificaciones.first);
      n.leida = true;
    });
  }

  void _marcarTodasLeidas() {
    setState(() {
      for (final n in _notificaciones) {
        n.leida = true;
      }
    });
  }

  int get _noLeidas => _notificaciones.where((n) => !n.leida).length;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      titulo: 'Pedidos — Admin',
      noLeidas: _noLeidas,
      loading: _loading,
      onMarcarTodas: _marcarTodasLeidas,
      onRefresh: _cargar,
      notificaciones: _notificaciones,
      onTap: (n) {
        _marcarLeida(n.id);
        if (n.route != null) {
          widget.onClose();
          context.go(n.route!);
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SHELL COMPARTIDO
// ─────────────────────────────────────────────────────────
class _PanelShell extends StatelessWidget {
  final String titulo;
  final int noLeidas;
  final bool loading;
  final VoidCallback onMarcarTodas;
  final VoidCallback onRefresh;
  final List<_Notificacion> notificaciones;
  final void Function(_Notificacion) onTap;

  const _PanelShell({
    required this.titulo,
    required this.noLeidas,
    required this.loading,
    required this.onMarcarTodas,
    required this.onRefresh,
    required this.notificaciones,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 8)),
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
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
              Expanded(
                child: Text(titulo,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
              if (noLeidas > 0)
                GestureDetector(
                  onTap: onMarcarTodas,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
                    ),
                    child: const Text('Marcar todas',
                        style: TextStyle(
                            color: AlpesColors.oroGuatemalteco,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF3B6D11).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Al día ✓',
                      style: TextStyle(
                          color: Color(0xFF3B6D11),
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
            ]),
          ),

          // ── Lista ──
          loading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                      color: AlpesColors.cafeOscuro, strokeWidth: 2))
              : Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: notificaciones.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AlpesColors.pergamino),
                    itemBuilder: (ctx, i) {
                      final n = notificaciones[i];
                      return GestureDetector(
                        onTap: () => onTap(n),
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
                              width: 40,
                              height: 40,
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
                            Expanded(
                              child: Column(
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
                              ),
                            ),
                            if (!n.leida)
                              Container(
                                width: 8,
                                height: 8,
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
                onPressed: onRefresh,
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
