import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('MI PERFIL'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AlpesColors.cafeOscuro,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AlpesColors.oroGuatemalteco,
                    child: Icon(Icons.person,
                        size: 40, color: AlpesColors.cafeOscuro),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    usuario?['USERNAME'] ?? usuario?['username'] ?? 'Usuario',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: AlpesColors.cremaFondo),
                  ),
                  Text(
                    usuario?['EMAIL'] ?? usuario?['email'] ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AlpesColors.arenaCalida),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _OpcionPerfil(
                icon: Icons.receipt_long_outlined,
                label: 'Mis órdenes',
                onTap: () => context.go('/mis-ordenes')),
            _OpcionPerfil(
                icon: Icons.favorite_outline,
                label: 'Mis favoritos',
                onTap: () => context.go('/favoritos')),
            _OpcionPerfil(
                icon: Icons.credit_card_outlined,
                label: 'Mis tarjetas',
                onTap: () => context.go('/mis-tarjetas')),
            _OpcionPerfil(
                icon: Icons.notifications_outlined,
                label: 'Notificaciones',
                onTap: () => context.go('/notificaciones')),
            _OpcionPerfil(
                icon: Icons.chat_bubble_outline,
                label: 'Soporte / Chat',
                onTap: () => context.go('/soporte')),
            _OpcionPerfil(
                icon: Icons.star_outline,
                label: 'Mis reseñas',
                onTap: () => context.go('/mis-resenas')),
            _OpcionPerfil(
                icon: Icons.location_on_outlined,
                label: 'Mis direcciones',
                onTap: () {}),
            _OpcionPerfil(
                icon: Icons.help_outline, label: 'Ayuda y FAQ', onTap: () {}),
            _OpcionPerfil(
                icon: Icons.settings_outlined,
                label: 'Configuración',
                onTap: () {}),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AlpesColors.rojoColonial),
                label: const Text('Cerrar sesión',
                    style: TextStyle(color: AlpesColors.rojoColonial)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AlpesColors.rojoColonial),
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OpcionPerfil extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OpcionPerfil(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AlpesColors.cafeOscuro),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: AlpesColors.arenaCalida),
      onTap: onTap,
    );
  }
}
