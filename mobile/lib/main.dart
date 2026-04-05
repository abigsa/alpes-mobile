import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/carrito_provider.dart';
import 'providers/producto_provider.dart';
import 'providers/favoritos_provider.dart';
import 'router/app_router.dart';

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
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => FavoritosProvider()),
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
