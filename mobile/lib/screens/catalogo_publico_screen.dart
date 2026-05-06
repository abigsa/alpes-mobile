import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../config/theme.dart';
import '../config/api_config.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  CATALOGO PUBLICO — sin login requerido
//  Accesible desde el home público al tocar Interior / Exterior
// ═══════════════════════════════════════════════════════════════════════════

class CatalogoPublicoScreen extends StatefulWidget {
  final String? categoriaInicial; // 'Interior' | 'Exterior' | null
  const CatalogoPublicoScreen({super.key, this.categoriaInicial});

  @override
  State<CatalogoPublicoScreen> createState() => _CatalogoPublicoScreenState();
}

class _CatalogoPublicoScreenState extends State<CatalogoPublicoScreen> {
  List<_Prod>   _todos      = [];
  bool          _cargando   = true;
  String        _filtro     = 'Todos';
  String        _busqueda   = '';
  final _searchCtrl = TextEditingController();

  final List<String> _tabs = ['Todos', 'Interior', 'Exterior'];

  @override
  void initState() {
    super.initState();
    _filtro = widget.categoriaInicial ?? 'Todos';
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}'))
          .timeout(const Duration(seconds: 12));
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        final lista = (data['data'] as List).map((e) => _Prod.fromJson(e)).toList();
        setState(() {
          _todos    = lista;
          _cargando = false;
        });
      } else {
        if (mounted) setState(() => _cargando = false);
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<_Prod> get _listaFiltrada {
    var lista = _filtro == 'Todos'
        ? _todos
        : _todos
            .where((p) =>
                (p.tipo ?? '').toUpperCase() == _filtro.toUpperCase())
            .toList();

    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      lista = lista
          .where((p) =>
              p.nombre.toLowerCase().contains(q) ||
              (p.descripcion ?? '').toLowerCase().contains(q))
          .toList();
    }
    return lista;
  }

  void _mostrarAcceso() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ModalAccesoPublico(
        // Pasamos el filtro activo para que el login redirija al catálogo con esa categoría
        categoriaActual: _filtro == 'Todos' ? null : _filtro,
        onLogin:    (categoria) => context.go('/login', extra: categoria),
        onRegistro: () => context.go('/registro'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safe  = MediaQuery.of(context).padding;
    final lista = _listaFiltrada;
    final w     = MediaQuery.of(context).size.width;
    final cols  = w > 600 ? 3 : 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AlpesColors.cremaFondo,
        body: Column(children: [
          // ── HEADER ────────────────────────────────────────────
          _buildHeader(safe),

          // ── TABS ──────────────────────────────────────────────
          _buildTabs(),

          // ── BUSCADOR ──────────────────────────────────────────
          _buildBuscador(),

          // ── BANNER CTA ────────────────────────────────────────
          _buildBannerCTA(),

          // ── PRODUCTOS ─────────────────────────────────────────
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AlpesColors.cafeOscuro, strokeWidth: 2))
                : lista.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AlpesColors.cafeOscuro,
                        onRefresh: _cargar,
                        child: GridView.builder(
                          padding: EdgeInsets.fromLTRB(
                              12, 12, 12, safe.bottom + 20),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: lista.length,
                          itemBuilder: (_, i) =>
                              _ProductoCardPublico(
                            producto:      lista[i],
                            onVerProducto: _mostrarAcceso,
                          ),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader(EdgeInsets safe) {
    return Container(
      color: AlpesColors.cafeOscuro,
      padding: EdgeInsets.fromLTRB(16, safe.top + 12, 16, 16),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.canPop() ? context.pop() : context.go('/home-publica'),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 15),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('MUEBLES DE LOS ALPES',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AlpesColors.oroGuatemalteco,
                    letterSpacing: 2.0)),
            Row(children: [
              Text(
                _filtro == 'Todos' ? 'Catalogo' : _filtro,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3),
              ),
              const SizedBox(width: 8),
              if (!_cargando)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
                  ),
                  child: Text('${_listaFiltrada.length}',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AlpesColors.oroGuatemalteco,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
          ]),
        ),
        GestureDetector(
          onTap: _mostrarAcceso,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AlpesColors.oroGuatemalteco,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Ingresar',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AlpesColors.cafeOscuro,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  // ── TABS ────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Container(
      color: const Color(0xFF1C0F08),
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        children: _tabs.map((t) {
          final activo = _filtro == t;
          final count  = t == 'Todos'
              ? _todos.length
              : _todos
                  .where((p) =>
                      (p.tipo ?? '').toUpperCase() == t.toUpperCase())
                  .length;
          return GestureDetector(
            onTap: () => setState(() => _filtro = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: activo
                    ? AlpesColors.oroGuatemalteco
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(t,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: activo
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: activo
                            ? AlpesColors.cafeOscuro
                            : Colors.white.withOpacity(0.6))),
                if (!_cargando) ...[
                  const SizedBox(width: 5),
                  Text('$count',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: activo
                              ? AlpesColors.cafeOscuro.withOpacity(0.6)
                              : Colors.white.withOpacity(0.3))),
                ],
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── BUSCADOR ────────────────────────────────────────────────────────────
  Widget _buildBuscador() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AlpesColors.cremaFondo,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AlpesColors.pergamino),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _busqueda = v),
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AlpesColors.cafeOscuro),
          decoration: InputDecoration(
            hintText: 'Buscar muebles...',
            hintStyle: const TextStyle(
                fontFamily: 'Poppins',
                color: AlpesColors.arenaCalida,
                fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AlpesColors.arenaCalida, size: 19),
            suffixIcon: _busqueda.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AlpesColors.arenaCalida, size: 17),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _busqueda = '');
                    })
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  // ── BANNER CTA ──────────────────────────────────────────────────────────
  Widget _buildBannerCTA() {
    return GestureDetector(
      onTap: _mostrarAcceso,
      child: Container(
        color: AlpesColors.oroGuatemalteco.withOpacity(0.12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          const Icon(Icons.lock_open_rounded,
              color: AlpesColors.arenaCalida, size: 16),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Crea una cuenta para agregar al carrito, ver precios especiales y hacer pedidos',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AlpesColors.cafeOscuro,
                  height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AlpesColors.cafeOscuro,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Unirse',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AlpesColors.oroGuatemalteco,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.chair_alt_rounded,
              size: 56, color: AlpesColors.arenaCalida.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Sin productos',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AlpesColors.cafeOscuro)),
          const SizedBox(height: 6),
          const Text('Intenta con otra búsqueda o categoría',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AlpesColors.nogalMedio)),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  CARD DE PRODUCTO PÚBLICA
// ═══════════════════════════════════════════════════════════════════════════
class _ProductoCardPublico extends StatelessWidget {
  final _Prod       producto;
  final VoidCallback onVerProducto;
  const _ProductoCardPublico(
      {required this.producto, required this.onVerProducto});

  @override
  Widget build(BuildContext context) {
    final p = producto;
    return GestureDetector(
      onTap: onVerProducto,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AlpesColors.pergamino, width: 0.8),
          boxShadow: [
            BoxShadow(
                color: AlpesColors.cafeOscuro.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Expanded(
            flex: 5,
            child: Stack(fit: StackFit.expand, children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: p.imagenUrl != null && p.imagenUrl!.isNotEmpty
                    ? Image.network(p.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              if (p.tipo != null && p.tipo!.isNotEmpty)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AlpesColors.cafeOscuro.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(p.tipo!.toUpperCase(),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AlpesColors.oroGuatemalteco,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                  ),
                ),
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      size: 13, color: AlpesColors.cafeOscuro),
                ),
              ),
            ]),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p.nombre,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AlpesColors.cafeOscuro),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.precio != null && p.precio! > 0
                            ? 'Q ${p.precio!.toStringAsFixed(0)}'
                            : 'Consultar',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AlpesColors.cafeOscuro),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AlpesColors.cafeOscuro,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Ver',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AlpesColors.oroGuatemalteco,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AlpesColors.cremaFondo,
        child: Center(
          child: Icon(Icons.chair_outlined,
              size: 32, color: AlpesColors.arenaCalida.withOpacity(0.3)),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  MODAL DE ACCESO — ahora pasa la categoría al login
// ═══════════════════════════════════════════════════════════════════════════
class _ModalAccesoPublico extends StatelessWidget {
  final String?              categoriaActual;
  final void Function(String?) onLogin;
  final VoidCallback           onRegistro;
  const _ModalAccesoPublico({
    required this.categoriaActual,
    required this.onLogin,
    required this.onRegistro,
  });

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
        const SizedBox(height: 24),
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
            const Text('Para comprar necesitas una cuenta',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AlpesColors.cafeOscuro)),
            Text('Es gratis y toma menos de 1 minuto',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AlpesColors.nogalMedio)),
          ]),
        ]),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onRegistro,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
                color: AlpesColors.oroGuatemalteco,
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Crear cuenta gratuita',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AlpesColors.cafeOscuro,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
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
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => onLogin(categoriaActual),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: AlpesColors.pergamino, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Ya tengo cuenta — Iniciar sesión',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AlpesColors.cafeOscuro,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MODELO LOCAL
// ═══════════════════════════════════════════════════════════════════════════
class _Prod {
  final int     id;
  final String  nombre;
  final String? tipo;
  final String? descripcion;
  final String? imagenUrl;
  final double? precio;

  const _Prod({
    required this.id,
    required this.nombre,
    this.tipo,
    this.descripcion,
    this.imagenUrl,
    this.precio,
  });

  factory _Prod.fromJson(Map<String, dynamic> j) => _Prod(
        id:          j['PRODUCTO_ID'] ?? j['producto_id'] ?? 0,
        nombre:      j['NOMBRE']      ?? j['nombre']      ?? '',
        tipo:        j['TIPO']        ?? j['tipo'],
        descripcion: j['DESCRIPCION'] ?? j['descripcion'],
        imagenUrl:   j['IMAGEN_URL']  ?? j['imagen_url'],
        precio: double.tryParse(
            '${j['PRECIO'] ?? j['precio'] ?? 0}'),
      );
}
