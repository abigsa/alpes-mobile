import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _verPassword = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.login(_userCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (result['ok'] == true) {
      if (result['role'] == UserRole.admin) {
        context.go('/admin');
      } else {
        context.go('/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['mensaje'] ?? 'Error al iniciar sesión'),
          backgroundColor: AlpesColors.rojoColonial,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header con logo
              Container(
                width: double.infinity,
                color: AlpesColors.cafeOscuro,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Column(
                  children: [
                    const Icon(Icons.chair_alt, size: 64, color: AlpesColors.oroGuatemalteco),
                    const SizedBox(height: 16),
                    Text(
                      'MUEBLES DE LOS ALPES',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AlpesColors.cremaFondo,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Artesanía · Calidad · Elegancia',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AlpesColors.arenaCalida,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),

              // Formulario
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Iniciar sesión',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa tus credenciales para continuar',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _userCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person_outline, color: AlpesColors.nogalMedio),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Ingresa tu usuario' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passCtrl,
                        obscureText: !_verPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline, color: AlpesColors.nogalMedio),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _verPassword ? Icons.visibility_off : Icons.visibility,
                              color: AlpesColors.nogalMedio,
                            ),
                            onPressed: () => setState(() => _verPassword = !_verPassword),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Ingresa tu contraseña' : null,
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: auth.loading ? null : _login,
                        child: auth.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('INGRESAR'),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes cuenta? ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () => context.go('/registro'),
                            child: const Text('Regístrate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
