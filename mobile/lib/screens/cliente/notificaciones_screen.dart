import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});
  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  late List<_Notif> _notifs;

  @override
  void initState() {
    super.initState();
    _notifs = [
      _Notif(Icons.local_shipping_outlined,
          'Tu pedido #ORD-0042 está en camino', 'Hace 2 horas', false),
      _Notif(Icons.check_circle_outline,
          'Pedido #ORD-0039 entregado con éxito', 'Ayer', true),
      _Notif(Icons.campaign_outlined,
          'Tienes un cupón de descuento del 10%', 'Hace 3 días', true),
      _Notif(Icons.payment_outlined,
          'Pago confirmado por Q1,890', 'Hace 5 días', true),
      _Notif(Icons.star_outline,
          'Califica tu último pedido', 'Hace 7 días', true),
    ];
  }

  int get _noLeidas => _notifs.where((n) => !n.leida).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: Text(_noLeidas > 0 ? 'Notificaciones ($_noLeidas)' : 'Notificaciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          if (_noLeidas > 0)
            TextButton(
              onPressed: () => setState(() {
                for (final n in _notifs) n.leida = true;
              }),
              child: const Text('Marcar todo',
                  style: TextStyle(color: AlpesColors.oroGuatemalteco,
                      fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _notifs.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
        itemBuilder: (_, i) {
          final n = _notifs[i];
          return GestureDetector(
            onTap: () => setState(() => n.leida = true),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: n.leida
                    ? AlpesColors.pergamino
                    : AlpesColors.oroGuatemalteco.withOpacity(0.2),
                child: Icon(n.icon, size: 20,
                    color: n.leida
                        ? AlpesColors.arenaCalida
                        : AlpesColors.oroGuatemalteco),
              ),
              title: Text(n.titulo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: n.leida ? FontWeight.w400 : FontWeight.w600,
                    color: AlpesColors.cafeOscuro,
                  )),
              subtitle: Text(n.tiempo,
                  style: const TextStyle(
                      fontSize: 11, color: AlpesColors.arenaCalida)),
              trailing: n.leida
                  ? null
                  : Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AlpesColors.oroGuatemalteco,
                      ),
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
  bool leida;
  _Notif(this.icon, this.titulo, this.tiempo, this.leida);
}
