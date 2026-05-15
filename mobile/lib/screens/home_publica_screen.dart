import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../config/theme.dart';
import '../../config/api_config.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  HOME PUBLICA — Muebles de los Alpes
//  Diseño editorial premium. Sin emojis. Paleta institucional.
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
  late AnimationController _entradaCtrl;
  late Animation<double>   _entradaFade;
  late Animation<Offset>   _entradaSlide;
  late AnimationController _heroCtrl;
  late Animation<double>   _heroScale;

  // ── Datos ──
  List<Map<String, dynamic>> _productos = [];
  bool _cargando = true;

  // ── Slider ──
  int _bannerActivo = 0;
  final PageController _pageCtrl = PageController();
  Timer? _autoScrollTimer;

  final List<_HeroSlide> _slides = const [
    _HeroSlide(
      etiqueta: 'COLECCION ARTESANAL 2025',
      titulo:   'Muebles que\ncuentan una\nhistoria',
      subtitulo:'Fabricados a mano con madera guatemalteca seleccionada',
      colorFondo: Color(0xFF1C0F08),
      colorAccento: Color(0xFFD4A853),
    ),
    _HeroSlide(
      etiqueta: 'LINEA COLONIAL',
      titulo:   'Herencia\nque\nse sienta',
      subtitulo:'Diseño colonial con acabados artesanales de alta durabilidad',
      colorFondo: Color(0xFF1A3A2A),
      colorAccento: Color(0xFFC4A882),
    ),
    _HeroSlide(
      etiqueta: 'ENVIO SIN COSTO',
      titulo:   'A toda\nGuatemala\nsin cargo',
      subtitulo:'Entregamos en los 22 departamentos con instalacion incluida',
      colorFondo: Color(0xFF2C1810),
      colorAccento: Color(0xFFD4A853),
    ),
  ];

  final List<_Categoria> _categorias = const [
    _Categoria('Interior',  Icons.weekend_rounded,  Color(0xFF2C1810)),
    _Categoria('Exterior',  Icons.deck_rounded,     Color(0xFF1A3A2A)),
  ];

  @override
  void initState() {
    super.initState();
    _entradaCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _entradaFade = CurvedAnimation(
        parent: _entradaCtrl, curve: Curves.easeOut);
    _entradaSlide = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entradaCtrl, curve: Curves.easeOutCubic));
    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _heroScale = Tween<double>(begin: 1.04, end: 1.0)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));
    _heroCtrl.forward();
    _cargarProductos();
    // Auto-avance del carrusel cada 4 segundos
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final siguiente = (_bannerActivo + 1) % _slides.length;
      _pageCtrl.animateToPage(
        siguiente,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _entradaCtrl.dispose();
    _heroCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productosPublico}'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(() {
          _productos =
              List<Map<String, dynamic>>.from(data['data']).take(12).toList();
          _cargando = false;
        });
        _entradaCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
      _entradaCtrl.forward();
    }
  }

  // ── Helpers de acceso ──
  void _irALogin({String? categoria})    => context.go('/login', extra: categoria);
  void _irARegistro() => context.go('/registro');

  void _mostrarAcceso({String? categoria}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ModalAcceso(
        onLogin:    () => _irALogin(categoria: categoria),
        onRegistro: _irARegistro,
        categoria:  categoria,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AlpesColors.cremaFondo,
        body: Stack(children: [
          CustomScrollView(
            slivers: [
              // ── 1. HEADER ──
              SliverToBoxAdapter(child: _buildHeader(safe)),

              // ── 2. HERO EDITORIAL ──
              SliverToBoxAdapter(child: _buildHero()),

              // ── 3. CATEGORÍAS ──
              SliverToBoxAdapter(child: _buildCategorias()),

              // ── 4. PRODUCTOS DESTACADOS ──
              SliverToBoxAdapter(child: _buildProductosDestacados()),

              // ── 5. FRANJA BENEFICIOS ──
              SliverToBoxAdapter(child: _buildBeneficios()),

              // ── 6. INSPIRACION / EDITORIAL ──
              SliverToBoxAdapter(child: _buildEditorial()),

              // ── 7. CTA FINAL ──
              SliverToBoxAdapter(child: _buildCTA()),

              // ── 8. FOOTER ──
              SliverToBoxAdapter(child: _buildFooter(safe)),
            ],
          ),

          // ── CHAT BOT FLOTANTE ──
          Positioned(
            bottom: safe.bottom + 20,
            right: 18,
            child: _ChatBot(onAcceso: _mostrarAcceso),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HEADER — minimalista tipo editorial
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildHeader(EdgeInsets safe) {
    return Container(
      color: Colors.white,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Barra top
        Container(
          padding: EdgeInsets.fromLTRB(20, safe.top + 12, 16, 12),
          child: Row(children: [
            // Logo
            Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, children: [
              const Text('MUEBLES DE LOS ALPES',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AlpesColors.cafeOscuro,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0)),
              Container(
                  width: 36, height: 1.5,
                  color: AlpesColors.oroGuatemalteco),
            ]),
            const Spacer(),
            const SizedBox(width: 8),
            // Botón acceso
            GestureDetector(
              onTap: _mostrarAcceso,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AlpesColors.cafeOscuro,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Ingresar',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
        // Divisor
        Container(height: 0.5, color: AlpesColors.pergamino),
        // Nav categorías
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              'Interior', 'Exterior', 'Ofertas',
            ].map((c) => _NavChip(
              label: c,
              onTap: c == 'Ofertas'
                  ? () => _mostrarAcceso(categoria: c)
                  : () => context.push('/catalogo-publico', extra: c),
            )).toList(),
          ),
        ),
        Container(height: 0.5, color: AlpesColors.pergamino),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HERO — carrusel editorial de pantalla completa
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildHero() {
    return SizedBox(
      height: 300,
      child: Stack(children: [
        PageView.builder(
          controller: _pageCtrl,
          onPageChanged: (i) => setState(() => _bannerActivo = i),
          itemCount: _slides.length,
          itemBuilder: (_, i) {
            final s = _slides[i];
            return Container(
              decoration: BoxDecoration(
                color: s.colorFondo,
              ),
              child: Stack(fit: StackFit.expand, children: [
                // Patrón de fondo
                Positioned(
                  top: -40, right: -40,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.colorAccento.withOpacity(0.06),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30, left: -20,
                  child: Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.colorAccento.withOpacity(0.04),
                    ),
                  ),
                ),
                // Contenido
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Etiqueta
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: s.colorAccento.withOpacity(0.6),
                              width: 0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(s.etiqueta,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                color: s.colorAccento,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8)),
                      ),
                      const SizedBox(height: 10),
                      // Titulo grande
                      Text(s.titulo,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -0.8)),
                      const SizedBox(height: 8),
                      // Subtitulo
                      Text(s.subtitulo,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 11,
                              height: 1.5),
                          maxLines: 2),
                      const SizedBox(height: 16),
                      // CTA
                      GestureDetector(
                        onTap: _mostrarAcceso,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: s.colorAccento,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min,
                              children: [
                            Text('Explorar coleccion',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: s.colorFondo,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded,
                                size: 13, color: s.colorFondo),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            );
          },
        ),
        // Indicadores
        Positioned(
          bottom: 14, left: 28,
          child: Row(
            children: List.generate(_slides.length, (i) {
              final act = _bannerActivo == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 5),
                width: act ? 22 : 5,
                height: 3,
                decoration: BoxDecoration(
                  color: act
                      ? AlpesColors.oroGuatemalteco
                      : Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CATEGORIAS — grid tipo editorial
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCategorias() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Titulo editorial
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            Text('Por categoria',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AlpesColors.arenaCalida,
                    letterSpacing: 2.0)),
            SizedBox(height: 4),
            Text('Encuentra tu estilo',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w300,
                    color: AlpesColors.cafeOscuro,
                    letterSpacing: -0.5)),
          ]),
        ),
        const SizedBox(height: 24),
        // Dos cards grandes lado a lado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _categorias.map((c) => _buildCatCard(c)).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildCatCard(_Categoria c) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push('/catalogo-publico', extra: c.nombre),
        child: Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: c.color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(fit: StackFit.expand, children: [
            // Gradiente de abajo hacia arriba
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
            // Icono grande de fondo decorativo
            Positioned(
              top: 16, right: 12,
              child: Icon(c.icono, size: 64,
                  color: Colors.white.withOpacity(0.07)),
            ),
            // Línea decorativa superior
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                  color: AlpesColors.oroGuatemalteco.withOpacity(0.6),
                ),
              ),
            ),
            // Contenido inferior
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.nombre,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AlpesColors.oroGuatemalteco,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('VER TODOS',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF1C0F08),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0)),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PRODUCTOS DESTACADOS — cards con imagen real desde BD/Cloudinary
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildProductosDestacados() {
    return FadeTransition(
      opacity: _entradaFade,
      child: SlideTransition(
        position: _entradaSlide,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(0, 32, 0, 32),
          child: Column(children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seleccion especial',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AlpesColors.arenaCalida,
                                letterSpacing: 2.0)),
                        SizedBox(height: 4),
                        Text('Productos destacados',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                                color: AlpesColors.cafeOscuro,
                                letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _mostrarAcceso,
                    child: const Text('Ver catalogo completo',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AlpesColors.oroGuatemalteco,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Cards
            if (_cargando)
              const SizedBox(
                height: 240,
                child: Center(
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AlpesColors.cafeOscuro),
                  ),
                ),
              )
            else if (_productos.isEmpty)
              _sinProductos()
            else
              SizedBox(
                height: 290,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _productos.length,
                  itemBuilder: (_, i) {
                    final p = _productos[i];
                    final nombre = (p['NOMBRE'] ?? p['nombre'] ?? 'Producto').toString();
                    final precio = double.tryParse(
                            '${p['PRECIO'] ?? p['precio'] ?? 0}') ?? 0;
                    final imgUrl = (p['IMAGEN_URL'] ?? p['imagen_url']) as String?;
                    final tipo   = (p['TIPO'] ?? p['tipo'] ?? '').toString();

                    return GestureDetector(
                      onTap: _mostrarAcceso,
                      child: Container(
                        width: 170,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: AlpesColors.pergamino, width: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen
                            Expanded(
                              flex: 5,
                              child: Stack(fit: StackFit.expand, children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(2)),
                                  child: imgUrl != null && imgUrl.isNotEmpty
                                      ? Image.network(imgUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _imgPlaceholder())
                                      : _imgPlaceholder(),
                                ),
                                if (tipo.isNotEmpty)
                                  Positioned(
                                    top: 8, left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      color: AlpesColors.cafeOscuro
                                          .withOpacity(0.85),
                                      child: Text(tipo.toUpperCase(),
                                          style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              color: AlpesColors.oroGuatemalteco,
                                              fontSize: 7,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.8)),
                                    ),
                                  ),
                              ]),
                            ),
                            // Info
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 8, 10, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(nombre,
                                        style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: AlpesColors.grafito),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Expanded(
                                        child: Text(
                                          precio > 0
                                              ? 'Q ${precio.toStringAsFixed(0)}'
                                              : 'Consultar',
                                          style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AlpesColors.cafeOscuro),
                                        ),
                                      ),
                                      // Divisor + icono carrito
                                      Container(
                                          width: 0.7, height: 28,
                                          color: AlpesColors.pergamino,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8)),
                                      GestureDetector(
                                        onTap: _mostrarAcceso,
                                        child: const Icon(
                                          Icons.shopping_cart_outlined,
                                          color: AlpesColors.cafeOscuro,
                                          size: 18,
                                        ),
                                      ),
                                    ]),
                                    if (precio > 0)
                                      Text(
                                        '12 cuotas de Q ${(precio / 12).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 9,
                                            color: AlpesColors.rojoColonial,
                                            fontWeight: FontWeight.w500),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: AlpesColors.cremaFondo,
        child: Center(
          child: Icon(Icons.chair_outlined,
              size: 36, color: AlpesColors.arenaCalida.withOpacity(0.35)),
        ),
      );

  Widget _sinProductos() => const SizedBox(
        height: 80,
        child: Center(
          child: Text('Cargando productos...',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AlpesColors.arenaCalida,
                  fontSize: 13)),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════
  //  BENEFICIOS — franja oscura
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildBeneficios() {
    final items = [
      _Beneficio(Icons.local_shipping_outlined,   'Envio sin costo',    'A toda Guatemala'),
      _Beneficio(Icons.workspace_premium_outlined, 'Garantia de 1 ano', 'Por defecto de fabrica'),
      _Beneficio(Icons.precision_manufacturing_outlined, 'Artesanal', 'Fabricado a mano'),
      _Beneficio(Icons.swap_horiz_rounded,        'Devolucion',         'Primeros 30 dias'),
    ];

    return Container(
      color: AlpesColors.cafeOscuro,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((b) => Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(b.icono, color: AlpesColors.oroGuatemalteco, size: 20),
            const SizedBox(height: 6),
            Text(b.titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(b.subtitulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 9)),
          ]),
        )).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  EDITORIAL — tres columnas de tendencias/estilos
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildEditorial() {
    final tendencias = [
      _Tendencia('Minimalismo\nCálido',   'Espacios serenos', const Color(0xFF2C1810)),
      _Tendencia('Estilo\nColonial',      'Herencia guatemalteca', const Color(0xFF1A3A2A)),
      _Tendencia('Ecléctico\nModerno',    'Fusion con caracter', const Color(0xFF283040)),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 32),
      child: Column(children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            Text('Tendencias 2025',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AlpesColors.arenaCalida,
                    letterSpacing: 2.0)),
            SizedBox(height: 4),
            Text('Inspiracion para tu hogar',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: AlpesColors.cafeOscuro,
                    letterSpacing: -0.5)),
          ]),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: tendencias.map((t) => Expanded(
              child: GestureDetector(
                onTap: _mostrarAcceso,
                child: Container(
                  height: 210,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  color: t.color,
                  child: Stack(fit: StackFit.expand, children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.45),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.35),
                                  width: 0.7),
                            ),
                            child: const Text('TENDENCIA',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 6,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0)),
                          ),
                          const SizedBox(height: 8),
                          Text(t.titulo,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2)),
                          const SizedBox(height: 8),
                          Text(t.subtitulo,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 9,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 10, right: 10,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ]),
                ),
              ),
            )).toList(),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CTA — crear cuenta
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCTA() {
    return Container(
      color: AlpesColors.cafeOscuro,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      child: Column(children: [
        // Linea decorativa
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 30, height: 0.8,
              color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
          const SizedBox(width: 10),
          Container(width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: AlpesColors.oroGuatemalteco,
                  shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Container(width: 30, height: 0.8,
              color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
        ]),
        const SizedBox(height: 22),
        const Text('Transforma tu hogar',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
                letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text('Crea tu cuenta y accede a precios exclusivos,\ncuotas y seguimiento de pedidos en tiempo real.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
                height: 1.6)),
        const SizedBox(height: 28),
        // Boton registro
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _irARegistro,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Crear cuenta gratuita',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AlpesColors.cafeOscuro,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Boton login
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _irALogin,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.white.withOpacity(0.2), width: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Ya tengo cuenta — Iniciar sesion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w400)),
            ),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  FOOTER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildFooter(EdgeInsets safe) {
    return Container(
      color: AlpesColors.cremaFondo,
      padding: EdgeInsets.fromLTRB(20, 28, 20, safe.bottom + 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 0.5, color: AlpesColors.pergamino),
        const SizedBox(height: 24),
        // Logo
        const Text('MUEBLES DE LOS ALPES',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AlpesColors.cafeOscuro,
                letterSpacing: 2.0)),
        Container(width: 36, height: 1.5,
            margin: const EdgeInsets.only(top: 4, bottom: 16),
            color: AlpesColors.oroGuatemalteco),
        // Contacto
        _FooterRow(Icons.phone_outlined,        'Telefono: (502) 2490-0000'),
        const SizedBox(height: 6),
        _FooterRow(Icons.email_outlined,         'ventas@mueblesdelosalpes.com.gt'),
        const SizedBox(height: 6),
        _FooterRow(Icons.location_on_outlined,   'Guatemala, Ciudad de Guatemala'),
        const SizedBox(height: 20),
        // Redes
        Row(children: [
          _SocialBtn(Icons.facebook_rounded),
          const SizedBox(width: 8),
          _SocialBtn(Icons.camera_alt_outlined),
          const SizedBox(width: 8),
          _SocialBtn(Icons.play_circle_outline_rounded),
        ]),
        const SizedBox(height: 24),
        Container(height: 0.5, color: AlpesColors.pergamino),
        const SizedBox(height: 16),
        Text(
          'c ${DateTime.now().year} Muebles de los Alpes. Todos los derechos reservados.',
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: AlpesColors.arenaCalida),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MODAL DE ACCESO
// ═══════════════════════════════════════════════════════════════════════════
class _ModalAcceso extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegistro;
  final String? categoria;
  const _ModalAcceso({required this.onLogin, required this.onRegistro, this.categoria});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(
              width: 32, height: 3,
              decoration: BoxDecoration(
                  color: AlpesColors.pergamino,
                  borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 28),
        // Header
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: AlpesColors.cafeOscuro,
                borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.chair_alt_rounded,
                color: AlpesColors.oroGuatemalteco, size: 24),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Muebles de los Alpes',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AlpesColors.cafeOscuro)),
            Text(
              categoria != null
                  ? 'Ver productos de $categoria'
                  : 'Bienvenido de vuelta',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: categoria != null
                      ? AlpesColors.oroGuatemalteco
                      : AlpesColors.nogalMedio)),
          ]),
        ]),
        const SizedBox(height: 28),
        // Iniciar sesion
        GestureDetector(
          onTap: onLogin,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
                color: AlpesColors.cafeOscuro,
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Iniciar sesion',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Ya tengo una cuenta',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11)),
                ]),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: AlpesColors.oroGuatemalteco, size: 18),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        // Crear cuenta
        GestureDetector(
          onTap: onRegistro,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco,
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Crear cuenta gratuita',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AlpesColors.cafeOscuro,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('Sin compromisos',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AlpesColors.cafeOscuro.withOpacity(0.5),
                          fontSize: 11)),
                ]),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: AlpesColors.cafeOscuro, size: 18),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text('Continuar explorando',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AlpesColors.arenaCalida,
                    fontSize: 12,
                    fontWeight: FontWeight.w400)),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CHAT BOT FLOTANTE — sin emojis, clean
