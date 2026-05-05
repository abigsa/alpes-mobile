import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../config/theme.dart';
import '../../config/api_config.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  HOME PÚBLICA — Premium · Poppins · Paleta Alpes
//  Ruta: /home-publica
// ═══════════════════════════════════════════════════════════════════════════

class HomePublicaScreen extends StatefulWidget {
  const HomePublicaScreen({super.key});
  @override
  State<HomePublicaScreen> createState() => _HomePublicaScreenState();
}

class _HomePublicaScreenState extends State<HomePublicaScreen>
    with TickerProviderStateMixin {
  // ── Animaciones ──
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Estado ──
  bool _loadingProductos = true;
  List<Map<String, dynamic>> _productos = [];
  int _bannerIndex = 0;
  final PageController _bannerCtrl = PageController();

  // ── Banners — tipo explícito para evitar error de inferencia ──
  final List<Map<String, dynamic>> _banners = [
    {
      'tag': 'COLECCIÓN 2025',
      'titulo': 'Amamos el\n"Vénganse\na la casa"',
      'desc': 'Diseño para que ames tus espacios',
      'bg': AlpesColors.cafeOscuro,
      'acc': AlpesColors.oroGuatemalteco,
      'icon': Icons.weekend_rounded,
    },
    {
      'tag': 'ENVÍO GRATUITO',
      'titulo': 'A toda\nGuatemala\nsin costo',
      'desc': 'Entregamos en cualquier departamento',
      'bg': AlpesColors.verdeSelva,
      'acc': AlpesColors.arenaCalida,
      'icon': Icons.local_shipping_rounded,
    },
    {
      'tag': 'TENDENCIAS 2025',
      'titulo': 'Tu hogar,\ntu mayor\norgullo',
      'desc': 'Muebles que inspiran cada día',
      'bg': AlpesColors.nogalMedio,
      'acc': AlpesColors.cremaFondo,
      'icon': Icons.auto_awesome_rounded,
    },
  ];

  // ── Categorías — tipo explícito ──
  final List<Map<String, dynamic>> _cats = [
    {'l': 'Salas', 'i': Icons.weekend_rounded, 'c': AlpesColors.cafeOscuro},
    {
      'l': 'Comedores',
      'i': Icons.table_restaurant_rounded,
      'c': AlpesColors.verdeSelva
    },
    {'l': 'Dormitorios', 'i': Icons.bed_rounded, 'c': AlpesColors.nogalMedio},
    {
      'l': 'Oficinas',
      'i': Icons.chair_rounded,
      'c': AlpesColors.oroGuatemalteco
    },
    {'l': 'Terrazas', 'i': Icons.deck_rounded, 'c': AlpesColors.grafito},
    {
      'l': 'Accesorios',
      'i': Icons.light_rounded,
      'c': AlpesColors.rojoColonial
    },
  ];

  // ── Tendencias — tipo explícito ──
  final List<Map<String, dynamic>> _tendencias = [
    {
      'titulo': 'Minimalismo Cálido',
      'sub': 'Espacios serenos con toques naturales',
      'bg': AlpesColors.cafeOscuro,
    },
    {
      'titulo': 'Ecléctico Chic',
      'sub': 'Fusión de estilos con carácter',
      'bg': AlpesColors.nogalMedio,
    },
    {
      'titulo': 'Estilo Colonial',
      'sub': 'Herencia guatemalteca en cada pieza',
      'bg': AlpesColors.verdeSelva,
    },
  ];

  // ── Beneficios — tipo explícito ──
  final List<Map<String, dynamic>> _beneficios = [
    {
      'icon': Icons.local_shipping_outlined,
      'titulo': 'Envío Gratis',
      'sub': 'A toda Guatemala'
    },
    {
      'icon': Icons.workspace_premium_outlined,
      'titulo': 'Soporte Total',
      'sub': 'De por vida'
    },
    {
      'icon': Icons.swap_horiz_rounded,
      'titulo': 'Trueque',
      'sub': 'Renueva tu mueble'
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargarProductos();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}'))
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final lista = List<Map<String, dynamic>>.from(data['data']);
        if (mounted) {
          setState(() {
            _productos = lista.take(8).toList();
            _loadingProductos = false;
          });
          _fadeCtrl.forward();
        }
      } else {
        if (mounted) setState(() => _loadingProductos = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingProductos = false);
        _fadeCtrl.forward();
      }
    }
  }

  void _acceso(BuildContext ctx) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ModalAcceso(
        onLogin: () {
          Navigator.pop(ctx);
          ctx.go('/login');
        },
        onRegistro: () {
          Navigator.pop(ctx);
          ctx.go('/registro');
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AlpesColors.cremaFondo,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _nav(context)),
                SliverToBoxAdapter(child: _hero(context)),
                SliverToBoxAdapter(child: _categorias(context)),
                SliverToBoxAdapter(child: _productosDestacados(context)),
                SliverToBoxAdapter(child: _inspira(context)),
                SliverToBoxAdapter(child: _beneficiosBanner()),
                SliverToBoxAdapter(child: _cta(context)),
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 24),
                ),
              ],
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              right: 18,
              child: _BotBtn(onAcceso: () => _acceso(context)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  NAV — estilo Kalea: blanco con logo + buscador + iconos
  // ══════════════════════════════════════════════════════════════════════════
  Widget _nav(BuildContext ctx) {
    final top = MediaQuery.of(ctx).padding.top;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Barra superior blanca — compacta ──
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(14, top + 8, 14, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hamburguesa
              GestureDetector(
                onTap: () => _acceso(ctx),
                child: const Icon(Icons.menu_rounded,
                    color: AlpesColors.cafeOscuro, size: 20),
              ),
              const SizedBox(width: 8),
              // Logo
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Muebles de los Alpes',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AlpesColors.cafeOscuro,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2)),
                  Text('es hoy',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AlpesColors.oroGuatemalteco,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0)),
                ],
              ),
              const Spacer(),
              // Buscar
              GestureDetector(
                onTap: () => _acceso(ctx),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Icon(Icons.search_rounded,
                      color: AlpesColors.cafeOscuro, size: 20),
                ),
              ),
              // Cuenta
              GestureDetector(
                onTap: () => _acceso(ctx),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Icon(Icons.person_outline_rounded,
                      color: AlpesColors.cafeOscuro, size: 20),
                ),
              ),
            ],
          ),
        ),
        // Divisor sutil
        Container(height: 0.5, color: AlpesColors.pergamino),
        // ── Barra de categorías horizontal ──
        Container(
          color: Colors.white,
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              'Salas',
              'Comedores',
              'Dormitorios',
              'Oficinas',
              'Terrazas',
              'Accesorios',
              'Ofertas',
            ].asMap().entries.map((e) {
              final isOfertas = e.value == 'Ofertas';
              return GestureDetector(
                onTap: () => _acceso(ctx),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            isOfertas ? Colors.transparent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isOfertas
                            ? AlpesColors.rojoColonial
                            : AlpesColors.grafito),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Divisor inferior
        Container(height: 0.5, color: AlpesColors.pergamino),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HERO — imagen de fondo full-width con texto encima, estilo Kalea
  // ══════════════════════════════════════════════════════════════════════════
  Widget _hero(BuildContext ctx) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          // PageView como fondo
          PageView.builder(
            controller: _bannerCtrl,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemCount: _banners.length,
            itemBuilder: (_, i) {
              final bg = _banners[i]['bg'] as Color;
              final acc = _banners[i]['acc'] as Color;
              // Fondo: gradiente de color + patrón sutil
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      bg,
                      bg.withOpacity(0.85),
                      bg.withOpacity(0.4),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Row(
                  children: [
                    // Contenido izquierdo
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 28, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Eyebrow
                            Text(
                              _banners[i]['tag'] as String,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: acc,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6),
                            ),
                            const SizedBox(height: 8),
                            // Título grande
                            Text(
                              _banners[i]['titulo'] as String,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 10),
                            // Badge descripción
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: acc,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                _banners[i]['desc'] as String,
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: bg,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Botón CTA
                            GestureDetector(
                              onTap: () => _acceso(ctx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 9),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Explorar ahora',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: bg,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 5),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 13, color: bg),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Ícono decorativo derecha
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Icon(
                          _banners[i]['icon'] as IconData,
                          size: 110,
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Indicadores + flechas encima
          Positioned(
            bottom: 12,
            left: 20,
            right: 20,
            child: Row(
              children: [
                // Dots
                Row(
                  children: List.generate(_banners.length, (i) {
                    final active = _bannerIndex == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(right: 5),
                      width: active ? 20 : 5,
                      height: 3,
                      decoration: BoxDecoration(
                        color: active
                            ? AlpesColors.oroGuatemalteco
                            : Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                // Flechas
                _arrowBtn(Icons.arrow_back_rounded, filled: false, onTap: () {
                  if (_bannerIndex > 0)
                    _bannerCtrl.previousPage(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeInOut);
                }),
                const SizedBox(width: 8),
                _arrowBtn(Icons.arrow_forward_rounded, filled: true, onTap: () {
                  if (_bannerIndex < _banners.length - 1)
                    _bannerCtrl.nextPage(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeInOut);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrowBtn(IconData icon,
      {required bool filled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: filled
              ? AlpesColors.oroGuatemalteco
              : Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon,
            size: 14, color: filled ? AlpesColors.cafeOscuro : Colors.white),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CATEGORÍAS — grid con imagen de fondo estilo Kalea
  // ══════════════════════════════════════════════════════════════════════════
  Widget _categorias(BuildContext ctx) {
    // Colores de fondo por categoría (simulan imagen)
    final List<Map<String, dynamic>> cats = [
      {
        'l': 'Salas',
        'i': Icons.weekend_rounded,
        'color': const Color(0xFF3A3A4A)
      },
      {
        'l': 'Comedores',
        'i': Icons.table_restaurant_rounded,
        'color': const Color(0xFF7B6B52)
      },
      {
        'l': 'Oficinas',
        'i': Icons.chair_rounded,
        'color': const Color(0xFF4A5568)
      },
      {
        'l': 'Dormitorios',
        'i': Icons.bed_rounded,
        'color': const Color(0xFF6B5B4E)
      },
      {
        'l': 'Terrazas',
        'i': Icons.deck_rounded,
        'color': const Color(0xFF4A6741)
      },
      {
        'l': 'Accesorios',
        'i': Icons.light_rounded,
        'color': const Color(0xFF8B7355)
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Categorías',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w300,
                color: AlpesColors.nogalMedio,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          // Fila 1: 3 categorías
          Row(
            children: cats.take(3).map((c) => _catCard(ctx, c)).toList(),
          ),
          // Fila 2: 3 categorías
          Row(
            children: cats.skip(3).map((c) => _catCard(ctx, c)).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _catCard(BuildContext ctx, Map<String, dynamic> c) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _acceso(ctx),
        child: Container(
          height: 140,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: c['color'] as Color,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gradiente oscuro abajo
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
              // Ícono decorativo fondo
              Positioned(
                top: 16,
                right: 12,
                child: Icon(c['i'] as IconData,
                    size: 40, color: Colors.white.withOpacity(0.12)),
              ),
              // Texto abajo
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c['l'] as String,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.white.withOpacity(0.7), width: 0.8),
                        ),
                        child: const Text(
                          '+ VER TODOS',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5),
                        ),
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

  // ══════════════════════════════════════════════════════════════════════════
  //  PRODUCTOS DESTACADOS — estilo Kalea: título centrado + cards con carrito
  // ══════════════════════════════════════════════════════════════════════════
  Widget _productosDestacados(BuildContext ctx) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 28),
      child: Column(
        children: [
          // Título centrado grande estilo Kalea
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Productos destacados',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: AlpesColors.nogalMedio,
                  letterSpacing: -0.3),
            ),
          ),
          const SizedBox(height: 20),
          if (_loadingProductos)
            const SizedBox(
              height: 240,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: AlpesColors.cafeOscuro),
                ),
              ),
            )
          else if (_productos.isEmpty)
            const SizedBox(
              height: 80,
              child: Center(
                child: Text('Sin productos disponibles',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AlpesColors.arenaCalida,
                        fontSize: 13)),
              ),
            )
          else
            FadeTransition(
              opacity: _fadeAnim,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _productos.length,
                      itemBuilder: (_, i) {
                        final p = _productos[i];
                        final nombre =
                            (p['NOMBRE'] ?? p['nombre'] ?? 'Producto')
                                .toString();
                        final precio = double.tryParse(
                                '${p['PRECIO'] ?? p['precio'] ?? 0}') ??
                            0;
                        final imgUrl = p['IMAGEN_URL'] ?? p['imagen_url'];

                        return GestureDetector(
                          onTap: () => _acceso(ctx),
                          child: Container(
                            width: 175,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: AlpesColors.pergamino, width: 0.8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen grande
                                Expanded(
                                  child: Container(
                                    color: AlpesColors.cremaFondo,
                                    child: imgUrl != null
                                        ? Image.network(imgUrl as String,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                            errorBuilder: (_, __, ___) =>
                                                const _ImgPlaceholder())
                                        : const _ImgPlaceholder(),
                                  ),
                                ),
                                // Info inferior — divisor + carrito
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 8, 8, 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(nombre,
                                                style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w400,
                                                    color: AlpesColors.grafito),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text(
                                              precio > 0
                                                  ? 'Q ${precio.toStringAsFixed(0)}'
                                                  : '—',
                                              style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      AlpesColors.cafeOscuro),
                                            ),
                                            if (precio > 0)
                                              Text(
                                                '12 cuotas de Q ${(precio / 12).toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 9,
                                                    color: AlpesColors
                                                        .rojoColonial,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Divisor vertical
                                      Container(
                                        width: 0.8,
                                        height: 40,
                                        color: AlpesColors.pergamino,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                      ),
                                      // Ícono carrito estilo Kalea
                                      GestureDetector(
                                        onTap: () => _acceso(ctx),
                                        child: const Icon(
                                          Icons.shopping_cart_outlined,
                                          color: AlpesColors.cafeOscuro,
                                          size: 22,
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
                  ),
                  // Flecha izquierda
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: AlpesColors.cafeOscuro, size: 20),
                    ),
                  ),
                  // Flecha derecha
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AlpesColors.cafeOscuro,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: AlpesColors.oroGuatemalteco, size: 20),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TENDENCIAS — banner editorial estilo Kalea
  // ══════════════════════════════════════════════════════════════════════════
  Widget _inspira(BuildContext ctx) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Título
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 4),
            child: Column(
              children: [
                Text(
                  'Diseño y tendencias',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: AlpesColors.nogalMedio,
                      letterSpacing: -0.3),
                ),
                Text(
                  'a tu alcance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: AlpesColors.nogalMedio,
                      letterSpacing: -0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Cards de tendencias — row fijo 3 columnas, sin corte de texto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_tendencias.length, (i) {
                final t = _tendencias[i];
                final bg = t['bg'] as Color;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _acceso(ctx),
                    child: Container(
                      height: 220,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(color: bg),
                          // Ícono decorativo centrado
                          Center(
                            child: Icon(
                              _cats[i % _cats.length]['i'] as IconData,
                              size: 56,
                              color: Colors.white.withOpacity(0.14),
                            ),
                          ),
                          // Contenido con padding
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '-nueva tendencia-',
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 7,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.4),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  t['titulo'] as String,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.6),
                                        width: 0.8),
                                  ),
                                  child: const Text(
                                    '+ COLECCIÓN',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontSize: 7,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Label inferior
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 5, 10, 7),
                              color: Colors.black.withOpacity(0.28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Tendencia',
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.white54,
                                          fontSize: 8)),
                                  Text(
                                    t['titulo'] as String,
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600),
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
              }),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FOOTER NEWSLETTER — estilo Kalea
  // ══════════════════════════════════════════════════════════════════════════
  Widget _beneficiosBanner() {
    return Container(
      color: AlpesColors.cremaFondo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Beneficios rápidos ──
          Container(
            color: AlpesColors.pergamino.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                _beneficioItem(Icons.local_shipping_outlined, 'Envío gratis',
                    'A toda Guatemala'),
                _vDivider(),
                _beneficioItem(Icons.workspace_premium_outlined,
                    'Soporte total', 'De por vida'),
                _vDivider(),
                _beneficioItem(
                    Icons.swap_horiz_rounded, 'Trueque', 'Renueva tu mueble'),
              ],
            ),
          ),
          // ── Newsletter ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(children: [
                  const Text('Muebles de los Alpes',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AlpesColors.cafeOscuro)),
                  const SizedBox(width: 5),
                  const Text('es hoy',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          color: AlpesColors.oroGuatemalteco,
                          fontWeight: FontWeight.w500)),
                ]),
                Container(
                  width: 36,
                  height: 1.5,
                  margin: const EdgeInsets.only(top: 5, bottom: 18),
                  color: AlpesColors.oroGuatemalteco,
                ),
                const Text('Suscríbete al',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: AlpesColors.cafeOscuro)),
                const Text('Newsletter',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AlpesColors.cafeOscuro,
                        letterSpacing: -0.5,
                        height: 1.15)),
                const SizedBox(height: 6),
                const Text(
                  'Sé el primero en enterarte de lo nuevo en tendencia, descuentos y lanzamientos.',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AlpesColors.nogalMedio,
                      height: 1.5),
                ),
                const SizedBox(height: 16),
                // Email field
                Row(children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: AlpesColors.arenaCalida, width: 0.8)),
                      ),
                      child: const TextField(
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AlpesColors.cafeOscuro),
                        decoration: InputDecoration(
                          hintText: 'Correo electrónico',
                          hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              color: AlpesColors.arenaCalida,
                              fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 8),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AlpesColors.cafeOscuro,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward,
                        color: AlpesColors.oroGuatemalteco, size: 16),
                  ),
                ]),
                const SizedBox(height: 24),
                Container(height: 0.5, color: AlpesColors.pergamino),
                const SizedBox(height: 18),
                // Contacto
                _contactRow(Icons.phone_outlined, 'Teléfono: (502) 2490-0000'),
                const SizedBox(height: 6),
                _contactRow(
                    Icons.email_outlined, 'ventas@mueblesdelosalpes.com.gt'),
                const SizedBox(height: 6),
                _contactRow(Icons.location_on_outlined,
                    'Muebles de los Alpes, Guatemala'),
                const SizedBox(height: 18),
                // Redes sociales
                Row(children: [
                  _socialIcon(Icons.facebook_rounded),
                  const SizedBox(width: 10),
                  _socialIcon(Icons.camera_alt_outlined),
                  const SizedBox(width: 10),
                  _socialIcon(Icons.play_circle_outline_rounded),
                  const SizedBox(width: 10),
                  _socialIcon(Icons.push_pin_outlined),
                ]),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _beneficioItem(IconData icon, String titulo, String sub) => Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AlpesColors.cafeOscuro, size: 18),
          const SizedBox(height: 4),
          Text(titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AlpesColors.cafeOscuro)),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  color: AlpesColors.nogalMedio)),
        ]),
      );

  Widget _vDivider() => Container(
        width: 0.5,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: AlpesColors.arenaCalida.withOpacity(0.4),
      );

  Widget _contactRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 13, color: AlpesColors.arenaCalida),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AlpesColors.nogalMedio)),
          ),
        ],
      );

  Widget _socialIcon(IconData icon) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(
              color: AlpesColors.arenaCalida.withOpacity(0.4), width: 0.8),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Icon(icon, size: 15, color: AlpesColors.cafeOscuro),
      );

  // ══════════════════════════════════════════════════════════════════════════
  //  CTA FINAL — botones acceso
  // ══════════════════════════════════════════════════════════════════════════
  Widget _cta(BuildContext ctx) {
    return Container(
      color: AlpesColors.cafeOscuro,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      child: Column(
        children: [
          const Text(
            '¿Listo para transformar tu hogar?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            'Crea tu cuenta y accede a precios especiales y cuotas.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.white.withOpacity(0.55),
                height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => ctx.go('/registro'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AlpesColors.oroGuatemalteco,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Crear cuenta gratis',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AlpesColors.cafeOscuro,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => ctx.go('/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25), width: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ya tengo cuenta — Iniciar sesión',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AlpesColors.cafeOscuro,
            letterSpacing: -0.2),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  PLACEHOLDER IMAGEN
// ═══════════════════════════════════════════════════════════════════════════
class _ImgPlaceholder extends StatelessWidget {
  const _ImgPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
        color: AlpesColors.cremaFondo,
        child: Center(
          child: Icon(
            Icons.chair_outlined,
            size: 34,
            color: AlpesColors.arenaCalida.withOpacity(0.4),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  MODAL ACCESO
// ═══════════════════════════════════════════════════════════════════════════
class _ModalAcceso extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegistro;
  const _ModalAcceso({required this.onLogin, required this.onRegistro});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                  color: AlpesColors.pergamino,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AlpesColors.cafeOscuro,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.chair_alt_rounded,
                    color: AlpesColors.oroGuatemalteco, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Muebles de los Alpes',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AlpesColors.cafeOscuro),
                  ),
                  Text(
                    'Bienvenido de vuelta',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AlpesColors.nogalMedio),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Iniciar sesión
          GestureDetector(
            onTap: onLogin,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              decoration: BoxDecoration(
                  color: AlpesColors.cafeOscuro,
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Iniciar sesión',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ya tengo una cuenta',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white38,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AlpesColors.oroGuatemalteco),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Crear cuenta
          GestureDetector(
            onTap: onRegistro,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              decoration: BoxDecoration(
                  color: AlpesColors.oroGuatemalteco,
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crear cuenta gratis',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AlpesColors.cafeOscuro,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sin compromisos',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AlpesColors.cafeOscuro,
                              fontSize: 11,
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AlpesColors.cafeOscuro),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Continuar solo mirando',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AlpesColors.arenaCalida,
                    fontSize: 12,
                    fontWeight: FontWeight.w400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BOT FLOTANTE
// ═══════════════════════════════════════════════════════════════════════════
class _BotBtn extends StatefulWidget {
  final VoidCallback onAcceso;
  const _BotBtn({required this.onAcceso});
  @override
  State<_BotBtn> createState() => _BotBtnState();
}

class _BotBtnState extends State<_BotBtn> with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;
  final _textCtrl = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;

  final List<_Msg> _msgs = [
    const _Msg('¡Hola! 👋 Soy AlpesBot.\n¿En qué te puedo ayudar hoy?', false),
  ];
  final List<String> _quick = [
    '¿Horarios?',
    '¿Dónde están?',
    'Precios',
    '¿Cómo comprar?',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 230));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _textCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  String _reply(String m) {
    final s = m.toLowerCase();
    if (s.contains('horario') || s.contains('hora'))
      return 'Lun–Vie: 8AM–6PM\nSáb: 9AM–5PM\nDom: 10AM–2PM';
    if (s.contains('ubica') || s.contains('donde'))
      return 'Zona 10 y Zona 18 en Ciudad de Guatemala, también en Antigua Guatemala.';
    if (s.contains('precio') || s.contains('costo'))
      return 'Nuestros muebles van desde Q 500. Crea una cuenta para ver precios y cuotas completas.';
    if (s.contains('comprar') || s.contains('pedido'))
      return 'Para realizar compras crea una cuenta gratuita. ¡Es muy rápido!';
    if (s.contains('envio') || s.contains('envío'))
      return 'Envío gratuito a toda Guatemala sin costo adicional.';
    if (s.contains('gracias'))
      return 'Con gusto 😊 Aquí estaré si necesitas algo más.';
    return 'Puedo ayudarte con horarios, ubicaciones, precios o cómo comprar. ¿Qué necesitas?';
  }

  void _send([String? t]) {
    final msg = (t ?? _textCtrl.text).trim();
    if (msg.isEmpty) return;
    setState(() {
      _msgs.add(_Msg(msg, true));
      _textCtrl.clear();
      _typing = true;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _msgs.add(_Msg(_reply(msg), false));
      });
      Future.delayed(const Duration(milliseconds: 80), () {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open)
          ScaleTransition(
            scale: _scale,
            alignment: Alignment.bottomRight,
            child: Container(
              width: 295,
              height: 400,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AlpesColors.pergamino, width: 0.8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    decoration: const BoxDecoration(
                      color: AlpesColors.cafeOscuro,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            color: AlpesColors.oroGuatemalteco,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.support_agent_rounded,
                            color: AlpesColors.cafeOscuro, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AlpesBot',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            Text('En línea',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white38,
                                    fontSize: 9)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggle,
                        child: const Icon(Icons.close,
                            color: Colors.white30, size: 16),
                      ),
                    ]),
                  ),
                  // Mensajes
                  Expanded(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: _msgs.length + (_typing ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (_typing && i == _msgs.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                  color: AlpesColors.cremaFondo,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Text('...',
                                  style: TextStyle(
                                      color: AlpesColors.arenaCalida,
                                      fontSize: 13)),
                            ),
                          );
                        }
                        final m = _msgs[i];
                        return Align(
                          alignment: m.esUsuario
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 7),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            constraints: const BoxConstraints(maxWidth: 210),
                            decoration: BoxDecoration(
                              color: m.esUsuario
                                  ? AlpesColors.cafeOscuro
                                  : AlpesColors.cremaFondo,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(10),
                                topRight: const Radius.circular(10),
                                bottomLeft:
                                    Radius.circular(m.esUsuario ? 10 : 2),
                                bottomRight:
                                    Radius.circular(m.esUsuario ? 2 : 10),
                              ),
                            ),
                            child: Text(
                              m.texto,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  height: 1.4,
                                  color: m.esUsuario
                                      ? Colors.white
                                      : AlpesColors.cafeOscuro),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Quick replies
                  SizedBox(
                    height: 34,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      itemCount: _quick.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _send(_quick[i]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AlpesColors.pergamino, width: 0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_quick[i],
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9,
                                  color: AlpesColors.nogalMedio)),
                        ),
                      ),
                    ),
                  ),
                  // Input
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: AlpesColors.pergamino, width: 0.8)),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _textCtrl,
                          onSubmitted: (_) => _send(),
                          textInputAction: TextInputAction.send,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AlpesColors.cafeOscuro),
                          decoration: InputDecoration(
                            hintText: 'Escribe tu mensaje…',
                            hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                color: AlpesColors.arenaCalida.withOpacity(0.6),
                                fontSize: 12),
                            filled: true,
                            fillColor: AlpesColors.cremaFondo,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      GestureDetector(
                        onTap: _send,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: AlpesColors.cafeOscuro,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.send_rounded,
                              color: AlpesColors.oroGuatemalteco, size: 14),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        // Botón flotante
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _open ? AlpesColors.nogalMedio : AlpesColors.cafeOscuro,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: AlpesColors.cafeOscuro.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(
              _open ? Icons.close_rounded : Icons.chat_bubble_rounded,
              color: AlpesColors.oroGuatemalteco,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _Msg {
  final String texto;
  final bool esUsuario;
  const _Msg(this.texto, this.esUsuario);
}
