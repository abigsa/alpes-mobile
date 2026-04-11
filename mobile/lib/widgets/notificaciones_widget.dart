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
  final String titulo;
  final String subtitulo;
  final IconData icon;
  final Color color;
  final String tipo; // 'orden' | 'stock' | 'info'
  final String? route;
  const _Notificacion({
    required this.titulo,
    required this.subtitulo,
    required this.icon,
    required this.color,
    required this.tipo,
    this.route,
  });
}

// ─────────────────────────────────────────────────────────
//  PANEL DE NOTIFICACIONES
// ─────────────────────────────────────────────────────────
class NotificacionesPanel extends StatefulWidget {
  const NotificacionesPanel({super.key});
  @override
  State<NotificacionesPanel> createState() => _NotificacionesPanelState();
}

class _NotificacionesPanelState extends State<NotificacionesPanel> {
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

    await Future.wait([
      // Órdenes pendientes
      () async {
        try {
          final res  = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'));
          final data = jsonDecode(res.body);
          if (data['ok'] == true) {
            final list = data['data'] as List;
            final pendientes = list.where((o) {
              final e = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
              return e == 'pendiente';
            }).toList();
            if (pendientes.isNotEmpty) {
              lista.add(_Notificacion(
                titulo   : '${pendientes.length} orden${pendientes.length > 1 ? 'es' : ''} pendiente${pendientes.length > 1 ? 's' : ''}',
                subtitulo: 'Requieren atención inmediata',
                icon     : Icons.receipt_long_rounded,
                color    : const Color(0xFF854F0B),
                tipo     : 'orden',
                route    : '/admin/ordenes',
              ));
            }
            // Órdenes nuevas (últimas 24h simulado con las primeras)
            final nuevas = list.where((o) {
              final e = (o['ESTADO'] ?? o['estado'] ?? '').toString().toLowerCase();
              return e == 'nuevo' || e == 'recibido';
            }).length;
            if (nuevas > 0) {
              lista.add(_Notificacion(
                titulo   : '$nuevas nueva${nuevas > 1 ? 's' : ''} venta${nuevas > 1 ? 's' : ''}',
                subtitulo: 'Registradas recientemente',
                icon     : Icons.shopping_bag_rounded,
                color    : AlpesColors.verdeSelva,
                tipo     : 'orden',
                route    : '/admin/ordenes',
              ));
            }
          }
        } catch (_) {}
      }(),
      // Stock bajo
      () async {
        try {
          final res  = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventarioProducto}'));
          final data = jsonDecode(res.body);
          if (data['ok'] == true) {
            final list  = data['data'] as List;
            final bajos = list.where((i) {
              final qty = int.tryParse(
                  '${i['CANTIDAD'] ?? i['cantidad'] ?? i['STOCK'] ?? i['stock'] ?? 0}') ?? 0;
              return qty <= 5;
            }).toList();
            if (bajos.isNotEmpty) {
              lista.add(_Notificacion(
                titulo   : '${bajos.length} producto${bajos.length > 1 ? 's' : ''} con stock bajo',
                subtitulo: 'Cantidad ≤ 5 unidades',
                icon     : Icons.inventory_2_rounded,
                color    : AlpesColors.rojoColonial,
                tipo     : 'stock',
                route    : '/admin/inventario',
              ));
            }
            // Productos sin stock
            final sinStock = list.where((i) {
              final qty = int.tryParse(
                  '${i['CANTIDAD'] ?? i['cantidad'] ?? i['STOCK'] ?? i['stock'] ?? 0}') ?? 0;
              return qty == 0;
            }).length;
            if (sinStock > 0) {
              lista.add(_Notificacion(
                titulo   : '$sinStock producto${sinStock > 1 ? 's' : ''} sin stock',
                subtitulo: 'Agotados — requieren reabastecimiento',
                icon     : Icons.remove_shopping_cart_rounded,
                color    : AlpesColors.rojoColonial,
                tipo     : 'stock',
                route    : '/admin/inventario',
              ));
            }
          }
        } catch (_) {}
      }(),
    ]);

    // Si no hay nada, agregar mensaje de bienvenida
    if (lista.isEmpty) {
      lista.add(const _Notificacion(
        titulo   : 'Todo al día',
        subtitulo: 'No hay alertas pendientes',
        icon     : Icons.check_circle_rounded,
        color    : Color(0xFF3B6D11),
        tipo     : 'info',
      ));
    }

    if (mounted) setState(() { _notificaciones = lista; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15),
              blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
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
              if (!_loading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AlpesColors.rojoColonial,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_notificaciones.length}',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
          // Lista
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                      color: AlpesColors.cafeOscuro, strokeWidth: 2),
                )
              : Flexible(
                  child: RefreshIndicator(
                    color: AlpesColors.cafeOscuro,
                    onRefresh: _cargar,
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _notificaciones.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, indent: 16, endIndent: 16,
                          color: AlpesColors.pergamino),
                      itemBuilder: (_, i) {
                        final n = _notificaciones[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: n.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(n.icon, color: n.color, size: 20),
                          ),
                          title: Text(n.titulo,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: AlpesColors.cafeOscuro)),
                          subtitle: Text(n.subtitulo,
                              style: const TextStyle(
                                  fontSize: 11, color: AlpesColors.nogalMedio)),
                          trailing: n.route != null
                              ? const Icon(Icons.chevron_right_rounded,
                                  color: AlpesColors.arenaCalida, size: 18)
                              : null,
                          onTap: n.route != null
                              ? () => context.go(n.route!)
                              : null,
                        );
                      },
                    ),
                  ),
                ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AlpesColors.pergamino)),
            ),
            child: TextButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text('Actualizar', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AlpesColors.nogalMedio),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  BOTÓN con panel desplegable
// ─────────────────────────────────────────────────────────
class NotificacionesBtn extends StatelessWidget {
  final int count;
  const NotificacionesBtn({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.transparent,
      elevation: 0,
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: const NotificacionesPanel(),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(alignment: Alignment.topRight, children: [
          const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
          if (count > 0)
            Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(
                  color: AlpesColors.rojoColonial, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('$count',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 9, fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    );
  }
}
