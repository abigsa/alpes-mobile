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
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
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
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Stack(children: [
        // ── Fondo ──
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.5,
              colors: [Color(0xFF3D2416), Color(0xFF2C1810), Color(0xFF0F0A06)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // ── Círculos decorativos ──
        Positioned(top: -60, right: -60,
            child: _circle(240, AlpesColors.oroGuatemalteco.withOpacity(0.06))),
        Positioned(bottom: -80, left: -60,
            child: _circle(280, AlpesColors.oroGuatemalteco.withOpacity(0.04))),
        Positioned(top: 160, left: -30,
            child: _circle(120, Colors.white.withOpacity(0.025))),

        // ── Contenido ──
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 0 : 24, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Logo ──
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: AlpesColors.oroGuatemalteco,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                  color: AlpesColors.oroGuatemalteco.withOpacity(0.4),
                                  blurRadius: 32, offset: const Offset(0, 10)),
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 16, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: const Icon(Icons.chair_alt_rounded,
                              size: 40, color: AlpesColors.cafeOscuro),
                        ),
                        const SizedBox(height: 22),

                        const Text('MUEBLES DE LOS ALPES',
                            style: TextStyle(color: Colors.white, fontSize: 17,
                                fontWeight: FontWeight.w800, letterSpacing: 3.0)),
                        const SizedBox(height: 6),

                        // Línea decorativa
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(width: 40, height: 1,
                              color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
                          const SizedBox(width: 8),
                          Container(width: 5, height: 5,
                              decoration: BoxDecoration(
                                  color: AlpesColors.oroGuatemalteco,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(
                                      color: AlpesColors.oroGuatemalteco.withOpacity(0.6),
                                      blurRadius: 6)])),
                          const SizedBox(width: 8),
                          Container(width: 40, height: 1,
                              color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
                        ]),
                        const SizedBox(height: 8),

                        const Text('Artesanía  ·  Calidad  ·  Elegancia',
                            style: TextStyle(color: AlpesColors.arenaCalida,
                                fontSize: 12, letterSpacing: 2.5)),
                        const SizedBox(height: 36),

                        // ── Card formulario ──
                        Container(
                          padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.32),
                                  blurRadius: 48, spreadRadius: 0,
                                  offset: const Offset(0, 18)),
                              BoxShadow(color: Colors.black.withOpacity(0.10),
                                  blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Título
                                Row(children: [
                                  Container(width: 3, height: 20,
                                      decoration: BoxDecoration(
                                          color: AlpesColors.oroGuatemalteco,
                                          borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(width: 10),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Iniciar sesión',
                                          style: TextStyle(fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: AlpesColors.cafeOscuro)),
                                      Text('Ingresa tus credenciales',
                                          style: TextStyle(fontSize: 12,
                                              color: AlpesColors.nogalMedio)),
                                    ],
                                  ),
                                ]),
                                const SizedBox(height: 26),

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
                                      color: AlpesColors.arenaCalida, size: 20),
                                    onPressed: () => setState(
                                        () => _verPassword = !_verPassword),
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Ingresa tu contraseña' : null,
                                ),
                                const SizedBox(height: 26),

                                // Botón ingresar
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: auth.loading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AlpesColors.cafeOscuro,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                      textStyle: const TextStyle(fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2.0),
                                    ),
                                    child: auth.loading
                                        ? const SizedBox(width: 22, height: 22,
                                            child: CircularProgressIndicator(
                                                color: Colors.white, strokeWidth: 2))
                                        : const Text('INGRESAR'),
                                  ),
                                ),
                                const SizedBox(height: 22),

                                Row(children: [
                                  Expanded(child: Divider(
                                      color: AlpesColors.pergamino.withOpacity(0.8))),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('o', style: TextStyle(
                                        fontSize: 12, color: AlpesColors.arenaCalida)),
                                  ),
                                  Expanded(child: Divider(
                                      color: AlpesColors.pergamino.withOpacity(0.8))),
                                ]),
                                const SizedBox(height: 16),

                                Row(mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                  const Text('¿No tienes cuenta?',
                                      style: TextStyle(fontSize: 13,
                                          color: AlpesColors.nogalMedio)),
                                  TextButton(
                                    onPressed: () => context.go('/registro'),
                                    style: TextButton.styleFrom(
                                        foregroundColor: AlpesColors.cafeOscuro,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8)),
                                    child: const Text('Regístrate',
                                        style: TextStyle(fontSize: 13,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                        Text('© ${DateTime.now().year} Muebles de los Alpes',
                            style: const TextStyle(color: AlpesColors.arenaCalida,
                                fontSize: 11, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
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
      style: const TextStyle(fontSize: 14, color: AlpesColors.cafeOscuro,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AlpesColors.arenaCalida, fontSize: 13),
        prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(icon, color: AlpesColors.nogalMedio, size: 19)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AlpesColors.cremaFondo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: AlpesColors.pergamino)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: AlpesColors.pergamino)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: AlpesColors.cafeOscuro, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: AlpesColors.rojoColonial)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: AlpesColors.rojoColonial, width: 1.5)),
      ),
      validator: validator,
    );
  }

  Widget _circle(double size, Color color) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
