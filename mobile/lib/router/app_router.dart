import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// Screens - Auth
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registro_screen.dart';

// Screens - Cliente
import '../screens/cliente/home_screen.dart';
import '../screens/cliente/catalogo_screen.dart';
import '../screens/cliente/producto_detalle_screen.dart';
import '../screens/cliente/carrito_screen.dart';
import '../screens/cliente/checkout_screen.dart';
import '../screens/cliente/mis_ordenes_screen.dart';
import '../screens/cliente/orden_detalle_screen.dart';
import '../screens/cliente/favoritos_screen.dart';
import '../screens/cliente/perfil_screen.dart';
import '../screens/cliente/busqueda_screen.dart';
import '../screens/cliente/seguimiento_screen.dart';
import '../screens/cliente/mis_tarjetas_screen.dart';
import '../screens/cliente/notificaciones_screen.dart';
import '../screens/cliente/soporte_screen.dart';
import '../screens/cliente/mis_resenas_screen.dart';

// Screens - Admin
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/productos/productos_screen.dart';
import '../screens/admin/productos/producto_form_screen.dart';
import '../screens/admin/inventario/inventario_screen.dart';
import '../screens/admin/ordenes/ordenes_venta_screen.dart';
import '../screens/admin/ordenes/orden_venta_detalle_screen.dart';
import '../screens/admin/clientes/clientes_screen.dart';
import '../screens/admin/empleados/empleados_screen.dart';
import '../screens/admin/empleados/empleado_form_screen.dart';
import '../screens/admin/nomina/nomina_screen.dart';
import '../screens/admin/proveedores/proveedores_screen.dart';
import '../screens/admin/compras/ordenes_compra_screen.dart';
import '../screens/admin/produccion/produccion_screen.dart';
import '../screens/admin/marketing/marketing_screen.dart';
import '../screens/admin/reportes/reportes_screen.dart';
import '../screens/admin/configuracion/configuracion_screen.dart';

class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/registro';

        if (state.matchedLocation == '/splash') return null;
        if (!auth.isLoggedIn && !isLoggingIn) return '/login';
        if (auth.isLoggedIn && isLoggingIn) {
          return auth.isAdmin ? '/admin' : '/home';
        }
        return null;
      },
      routes: [
        // Auth
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/registro', builder: (_, __) => const RegistroScreen()),

        // Cliente
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/catalogo', builder: (_, __) => const CatalogoScreen()),
        GoRoute(
          path: '/producto/:id',
          builder: (_, state) => ProductoDetalleScreen(
            productoId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(path: '/carrito', builder: (_, __) => const CarritoScreen()),
        GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
        GoRoute(
            path: '/mis-ordenes', builder: (_, __) => const MisOrdenesScreen()),
        GoRoute(
            path: '/mis-tarjetas',
            builder: (_, __) => const MisTarjetasScreen()),
        GoRoute(
          path: '/orden/:id',
          builder: (_, state) => OrdenDetalleScreen(
            ordenId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
            path: '/favoritos', builder: (_, __) => const FavoritosScreen()),
        GoRoute(path: '/perfil', builder: (_, __) => const PerfilScreen()),
        GoRoute(path: '/busqueda', builder: (_, __) => const BusquedaScreen()),
        GoRoute(
          path: '/seguimiento/:id',
          builder: (_, state) => SeguimientoScreen(
            envioId: int.parse(state.pathParameters['id']!),
          ),
        ),
        // Nuevas rutas
        GoRoute(
            path: '/notificaciones',
            builder: (_, __) => const NotificacionesScreen()),
        GoRoute(path: '/soporte', builder: (_, __) => const SoporteScreen()),
        GoRoute(
            path: '/mis-resenas', builder: (_, __) => const MisResenasScreen()),

        // Admin
        GoRoute(path: '/admin', builder: (_, __) => const AdminHomeScreen()),
        GoRoute(
            path: '/admin/productos',
            builder: (_, __) => const ProductosScreen()),
        GoRoute(
          path: '/admin/productos/nuevo',
          builder: (_, __) => const ProductoFormScreen(),
        ),
        GoRoute(
          path: '/admin/productos/:id',
          builder: (_, state) => ProductoFormScreen(
            productoId: int.tryParse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
            path: '/admin/inventario',
            builder: (_, __) => const InventarioScreen()),
        GoRoute(
            path: '/admin/ordenes',
            builder: (_, __) => const OrdenesVentaScreen()),
        GoRoute(
          path: '/admin/ordenes/:id',
          builder: (_, state) => OrdenVentaDetalleScreen(
            ordenId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
            path: '/admin/clientes',
            builder: (_, __) => const ClientesScreen()),
        GoRoute(
            path: '/admin/empleados',
            builder: (_, __) => const EmpleadosScreen()),
        GoRoute(
          path: '/admin/empleados/nuevo',
          builder: (_, __) => const EmpleadoFormScreen(),
        ),
        GoRoute(
          path: '/admin/empleados/:id',
          builder: (_, state) => EmpleadoFormScreen(
            empleadoId: int.tryParse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
            path: '/admin/nomina', builder: (_, __) => const NominaScreen()),
        GoRoute(
            path: '/admin/proveedores',
            builder: (_, __) => const ProveedoresScreen()),
        GoRoute(
            path: '/admin/compras',
            builder: (_, __) => const OrdenesCompraScreen()),
        GoRoute(
            path: '/admin/produccion',
            builder: (_, __) => const ProduccionScreen()),
        GoRoute(
            path: '/admin/marketing',
            builder: (_, __) => const MarketingScreen()),
        GoRoute(
            path: '/admin/reportes',
            builder: (_, __) => const ReportesScreen()),
        GoRoute(
            path: '/admin/configuracion',
            builder: (_, __) => const ConfiguracionScreen()),
      ],
    );
  }
}
