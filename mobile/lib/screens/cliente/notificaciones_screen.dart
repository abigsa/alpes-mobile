import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../config/theme.dart';
import '../../config/api_config.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});
  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<_Notif> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final lista = <_Notif>[];

    // Promociones activas
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.promocion}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = data['data'] as List;
        if (list.isNotEmpty) {
          lista.add(_Notif(
            icon: Icons.local_offer_rounded,
            titulo: '🎉 ${list.length} oferta${list.length > 1 ? 's' : ''} disponible${list.length > 1 ? 's' : ''}',
            subtitulo: 'Ver productos en promoción',
            color: const Color(0xFF854F0B),
            route: '/catalogo',
          ));
        }
      }
    } catch (_) {}

    // Pedidos del cliente con estado
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list = data['data'] as List;

        for (final o in list.take(20)) {
          final estado = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
          final num = o['NUM_ORDEN'] ?? o['num_orden'] ?? o['ORDEN_VENTA_ID'] ?? '';
          final id = o['ORDEN_VENTA_ID'] ?? o['orden_venta_id'] ?? '';

          if (estado == 'aprobado' || estado == 'aprobada' ||
              estado == 'confirmado' || estado == 'confirmada') {
            lista.add(_Notif(
              icon: Icons.check_circle_rounded,
              titulo: '✅ Orden #$num aprobada',
              subtitulo: 'Ya estamos preparando tu pedido',
              color: const Color(0xFF3B6D11),
              route: '/orden/$id',
            ));
          } else if (estado == 'en proceso' || estado == 'preparando' || estado == 'pendiente') {
            lista.add(_Notif(
              icon: Icons.build_rounded,
              titulo: '🔨 Pedido #$num en preparación',
              subtitulo: 'Estamos trabajando en tu orden',
              color: const Color(0xFF854F0B),
              route: '/orden/$id',
            ));
          } else if (estado == 'en camino' || estado == 'en ruta' ||
              estado == 'enviado' || estado == 'despachado') {
            lista.add(_Notif(
              icon: Icons.local_shipping_rounded,
              titulo: '🚚 Pedido #$num en camino',
              subtitulo: 'Tu pedido está camino a tu dirección',
              color: const Color(0xFF185FA5),
              route: '/orden/$id',
            ));
          } else if (estado == 'entregado' || estado == 'entregada') {
            lista.add(_Notif(
              icon: Icons.inventory_2_rounded,
              titulo: '📦 Pedido #$num entregado',
              subtitulo: 'Califica tu experiencia',
              color: const Color(0xFF3B6D11),
              route: '/mis-resenas',
            ));
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() { _notifs = lista; _loading = false; });
  }

  int get _noLeidas => _notifs.where((n) => !n.leida).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        backgroundColor: AlpesColors.cafeOscuro,
        foregroundColor: Colors.white,
        title: Text(
          _noLeidas > 0 ? 'Notificaciones ($_noLeidas)' : 'Notificaciones',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          if (_noLeidas > 0)
            TextButton(
              onPressed: () => setState(() { for (final n in _notifs) n.leida = true; }),
              child: const Text('Marcar todo',
                  style: TextStyle(color: AlpesColors.oroGuatemalteco,
                      fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: AlpesColors.cafeOscuro, strokeWidth: 2))
          : _notifs.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.notifications_off_outlined,
                        size: 56, color: AlpesColors.arenaCalida.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('Todo al día ✓',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                            color: AlpesColors.cafeOscuro)),
                    const SizedBox(height: 6),
                    const Text('No tienes notificaciones pendientes',
                        style: TextStyle(color: AlpesColors.nogalMedio, fontSize: 13)),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Actualizar'),
                      onPressed: _cargar,
                      style: TextButton.styleFrom(foregroundColor: AlpesColors.cafeOscuro),
                    ),
                  ]),
                )
              : RefreshIndicator(
                  color: AlpesColors.cafeOscuro,
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemCount: _notifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = _notifs[i];
                      return GestureDetector(
                        onTap: () {
                          setState(() => n.leida = true);
                          if (n.route != null) context.go(n.route!);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: n.leida ? Colors.white : n.color.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: n.leida ? AlpesColors.pergamino : n.color.withOpacity(0.2),
                            ),
                            boxShadow: [BoxShadow(
                                color: AlpesColors.cafeOscuro.withOpacity(0.04),
                                blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: n.leida
                                      ? AlpesColors.pergamino
                                      : n.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(n.icon,
                                    color: n.leida ? AlpesColors.arenaCalida : n.color,
                                    size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.titulo, style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: n.leida ? FontWeight.w400 : FontWeight.w600,
                                      color: n.leida
                                          ? AlpesColors.nogalMedio
                                          : AlpesColors.cafeOscuro)),
                                  const SizedBox(height: 2),
                                  Text(n.subtitulo, style: const TextStyle(
                                      fontSize: 11, color: AlpesColors.arenaCalida)),
                                ],
                              )),
                              if (!n.leida)
                                Container(width: 9, height: 9,
                                    decoration: BoxDecoration(
                                        color: n.color, shape: BoxShape.circle))
                              else if (n.route != null)
                                const Icon(Icons.chevron_right_rounded,
                                    color: AlpesColors.arenaCalida, size: 18),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _Notif {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Color color;
  final String? route;
  bool leida;
  _Notif({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    this.route,
    this.leida = false,
  });
}
