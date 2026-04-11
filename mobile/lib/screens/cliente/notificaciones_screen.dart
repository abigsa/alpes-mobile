import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  static const _notifs = [
    _Notif(Icons.local_shipping_outlined, 'Tu pedido #ORD-0042 está en camino', 'Hace 2 horas', false),
    _Notif(Icons.check_circle_outline, 'Pedido #ORD-0039 entregado con éxito', 'Ayer', true),
    _Notif(Icons.campaign_outlined, 'Tienes un cupón de descuento del 10%', 'Hace 3 días', true),
    _Notif(Icons.payment_outlined, 'Pago confirmado por Q1,890', 'Hace 5 días', true),
    _Notif(Icons.star_outline, 'Califica tu último pedido', 'Hace 7 días', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('NOTIFICACIONES'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _notifs.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
        itemBuilder: (context, i) {
          final n = _notifs[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: n.leida
                  ? AlpesColors.pergamino
                  : AlpesColors.oroGuatemalteco.withOpacity(0.2),
              child: Icon(n.icon,
                  size: 20,
                  color: n.leida ? AlpesColors.arenaCalida : AlpesColors.oroGuatemalteco),
            ),
            title: Text(n.titulo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: n.leida ? FontWeight.w400 : FontWeight.w600,
                  color: AlpesColors.cafeOscuro,
                )),
            subtitle: Text(n.tiempo,
                style: const TextStyle(fontSize: 11, color: AlpesColors.arenaCalida)),
            trailing: n.leida
                ? null
                : Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AlpesColors.oroGuatemalteco,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _Notif {
  final IconData icon;
  final String titulo;
  final String tiempo;
  final bool leida;
  const _Notif(this.icon, this.titulo, this.tiempo, this.leida);
}
