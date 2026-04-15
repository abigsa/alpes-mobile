import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Controladores por etapa ──
  late AnimationController _bgCtrl;       // 1. Fondo aparece
  late AnimationController _logoCtrl;     // 2. Logo entra
  late AnimationController _glowCtrl;     // 3. Halo dorado pulsa
  late AnimationController _textCtrl;     // 4. Texto y subtítulo
  late AnimationController _lineCtrl;     // 5. Línea decorativa
  late AnimationController _exitCtrl;     // 6. Salida elegante

  // Animaciones
  late Animation<double>  _bgFade;
  late Animation<double>  _logoScale;
  late Animation<double>  _logoFade;
  late Animation<double>  _logoY;
  late Animation<double>  _glowRadius;
  late Animation<double>  _glowOpacity;
  late Animation<double>  _textFade;
  late Animation<double>  _textY;
  late Animation<double>  _lineWidth;
  late Animation<double>  _taglineFade;
  late Animation<double>  _exitFade;
  late Animation<double>  _exitScale;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runSequence();
  }

  void _setupAnimations() {
    // Fondo
    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);

    // Logo
    _logoCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _logoScale = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));
    _logoY     = Tween<double>(begin: 40.0, end: 0.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));

    // Glow
    _glowCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _glowRadius  = Tween<double>(begin: 30.0, end: 60.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _glowOpacity = Tween<double>(begin: 0.25, end: 0.55)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Texto nombre
    _textCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _textFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textY    = Tween<double>(begin: 20.0, end: 0.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // Línea separadora
    _lineCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _lineWidth   = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _lineCtrl, curve: Curves.easeOutCubic));
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _lineCtrl, curve: Curves.easeOut));

    // Salida
    _exitCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _exitFade  = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInCubic));
    _exitScale = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
  }

  Future<void> _runSequence() async {
    // 1. Fondo aparece
    await _bgCtrl.forward();

    // 2. Logo entra con elasticidad
    await Future.delayed(const Duration(milliseconds: 100));
    await _logoCtrl.forward();

    // 3. Texto entra
    await Future.delayed(const Duration(milliseconds: 200));
    await _textCtrl.forward();

    // 4. Línea y tagline
    await Future.delayed(const Duration(milliseconds: 100));
    await _lineCtrl.forward();

    // 5. Esperar a que termine de verse
    await Future.delayed(const Duration(milliseconds: 1400));

    // 6. Salida elegante
    _glowCtrl.stop();
    await _exitCtrl.forward();

    // 7. Navegar
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      context.go(auth.isAdmin ? '/admin' : '/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _textCtrl.dispose();
    _lineCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgCtrl, _logoCtrl, _glowCtrl, _textCtrl, _lineCtrl, _exitCtrl
        ]),
        builder: (_, __) {
          return FadeTransition(
            opacity: _exitFade,
            child: ScaleTransition(
              scale: _exitScale,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── FONDO ──────────────────────────────
                  FadeTransition(
                    opacity: _bgFade,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.2),
                          radius: 1.4,
                          colors: [
                            Color(0xFF3D2416),
                            Color(0xFF2C1810),
                            Color(0xFF180C06),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // ── PARTÍCULAS DECORATIVAS ──────────────
                  FadeTransition(
                    opacity: _bgFade,
                    child: Stack(children: [
                      _circle(260, 260, const Offset(-80, -80),
                          AlpesColors.oroGuatemalteco.withOpacity(0.06)),
                      _circle(180, 180, Offset(
                          MediaQuery.of(context).size.width + 40,
                          MediaQuery.of(context).size.height * 0.2),
                          AlpesColors.oroGuatemalteco.withOpacity(0.05)),
                      _circle(120, 120, Offset(
                          MediaQuery.of(context).size.width * 0.15,
                          MediaQuery.of(context).size.height * 0.72),
                          Colors.white.withOpacity(0.03)),
                      _circle(80, 80, Offset(
                          MediaQuery.of(context).size.width * 0.78,
                          MediaQuery.of(context).size.height * 0.8),
                          AlpesColors.oroGuatemalteco.withOpacity(0.07)),
                    ]),
                  ),

                  // ── CONTENIDO CENTRAL ───────────────────
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        // Glow + Logo
                        Transform.translate(
                          offset: Offset(0, _logoY.value),
                          child: Opacity(
                            opacity: _logoFade.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Halo pulsante
                                Container(
                                  width: _glowRadius.value * 2 + 80,
                                  height: _glowRadius.value * 2 + 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AlpesColors.oroGuatemalteco
                                        .withOpacity(_glowOpacity.value * 0.15),
                                  ),
                                ),
                                // Halo medio
                                Container(
                                  width: 110, height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AlpesColors.oroGuatemalteco
                                        .withOpacity(_glowOpacity.value * 0.12),
                                  ),
                                ),
                                // Logo principal
                                Transform.scale(
                                  scale: _logoScale.value,
                                  child: Container(
                                    width: 88, height: 88,
                                    decoration: BoxDecoration(
                                      color: AlpesColors.oroGuatemalteco,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AlpesColors.oroGuatemalteco
                                              .withOpacity(_glowOpacity.value),
                                          blurRadius: _glowRadius.value,
                                          spreadRadius: 2,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.chair_alt_rounded,
                                      size: 44,
                                      color: AlpesColors.cafeOscuro,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Nombre empresa
                        Transform.translate(
                          offset: Offset(0, _textY.value),
                          child: Opacity(
                            opacity: _textFade.value,
                            child: const Text(
                              'MUEBLES DE LOS ALPES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Línea dorada animada
                        Opacity(
                          opacity: _taglineFade.value,
                          child: SizedBox(
                            width: 240,
                            child: Row(
                              children: [
                                // Línea izquierda
                                Expanded(
                                  child: FractionallySizedBox(
                                    widthFactor: _lineWidth.value,
                                    alignment: Alignment.centerRight,
                                    child: Container(height: 1,
                                        color: AlpesColors.oroGuatemalteco.withOpacity(0.5)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Container(
                                    width: 5, height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AlpesColors.oroGuatemalteco,
                                      boxShadow: [BoxShadow(
                                        color: AlpesColors.oroGuatemalteco.withOpacity(0.6),
                                        blurRadius: 6,
                                      )],
                                    ),
                                  ),
                                ),
                                // Línea derecha
                                Expanded(
                                  child: FractionallySizedBox(
                                    widthFactor: _lineWidth.value,
                                    alignment: Alignment.centerLeft,
                                    child: Container(height: 1,
                                        color: AlpesColors.oroGuatemalteco.withOpacity(0.5)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Tagline
                        Opacity(
                          opacity: _taglineFade.value,
                          child: const Text(
                            'Artesanía  ·  Calidad  ·  Elegancia',
                            style: TextStyle(
                              color: AlpesColors.arenaCalida,
                              fontSize: 12,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        const SizedBox(height: 80),

                        // Loading indicator sutil
                        Opacity(
                          opacity: _taglineFade.value,
                          child: SizedBox(
                            width: 40,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AlpesColors.oroGuatemalteco.withOpacity(0.7)),
                              minHeight: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _circle(double w, double h, Offset offset, Color color) =>
      Positioned(
        left: offset.dx,
        top: offset.dy,
        child: Container(
          width: w, height: h,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      );
}
