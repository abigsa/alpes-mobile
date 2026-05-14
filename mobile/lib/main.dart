import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/carrito_provider.dart';
import 'providers/producto_provider.dart';
import 'providers/favoritos_provider.dart';
import 'providers/cupon_provider.dart';
import 'router/app_router.dart';
import 'utils/http_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlpesApp());
}

class AlpesApp extends StatelessWidget {
  const AlpesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProxyProvider<AuthProvider, ProductoProvider>(
          create: (_) => ProductoProvider(),
          update: (_, auth, producto) {
            // ✅ Actualiza token global y en cada provider
            ApiClient.setToken(auth.token);
            producto!.setToken(auth.token);
            return producto;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, CarritoProvider>(
          create: (_) => CarritoProvider(),
          update: (_, auth, carrito) {
            carrito!.setToken(auth.token);
            return carrito;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, FavoritosProvider>(
          create: (_) => FavoritosProvider(),
          update: (_, auth, favoritos) {
            favoritos!.setToken(auth.token);
            return favoritos;
          },
        ),

        ChangeNotifierProvider(create: (_) => CuponProvider()),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.createRouter(context);
          return MaterialApp.router(
            title: 'Muebles de los Alpes',
            debugShowCheckedModeBanner: false,
            theme: AlpesTheme.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
