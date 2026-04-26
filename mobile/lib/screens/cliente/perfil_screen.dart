import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_nav_cliente.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final nombre   = auth.nombreCompleto;
    final email    = auth.usuario?['EMAIL']    ?? auth.usuario?['email']    ?? '';
    final username = auth.usuario?['USERNAME'] ?? auth.usuario?['username'] ?? '';
    final initial  = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      bottomNavigationBar: const BottomNavCliente(currentIndex: 4),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AlpesColors.cafeOscuro,
            leading: IconButton(
              icon: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
              ),
              onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
            ),
            actions: [
              IconButton(
                icon: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF1A0E08), Color(0xFF2C1810), Color(0xFF3D2416)],
                    ),
                  ),
                ),
                // Círculos decorativos
                Positioned(top: -40, right: -40,
                  child: Container(width: 160, height: 160,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: AlpesColors.oroGuatemalteco.withOpacity(0.07)))),
                Positioned(bottom: 20, right: 80,
                  child: Container(width: 50, height: 50,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: AlpesColors.oroGuatemalteco.withOpacity(0.05)))),
                // Contenido del hero
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      // Avatar
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8B84B), Color(0xFFD4A853)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(
                            color: AlpesColors.oroGuatemalteco.withOpacity(0.5),
                            blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        alignment: Alignment.center,
                        child: Text(initial, style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w800,
                          color: AlpesColors.cafeOscuro)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombre.isNotEmpty ? nombre : username,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: 0.2)),
                          const SizedBox(height: 3),
                          if (email.isNotEmpty)
                            Text(email, style: TextStyle(fontSize: 12,
                              color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.star_rounded, size: 12, color: AlpesColors.oroGuatemalteco),
                              const SizedBox(width: 4),
                              const Text('Cliente VIP', style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: AlpesColors.oroGuatemalteco)),
                            ]),
                          ),
                        ],
                      )),
                    ]),
                  ),
                ),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [

                // ── Stats rápidas ──
                Row(children: [
                  _statCard('Pedidos', '0', Icons.shopping_bag_rounded, context),
                  const SizedBox(width: 10),
                  _statCard('Favoritos', '0', Icons.favorite_rounded, context),
                  const SizedBox(width: 10),
                  _statCard('Reseñas', '0', Icons.star_rounded, context),
                ]),
                const SizedBox(height: 20),

                // ── Sección Mi Cuenta ──
                _sectionHeader('Mi cuenta'),
                const SizedBox(height: 10),
                _menuCard([
                  _MenuItem('Mis órdenes', Icons.receipt_long_rounded, () => context.go('/mis-ordenes')),
                  _MenuItem('Mis favoritos', Icons.favorite_rounded, () => context.go('/favoritos')),
                  _MenuItem('Mis tarjetas', Icons.credit_card_rounded, () => context.go('/mis-tarjetas')),
                  _MenuItem('Soporte', Icons.headset_mic_rounded, () => context.go('/soporte')),
                ]),
                const SizedBox(height: 16),

                // ── Sección Datos personales ──
                _sectionHeader('Datos personales'),
                const SizedBox(height: 10),
                _infoCard([
                  _InfoRow(Icons.person_rounded, 'Usuario', username),
                  _InfoRow(Icons.email_rounded, 'Correo', email.isNotEmpty ? email : 'No registrado'),
                ]),
                const SizedBox(height: 16),

                // ── Cerrar sesión ──
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AlpesColors.rojoColonial.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AlpesColors.rojoColonial.withOpacity(0.15)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AlpesColors.rojoColonial.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout_rounded, color: AlpesColors.rojoColonial, size: 18),
                    ),
                    title: const Text('Cerrar sesión',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: AlpesColors.rojoColonial)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AlpesColors.rojoColonial),
                    onTap: () async {
                      await auth.logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Versión
                Text('Muebles de los Alpes v1.0',
                  style: TextStyle(fontSize: 11, color: AlpesColors.arenaCalida.withOpacity(0.7))),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, BuildContext ctx) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Icon(icon, size: 20, color: AlpesColors.oroGuatemalteco),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
          color: AlpesColors.cafeOscuro)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AlpesColors.nogalMedio)),
      ]),
    ));
  }

  Widget _sectionHeader(String title) => Row(children: [
    Container(width: 3, height: 16,
      decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
        borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
      color: AlpesColors.cafeOscuro)),
  ]);

  Widget _menuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: List.generate(items.length, (i) {
        final item = items[i];
        return Column(children: [
          ListTile(
            leading: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AlpesColors.cafeOscuro.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 17, color: AlpesColors.cafeOscuro),
            ),
            title: Text(item.label, style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: AlpesColors.arenaCalida),
            onTap: item.onTap,
          ),
          if (i < items.length - 1)
            const Divider(height: 1, indent: 66, endIndent: 16, color: AlpesColors.pergamino),
        ]);
      })),
    );
  }

  Widget _infoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: List.generate(rows.length, (i) {
        final row = rows[i];
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AlpesColors.cafeOscuro.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(row.icon, size: 17, color: AlpesColors.cafeOscuro),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(row.label, style: const TextStyle(fontSize: 11,
                  color: AlpesColors.nogalMedio, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(row.value, style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro)),
              ]),
            ]),
          ),
          if (i < rows.length - 1)
            const Divider(height: 1, indent: 66, endIndent: 16, color: AlpesColors.pergamino),
        ]);
      })),
    );
  }
}

class _MenuItem { final String label; final IconData icon; final VoidCallback onTap;
  const _MenuItem(this.label, this.icon, this.onTap); }
class _InfoRow { final IconData icon; final String label; final String value;
  const _InfoRow(this.icon, this.label, this.value); }