// ═══════════════════════════════════════════════════════════════════════════
class _ChatBot extends StatefulWidget {
  final VoidCallback onAcceso;
  const _ChatBot({required this.onAcceso});
  @override
  State<_ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<_ChatBot> with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  final _textCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _escribiendo = false;

  final List<_Msg> _mensajes = const [
    _Msg('Hola. Soy el asistente de Muebles de los Alpes. En que puedo ayudarte hoy?', false),
  ];
  List<_Msg> _chat = [];

  final _respuestasRapidas = [
    'Horarios de atencion',
    'Donde estan ubicados',
    'Como funciona el envio',
    'Formas de pago',
  ];

  @override
  void initState() {
    super.initState();
    _chat = List.from(_mensajes);
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  String _responder(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('horario') || m.contains('hora') || m.contains('abren'))
      return 'Nuestros horarios son:\nLunes a Viernes: 8:00 AM - 6:00 PM\nSabados: 9:00 AM - 5:00 PM\nDomingos: 10:00 AM - 2:00 PM';
    if (m.contains('ubic') || m.contains('donde') || m.contains('direcc'))
      return 'Contamos con sucursales en:\n- Zona 10, Ciudad de Guatemala\n- Zona 18, Ciudad de Guatemala\n- Antigua Guatemala';
    if (m.contains('envio') || m.contains('entrega') || m.contains('enviar'))
      return 'Realizamos envios sin costo a toda Guatemala. El tiempo de entrega es de 3 a 7 dias habiles segun el departamento.';
    if (m.contains('pago') || m.contains('cuota') || m.contains('tarjeta'))
      return 'Aceptamos efectivo, tarjetas de credito y debito, transferencia bancaria y cheques certificados. Ofrecemos cuotas hasta 12 meses.';
    if (m.contains('gracias') || m.contains('listo') || m.contains('ok'))
      return 'Con mucho gusto. Estoy aqui si necesitas algo mas.';
    return 'Puedo ayudarte con informacion sobre horarios, ubicaciones, envios y formas de pago. Para ver productos y realizar compras, te invitamos a crear tu cuenta.';
  }

