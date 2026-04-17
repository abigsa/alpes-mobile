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
    final auth = context.watch<AuthProvider>();
    final nombre = auth.nombreCompleto;
    final email = auth.usuario?['EMAIL'] ?? auth.usuario?['email'] ?? '';
    final username =
        auth.usuario?['USERNAME'] ?? auth.usuario?['username'] ?? '';
    final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar con hero ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AlpesColors.cafeOscuro,
            leading: IconButton(
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 16),
              ),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2C1810), Color(0xFF3D2416)],
                    ),
                  ),
                ),
                Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AlpesColors.oroGuatemalteco
                                .withOpacity(0.08)))),
                Positioned(
                    bottom: -20,
                    left: 40,
                    child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AlpesColors.oroGuatemalteco
                                .withOpacity(0.05)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Row(children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AlpesColors.oroGuatemalteco,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  AlpesColors.oroGuatemalteco.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(initial,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AlpesColors.cafeOscuro)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(nombre,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                        if (email.isNotEmpty)
                          Text(email,
                              style: const TextStyle(
                                  color: AlpesColors.arenaCalida, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AlpesColors.oroGuatemalteco.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AlpesColors.oroGuatemalteco
                                    .withOpacity(0.3)),
                          ),
                          child: Text('@$username',
                              style: const TextStyle(
                                  color: AlpesColors.oroGuatemalteco,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    )),
                  ]),
                ),
              ]),
            ),
            title: const Text('Mi perfil',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Sección principal ──
                    _sectionLabel('Mi cuenta'),
                    const SizedBox(height: 10),
                    _menuCard([
                      _MenuItem(
                          Icons.receipt_long_rounded,
                          'Mis pedidos',
                          'Ver historial de órdenes',
                          () => context.go('/mis-ordenes')),
                      _MenuItem(
                          Icons.favorite_rounded,
                          'Mis favoritos',
                          'Productos guardados',
                          () => context.go('/favoritos')),
                      _MenuItem(
                          Icons.location_on_rounded,
                          'Mis direcciones',
                          'Gestionar direcciones de entrega',
                          () => _mostrarDirecciones(context, auth)),
                    ]),
                    const SizedBox(height: 20),

                    // ── Preferencias ──
                    _sectionLabel('Preferencias'),
                    const SizedBox(height: 10),
                    _menuCard([
                      _MenuItem(
                          Icons.notifications_outlined,
                          'Notificaciones',
                          'Alertas y avisos',
                          () => context.go('/notificaciones')),
                      _MenuItem(Icons.help_outline_rounded, 'Ayuda y soporte',
                          'FAQ y contacto', () => context.go('/soporte')),
                      _MenuItem(Icons.info_outline_rounded, 'Acerca de',
                          'Versión 1.2.0', () {}),
                    ]),
                    const SizedBox(height: 20),

                    // ── Editar perfil ──
                    _sectionLabel('Configuración de cuenta'),
                    const SizedBox(height: 10),
                    _menuCard([
                      _MenuItem(
                          Icons.person_outline_rounded,
                          'Editar perfil',
                          'Nombre, email y contraseña',
                          () => _editarPerfil(context, auth)),
                    ]),
                    const SizedBox(height: 24),

                    // ── Cerrar sesión ──
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout_rounded,
                            color: AlpesColors.rojoColonial),
                        label: const Text('Cerrar sesión',
                            style: TextStyle(
                                color: AlpesColors.rojoColonial,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: AlpesColors.rojoColonial),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          await auth.logout();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ),
                  ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavCliente(currentIndex: 4),
    );
  }

  Widget _sectionLabel(String label) => Row(children: [
        Container(
            width: 3,
            height: 15,
            decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AlpesColors.cafeOscuro)),
      ]);

  Widget _menuCard(List<_MenuItem> items) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AlpesColors.pergamino),
          boxShadow: [
            BoxShadow(
                color: AlpesColors.cafeOscuro.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: List.generate(items.length * 2 - 1, (i) {
            if (i.isOdd)
              return const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AlpesColors.pergamino);
            final item = items[i ~/ 2];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AlpesColors.cafeOscuro.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 18, color: AlpesColors.cafeOscuro),
              ),
              title: Text(item.label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AlpesColors.cafeOscuro)),
              subtitle: Text(item.subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AlpesColors.nogalMedio)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AlpesColors.arenaCalida),
              onTap: item.onTap,
            );
          }),
        ),
      );

  void _editarPerfil(BuildContext context, AuthProvider auth) {
    final nombreCtrl = TextEditingController(
        text: '${auth.usuario?['NOMBRE'] ?? auth.usuario?['nombre'] ?? ''}');
    final apellidoCtrl = TextEditingController(
        text:
            '${auth.usuario?['APELLIDO'] ?? auth.usuario?['apellido'] ?? ''}');
    final emailCtrl = TextEditingController(
        text: '${auth.usuario?['EMAIL'] ?? auth.usuario?['email'] ?? ''}');
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AlpesColors.pergamino,
                      borderRadius: BorderRadius.circular(2))),
              const Text('Editar perfil',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AlpesColors.cafeOscuro)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: nombreCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Nombre'))),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        controller: apellidoCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Apellido'))),
              ]),
              const SizedBox(height: 12),
              TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          setSt(() => guardando = true);
                          await auth.updatePerfil(
                            nombre: nombreCtrl.text.trim(),
                            apellido: apellidoCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AlpesColors.cafeOscuro,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('GUARDAR',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

void _mostrarDirecciones(BuildContext context, AuthProvider auth) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: AlpesColors.pergamino,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mis direcciones',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AlpesColors.cafeOscuro)),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded,
                      size: 16, color: AlpesColors.oroGuatemalteco),
                  label: const Text('Agregar',
                      style: TextStyle(
                          color: AlpesColors.oroGuatemalteco,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Función de agregar dirección próximamente'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                ),
              ],
            ),
          ),
          const Divider(color: AlpesColors.pergamino, height: 1),
          Expanded(
            child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                          color: AlpesColors.pergamino,
                          borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.location_off_rounded,
                          size: 36, color: AlpesColors.arenaCalida),
                    ),
                    const SizedBox(height: 14),
                    const Text('Sin direcciones guardadas',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AlpesColors.cafeOscuro)),
                    const SizedBox(height: 6),
                    const Text('Presiona "Agregar" para añadir una',
                        style: TextStyle(
                            fontSize: 12, color: AlpesColors.nogalMedio)),
                  ]),
            ),
          ),
        ]),
      ),
    ),
  );
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.subtitle, this.onTap);
}
