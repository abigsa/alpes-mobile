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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _verPassword = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth   = context.read<AuthProvider>();
    final result = await auth.login(_userCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (result['ok'] == true) {
      context.go(result['role'] == UserRole.admin ? '/admin' : '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['mensaje'] ?? 'Error al iniciar sesión'),
        backgroundColor: AlpesColors.rojoColonial,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final size   = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          // ── Fondo con gradiente ──────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.45, 1.0],
                colors: [
                  AlpesColors.cafeOscuro,
                  Color(0xFF3D2416),
                  Color(0xFF1E0E08),
                ],
              ),
            ),
          ),

          // ── Círculos decorativos de fondo ────────────────
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AlpesColors.oroGuatemalteco.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -80,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AlpesColors.oroGuatemalteco.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.18, left: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),

          // ── Contenido centrado ───────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 0 : 24,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Logo ──────────────────────────
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: AlpesColors.oroGuatemalteco,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AlpesColors.oroGuatemalteco.withOpacity(0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chair_alt_rounded,
                              size: 36,
                              color: AlpesColors.cafeOscuro,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'MUEBLES DE LOS ALPES',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Artesanía · Calidad · Elegancia',
                            style: TextStyle(
                              color: AlpesColors.arenaCalida,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // ── Card del formulario ───────────
                          Container(
                            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.30),
                                  blurRadius: 40,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 16),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Título del form
                                  Row(children: [
                                    Container(
                                      width: 3, height: 20,
                                      decoration: BoxDecoration(
                                        color: AlpesColors.oroGuatemalteco,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Iniciar sesión',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: AlpesColors.cafeOscuro)),
                                        Text('Ingresa tus credenciales',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AlpesColors.nogalMedio)),
                                      ],
                                    ),
                                  ]),
                                  const SizedBox(height: 28),

                                  // Campo usuario
                                  _buildField(
                                    controller: _userCtrl,
                                    label: 'Usuario',
                                    icon: Icons.person_outline_rounded,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Ingresa tu usuario' : null,
                                  ),
                                  const SizedBox(height: 14),

                                  // Campo contraseña
                                  _buildField(
                                    controller: _passCtrl,
                                    label: 'Contraseña',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: !_verPassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _login(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _verPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AlpesColors.arenaCalida,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                          () => _verPassword = !_verPassword),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Ingresa tu contraseña' : null,
                                  ),
                                  const SizedBox(height: 28),

                                  // Botón ingresar
                                  SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: auth.loading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AlpesColors.cafeOscuro,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        textStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.5),
                                      ),
                                      child: auth.loading
                                          ? const SizedBox(height: 20, width: 20,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white, strokeWidth: 2))
                                          : const Text('INGRESAR'),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Divider
                                  Row(children: [
                                    Expanded(child: Divider(color: AlpesColors.pergamino.withOpacity(0.8))),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('o',
                                          style: TextStyle(fontSize: 12, color: AlpesColors.arenaCalida)),
                                    ),
                                    Expanded(child: Divider(color: AlpesColors.pergamino.withOpacity(0.8))),
                                  ]),
                                  const SizedBox(height: 16),

                                  // Registro
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('¿No tienes cuenta?',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: AlpesColors.nogalMedio)),
                                      TextButton(
                                        onPressed: () => context.go('/registro'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AlpesColors.cafeOscuro,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                        ),
                                        child: const Text('Regístrate',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Footer ────────────────────────
                          const SizedBox(height: 32),
                          Text(
                            '© ${DateTime.now().year} Muebles de los Alpes',
                            style: const TextStyle(
                              color: AlpesColors.arenaCalida,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
          fontSize: 14, color: AlpesColors.cafeOscuro, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: AlpesColors.arenaCalida, fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(icon, color: AlpesColors.nogalMedio, size: 19),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AlpesColors.cremaFondo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AlpesColors.pergamino),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AlpesColors.pergamino),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AlpesColors.cafeOscuro, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AlpesColors.rojoColonial),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AlpesColors.rojoColonial, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