  void _enviar([String? texto]) {
    final msg = (texto ?? _textCtrl.text).trim();
    if (msg.isEmpty) return;
    setState(() {
      _chat.add(_Msg(msg, true));
      _textCtrl.clear();
      _escribiendo = true;
    });
    _scrollFinal();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _escribiendo = false;
        _chat.add(_Msg(_responder(msg), false));
      });
      _scrollFinal();
    });
  }

  void _scrollFinal() => Future.delayed(const Duration(milliseconds: 80), () {
    if (_scrollCtrl.hasClients)
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end, children: [
      if (_open)
        ScaleTransition(
          scale: _scale,
          alignment: Alignment.bottomRight,
          child: Container(
            width: 300,
            height: 400,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.14),
                    blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(children: [
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
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: AlpesColors.oroGuatemalteco,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.support_agent_rounded,
                        color: AlpesColors.cafeOscuro, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Asistente Alpes',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Row(children: [
                      Container(width: 5, height: 5,
                          decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('En linea',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 9)),
                    ]),
                  ])),
                  GestureDetector(
                    onTap: _toggle,
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white38, size: 18),
                  ),
                ]),
              ),
              // Mensajes
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(10),
                  itemCount: _chat.length + (_escribiendo ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_escribiendo && i == _chat.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                              color: AlpesColors.cremaFondo,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AlpesColors.pergamino)),
                          child: Row(mainAxisSize: MainAxisSize.min,
                              children: const [
                            _PuntoCarga(delay: 0),
                            SizedBox(width: 4),
                            _PuntoCarga(delay: 200),
                            SizedBox(width: 4),
                            _PuntoCarga(delay: 400),
                          ]),
                        ),
                      );
                    }
                    final m = _chat[i];
                    return Align(
                      alignment: m.esUsuario
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        constraints: const BoxConstraints(maxWidth: 220),
                        decoration: BoxDecoration(
                          color: m.esUsuario
                              ? AlpesColors.cafeOscuro
                              : AlpesColors.cremaFondo,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(10),
                            topRight: const Radius.circular(10),
                            bottomLeft: Radius.circular(m.esUsuario ? 10 : 2),
                            bottomRight: Radius.circular(m.esUsuario ? 2 : 10),
                          ),
                          border: !m.esUsuario
                              ? Border.all(color: AlpesColors.pergamino)
                              : null,
                        ),
                        child: Text(m.texto,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                height: 1.5,
                                color: m.esUsuario
                                    ? Colors.white
                                    : AlpesColors.cafeOscuro)),
                      ),
                    );
                  },
                ),
              ),
              // Respuestas rapidas
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  itemCount: _respuestasRapidas.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _enviar(_respuestasRapidas[i]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AlpesColors.pergamino, width: 0.8),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(_respuestasRapidas[i],
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              color: AlpesColors.nogalMedio,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
              ),
              // Input
              Container(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AlpesColors.pergamino, width: 0.8)),
                ),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      onSubmitted: (_) => _enviar(),
                      textInputAction: TextInputAction.send,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AlpesColors.cafeOscuro),
                      decoration: InputDecoration(
                        hintText: 'Escribe tu pregunta...',
                        hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            color: AlpesColors.arenaCalida.withOpacity(0.7),
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
                    onTap: _enviar,
                    child: Container(
                      width: 34, height: 34,
                      decoration: const BoxDecoration(
                          color: AlpesColors.cafeOscuro,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded,
                          color: AlpesColors.oroGuatemalteco, size: 15),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      // Boton flotante
      GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: _open
                ? AlpesColors.nogalMedio
                : AlpesColors.cafeOscuro,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AlpesColors.cafeOscuro.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Icon(
            _open ? Icons.close_rounded : Icons.chat_outlined,
            color: AlpesColors.oroGuatemalteco, size: 22,
          ),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════

class _HeaderBtn extends StatelessWidget {
  final IconData  icon;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(icon, color: AlpesColors.cafeOscuro, size: 20),
        ),
      );
}

