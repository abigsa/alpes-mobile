import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('PANEL ADMINISTRATIVO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, auth),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AlpesColors.cafeOscuro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AlpesColors.oroGuatemalteco,
                    child: Icon(Icons.admin_panel_settings, color: AlpesColors.cafeOscuro),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${auth.usuario?['USERNAME'] ?? auth.usuario?['username'] ?? 'Administrador'}',
                        style: const TextStyle(color: AlpesColors.cremaFondo, fontWeight: FontWeight.w600),
                      ),
                      const Text('Panel de administración',
                          style: TextStyle(color: AlpesColors.arenaCalida, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Gestión comercial', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _grid(context, [
              _mod('Productos', Icons.inventory_2_outlined, '/admin/productos'),
              _mod('Inventario', Icons.warehouse_outlined, '/admin/inventario'),
              _mod('Órdenes', Icons.receipt_long_outlined, '/admin/ordenes'),
              _mod('Clientes', Icons.people_outline, '/admin/clientes'),
              _mod('Marketing', Icons.campaign_outlined, '/admin/marketing'),
              _mod('Reportes', Icons.bar_chart, '/admin/reportes'),
            ]),
            const SizedBox(height: 24),
            Text('Gestión operativa', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _grid(context, [
              _mod('Empleados', Icons.badge_outlined, '/admin/empleados'),
              _mod('Nómina', Icons.payments_outlined, '/admin/nomina'),
              _mod('Proveedores', Icons.local_shipping_outlined, '/admin/proveedores'),
              _mod('Compras', Icons.shopping_bag_outlined, '/admin/compras'),
              _mod('Producción', Icons.factory_outlined, '/admin/produccion'),
              _mod('Configuración', Icons.settings_outlined, '/admin/configuracion'),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _mod(String label, IconData icon, String route) =>
      {'label': label, 'icon': icon, 'route': route};

  Widget _grid(BuildContext context, List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => context.go(items[i]['route'] as String),
        child: Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(items[i]['icon'] as IconData, color: AlpesColors.cafeOscuro, size: 28),
              const SizedBox(height: 6),
              Text(items[i]['label'] as String,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AlpesColors.cafeOscuro),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.chair_alt, size: 40, color: AlpesColors.oroGuatemalteco),
                const SizedBox(height: 8),
                const Text('Muebles de los Alpes',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                Text('${auth.usuario?['USERNAME'] ?? auth.usuario?['username'] ?? ''}',
                    style: const TextStyle(color: AlpesColors.arenaCalida, fontSize: 13)),
              ],
            ),
          ),
          _item(context, Icons.inventory_2_outlined, 'Productos', '/admin/productos'),
          _item(context, Icons.warehouse_outlined, 'Inventario', '/admin/inventario'),
          _item(context, Icons.receipt_long_outlined, 'Órdenes de venta', '/admin/ordenes'),
          _item(context, Icons.people_outline, 'Clientes', '/admin/clientes'),
          _item(context, Icons.badge_outlined, 'Empleados', '/admin/empleados'),
          _item(context, Icons.payments_outlined, 'Nómina', '/admin/nomina'),
          _item(context, Icons.local_shipping_outlined, 'Proveedores', '/admin/proveedores'),
          _item(context, Icons.shopping_bag_outlined, 'Órdenes de compra', '/admin/compras'),
          _item(context, Icons.factory_outlined, 'Producción', '/admin/produccion'),
          _item(context, Icons.campaign_outlined, 'Marketing', '/admin/marketing'),
          _item(context, Icons.bar_chart, 'Reportes', '/admin/reportes'),
          _item(context, Icons.settings_outlined, 'Configuración', '/admin/configuracion'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AlpesColors.rojoColonial),
            title: const Text('Cerrar sesión', style: TextStyle(color: AlpesColors.rojoColonial)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: AlpesColors.cafeOscuro),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AlpesColors.arenaCalida),
      onTap: () { Navigator.pop(context); context.go(route); },
    );
  }
}
