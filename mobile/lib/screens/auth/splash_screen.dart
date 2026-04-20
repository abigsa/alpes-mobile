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
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _logoFade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _textFade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 0.9, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic)));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    final auth = context.read<AuthProvider>();
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    if (auth.isLoggedIn) {
      context.go(auth.isAdmin ? '/admin' : '/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3), radius: 1.5,
          colors: [Color(0xFF3D2416), Color(0xFF2C1810), Color(0xFF0A0604)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -100, right: -80,
          child: _circle(280, AlpesColors.oroGuatemalteco.withOpacity(0.06))),
        Positioned(bottom: -80, left: -60,
          child: _circle(220, AlpesColors.oroGuatemalteco.withOpacity(0.04))),
        Positioned(top: 180, left: -30,
          child: _circle(100, AlpesColors.oroGuatemalteco.withOpacity(0.03))),
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(scale: _logoScale,
            child: FadeTransition(opacity: _logoFade,
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8B84B), Color(0xFFD4A853), Color(0xFFB8922A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: AlpesColors.oroGuatemalteco.withOpacity(0.5),
                        blurRadius: 40, offset: const Offset(0, 16)),
                    BoxShadow(color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                        blurRadius: 80, offset: const Offset(0, 30)),
                  ],
                ),
                child: const Icon(Icons.chair_alt_rounded, size: 56, color: AlpesColors.cafeOscuro),
              ),
            ),
          ),
          const SizedBox(height: 36),
          SlideTransition(position: _textSlide,
            child: FadeTransition(opacity: _textFade,
              child: Column(children: [
                const Text('Muebles de los Alpes',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 0.4)),
                const SizedBox(height: 8),
                Text('Elegancia en cada espacio',
                    style: TextStyle(fontSize: 13, color: AlpesColors.oroGuatemalteco.withOpacity(0.85),
                        letterSpacing: 2.0, fontWeight: FontWeight.w400)),
              ]),
            ),
          ),
          const SizedBox(height: 80),
          FadeTransition(opacity: _textFade,
            child: SizedBox(width: 48, height: 2,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(AlpesColors.oroGuatemalteco),
              ),
            ),
          ),
        ])),
      ]),
    ),
  );

  Widget _circle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