class _NavChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: label == 'Ofertas'
                      ? AlpesColors.rojoColonial
                      : AlpesColors.grafito)),
        ),
      );
}

class _FooterRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _FooterRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 13, color: AlpesColors.arenaCalida),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AlpesColors.nogalMedio)),
        ),
      ]);
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  const _SocialBtn(this.icon);
  @override
  Widget build(BuildContext context) => Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          border: Border.all(
              color: AlpesColors.arenaCalida.withOpacity(0.35), width: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: AlpesColors.cafeOscuro),
      );
}

class _PuntoCarga extends StatefulWidget {
  final int delay;
  const _PuntoCarga({required this.delay});
  @override
  State<_PuntoCarga> createState() => _PuntoCargaState();
}

class _PuntoCargaState extends State<_PuntoCarga>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay),
        () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _a,
        child: Container(
          width: 5, height: 5,
          decoration: const BoxDecoration(
              color: AlpesColors.arenaCalida, shape: BoxShape.circle),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  MODELOS
// ═══════════════════════════════════════════════════════════════════════════

class _HeroSlide {
  final String etiqueta, titulo, subtitulo;
  final Color  colorFondo, colorAccento;
  const _HeroSlide({
    required this.etiqueta,
    required this.titulo,
    required this.subtitulo,
    required this.colorFondo,
    required this.colorAccento,
  });
}

class _Categoria {
  final String   nombre;
  final IconData icono;
  final Color    color;
  const _Categoria(this.nombre, this.icono, this.color);
}

class _Beneficio {
  final IconData icono;
  final String   titulo, subtitulo;
  const _Beneficio(this.icono, this.titulo, this.subtitulo);
}

class _Tendencia {
  final String titulo, subtitulo;
  final Color  color;
  const _Tendencia(this.titulo, this.subtitulo, this.color);
}

class _Msg {
  final String texto;
  final bool   esUsuario;
  const _Msg(this.texto, this.esUsuario);
}