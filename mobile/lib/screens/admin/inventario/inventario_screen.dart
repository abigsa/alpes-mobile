import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _productos = [];
  bool _loading = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _toInt(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;

  String _readString(
    Map<String, dynamic> item,
    List<String> keys, [
    String fallback = '',
  ]) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  String _normalizeText(String value) {
    var text = value.toLowerCase().trim();
    const accents = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ñ': 'n',
    };

    accents.forEach((key, replacement) {
      text = text.replaceAll(key, replacement);
    });

    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return text;
  }

  bool _matchesSearch(String source, String query) {
    if (query.isEmpty) return true;

    final rawSource = source.toLowerCase();
    final rawQuery = query.toLowerCase();

    if (rawSource.contains(rawQuery)) return true;

    final normalizedSource = _normalizeText(source);
    final normalizedQuery = _normalizeText(query);

    if (normalizedQuery.isEmpty) return true;
    return normalizedSource.contains(normalizedQuery);
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.inventarioProducto)),
        http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.productos)),
      ]);

      final inventarioData = jsonDecode(responses[0].body);
      final productosData = jsonDecode(responses[1].body);

      if (inventarioData['ok'] == true) {
        _items = List<Map<String, dynamic>>.from(inventarioData['data'] ?? []);
      }

      if (productosData['ok'] == true) {
        _productos = List<Map<String, dynamic>>.from(productosData['data'] ?? []);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _eliminar(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Confirmar'),
        content: const Text('¿Eliminar este registro de inventario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AlpesColors.rojoColonial,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventarioProducto}/$id'),
    );

    _cargar();
  }

  void _abrirForm([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InventarioForm(
        item: item,
        onGuardado: _cargar,
      ),
    );
  }

  Map<String, dynamic>? _buscarProductoPorId(int productoId) {
    for (final producto in _productos) {
      final id = _toInt(producto['PRODUCTO_ID'] ?? producto['producto_id']);
      if (id == productoId) return producto;
    }
    return null;
  }

  Map<String, dynamic> _mergeItem(Map<String, dynamic> item) {
    final productoId = _toInt(item['PRODUCTO_ID'] ?? item['producto_id']);
    final producto = _buscarProductoPorId(productoId) ?? <String, dynamic>{};
    return {...producto, ...item};
  }

  List<Map<String, dynamic>> get _itemsFiltrados {
    final query = _busqueda.trim();
    final merged = _items.map(_mergeItem).toList();

    if (query.isEmpty) return merged;

    return merged.where((item) {
      final idInventario = _toInt(
        item['INV_PROD_ID'] ??
            item['inv_prod_id'] ??
            item['INVENTARIO_PRODUCTO_ID'] ??
            item['inventario_producto_id'] ??
            item['ID'] ??
            item['id'],
      );
      final productoId = _toInt(item['PRODUCTO_ID'] ?? item['producto_id']);
      final nombre = _readString(
        item,
        ['NOMBRE', 'nombre', 'PRODUCTO_NOMBRE', 'producto_nombre'],
      );
      final referencia = _readString(item, ['REFERENCIA', 'referencia']);
      final categoria = _readString(item, ['CATEGORIA_NOMBRE', 'categoria_nombre']);
      final color = _readString(item, ['COLOR', 'color']);
      final tipo = _readString(item, ['TIPO', 'tipo']);
      final descripcion = _readString(item, ['DESCRIPCION', 'descripcion']);

      final searchBlob = [
        idInventario,
        productoId,
        nombre,
        referencia,
        categoria,
        color,
        tipo,
        descripcion,
        'producto#$productoId',
        'producto $productoId',
        'id$idInventario',
      ].join(' ');

      return _matchesSearch(searchBlob, query);
    }).toList();
  }

  int get _totalStock => _itemsFiltrados.fold<int>(
        0,
        (sum, item) => sum + _toInt(item['STOCK'] ?? item['stock']),
      );

  int get _totalReservado => _itemsFiltrados.fold<int>(
        0,
        (sum, item) => sum + _toInt(item['STOCK_RESERVADO'] ?? item['stock_reservado']),
      );

  int get _bajoMinimo => _itemsFiltrados.where((item) {
        final stock = _toInt(item['STOCK'] ?? item['stock']);
        final minimo = _toInt(item['STOCK_MINIMO'] ?? item['stock_minimo']);
        return stock <= minimo;
      }).length;

  Color _stockColor(int stock, int minimo) {
    if (stock <= minimo) return AlpesColors.rojoColonial;
    if (stock <= (minimo + 5)) return AlpesColors.oroGuatemalteco;
    return AlpesColors.verdeSelva;
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color tint,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint == Colors.white ? AlpesColors.pergamino : tint.withOpacity(0.85)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AlpesColors.nogalMedio,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AlpesColors.cafeOscuro,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AlpesColors.pergamino,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(
          child: Icon(
            Icons.inventory_2_rounded,
            size: 34,
            color: AlpesColors.nogalMedio,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AlpesColors.pergamino,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 32,
              color: AlpesColors.nogalMedio,
            ),
          ),
        ),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AlpesColors.pergamino,
            child: const Center(
              child: CircularProgressIndicator(
                color: AlpesColors.cafeOscuro,
                strokeWidth: 2,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader() {
    final total = _itemsFiltrados.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: AlpesColors.pergamino,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AlpesColors.cafeOscuro,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventario de productos',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AlpesColors.cafeOscuro,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visualiza stock, reserva y detalle del producto en un solo lugar.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AlpesColors.nogalMedio,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AlpesColors.cremaFondo,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AlpesColors.pergamino,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AlpesColors.oroGuatemalteco,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$total registros visibles',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AlpesColors.cafeOscuro,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _busqueda = value),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, referencia, ID, color, tipo o descripción',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _busqueda.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _busqueda = '');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildInventarioCardContent(Map<String, dynamic> item) {
    final id = _toInt(
      item['INV_PROD_ID'] ??
          item['inv_prod_id'] ??
          item['INVENTARIO_PRODUCTO_ID'] ??
          item['inventario_producto_id'] ??
          item['ID'] ??
          item['id'],
    );
    final productoId = _toInt(item['PRODUCTO_ID'] ?? item['producto_id']);

    final nombre = _readString(
      item,
      ['NOMBRE', 'nombre', 'PRODUCTO_NOMBRE', 'producto_nombre'],
      'Producto #$productoId',
    );
    final referencia = _readString(item, ['REFERENCIA', 'referencia']);
    final descripcion = _readString(item, ['DESCRIPCION', 'descripcion']);
    final tipo = _readString(item, ['TIPO', 'tipo']);
    final color = _readString(item, ['COLOR', 'color']);
    final imagen = _readString(item, ['IMAGEN_URL', 'imagen_url']);

    final stock = _toInt(item['STOCK'] ?? item['stock']);
    final reservado = _toInt(item['STOCK_RESERVADO'] ?? item['stock_reservado']);
    final minimo = _toInt(item['STOCK_MINIMO'] ?? item['stock_minimo']);
    final disponible = stock - reservado;
    final estadoColor = _stockColor(stock, minimo);
    final estadoTexto = stock <= minimo
        ? 'Stock bajo'
        : stock <= (minimo + 5)
            ? 'En alerta'
            : 'Disponible';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: _buildImage(imagen),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            nombre,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 17,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: estadoColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: estadoColor.withOpacity(0.20),
                            ),
                          ),
                          child: Text(
                            estadoTexto,
                            style: TextStyle(
                              color: estadoColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8EA),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AlpesColors.oroGuatemalteco.withOpacity(0.35),
                            ),
                          ),
                          child: Text(
                            _productoIdLabel(item),
                            style: const TextStyle(
                              color: AlpesColors.cafeOscuro,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3ECE2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _inventarioIdLabel(item),
                            style: const TextStyle(
                              color: AlpesColors.cafeOscuro,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (referencia.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Ref: $referencia',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AlpesColors.cafeOscuro,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (tipo.isNotEmpty) _chip(tipo),
                        if (color.isNotEmpty) _chip(color),
                        _chip('Disponible $disponible'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (descripcion.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AlpesColors.cremaFondo,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                descripcion,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _stockBox(
                  'Stock actual',
                  '$stock',
                  Icons.inventory_2_rounded,
                  background: const Color(0xFFF4EEE6),
                  accent: AlpesColors.cafeOscuro,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stockBox(
                  'Reservado',
                  '$reservado',
                  Icons.lock_clock_outlined,
                  background: const Color(0xFFFFF6E8),
                  accent: AlpesColors.oroGuatemalteco,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stockBox(
                  'Bajo mínimo',
                  '$minimo',
                  Icons.warning_amber_rounded,
                  background: const Color(0xFFF9ECE9),
                  accent: AlpesColors.rojoColonial,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _abrirForm(item),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: id > 0 ? () => _eliminar(id) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AlpesColors.rojoColonial,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _productoIdLabel(Map<String, dynamic> item) {
    final productoId = _toInt(item['PRODUCTO_ID'] ?? item['producto_id']);
    return productoId > 0 ? 'ID producto #$productoId' : 'ID no disponible';
  }

  String _inventarioIdLabel(Map<String, dynamic> item) {
    final id = _toInt(
      item['INV_PROD_ID'] ??
          item['inv_prod_id'] ??
          item['INVENTARIO_PRODUCTO_ID'] ??
          item['inventario_producto_id'] ??
          item['ID'] ??
          item['id'],
    );
    return id > 0 ? 'Inventario #$id' : 'Inventario sin ID';
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AlpesColors.pergamino,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AlpesColors.cafeOscuro,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _stockBox(
    String label,
    String value,
    IconData icon, {
    required Color background,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AlpesColors.nogalMedio,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AlpesColors.cafeOscuro,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsFiltrados;

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('INVENTARIO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _abrirForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AlpesColors.cafeOscuro),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: AlpesColors.cafeOscuro,
                    onRefresh: _cargar,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: [
                        _buildHeroHeader(),
                        const SizedBox(height: 16),
                        _buildSearchBox(),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.inventory_2_rounded,
                                label: 'Productos',
                                value: '${items.length}',
                                tint: const Color(0xFFF4EEE6),
                                iconColor: AlpesColors.cafeOscuro,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.stacked_bar_chart_rounded,
                                label: 'Stock actual',
                                value: '$_totalStock',
                                tint: const Color(0xFFEFF4EE),
                                iconColor: AlpesColors.verdeSelva,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.lock_clock_rounded,
                                label: 'Reservado',
                                value: '$_totalReservado',
                                tint: const Color(0xFFFFF6E8),
                                iconColor: AlpesColors.oroGuatemalteco,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                icon: Icons.warning_amber_rounded,
                                label: 'Bajo mínimo',
                                value: '$_bajoMinimo',
                                tint: const Color(0xFFFFEFEC),
                                iconColor: AlpesColors.rojoColonial,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (items.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: AlpesColors.pergamino),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 72,
                                  color: AlpesColors.arenaCalida,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _busqueda.trim().isEmpty
                                      ? 'No hay registros de inventario'
                                      : 'No se encontraron coincidencias',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _busqueda.trim().isEmpty
                                      ? 'Agrega un nuevo registro para comenzar.'
                                      : 'Prueba con nombre, referencia, IDs, color, tipo o descripción.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _abrirForm(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Agregar inventario'),
                                ),
                              ],
                            ),
                          )
                        else
                          ...items.map((item) => _InventarioHoverCard(
                                item: item,
                                child: _buildInventarioCardContent(item),
                              )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AlpesColors.cafeOscuro,
        onPressed: () => _abrirForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}


class _InventarioHoverCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final Widget child;

  const _InventarioHoverCard({
    required this.item,
    required this.child,
  });

  @override
  State<_InventarioHoverCard> createState() => _InventarioHoverCardState();
}

class _InventarioHoverCardState extends State<_InventarioHoverCard> {
  bool _hovered = false;

  int _toInt(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;

  @override
  Widget build(BuildContext context) {
    final stock = _toInt(widget.item['STOCK'] ?? widget.item['stock']);
    final minimo = _toInt(widget.item['STOCK_MINIMO'] ?? widget.item['stock_minimo']);
    final bool lowStock = stock <= minimo;

    final baseBorder = lowStock
        ? AlpesColors.rojoColonial.withOpacity(0.26)
        : AlpesColors.arenaCalida.withOpacity(0.42);
    const hoverBorder = AlpesColors.oroGuatemalteco;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 18),
        transform: Matrix4.identity()..translate(0.0, _hovered ? -2.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: _hovered ? hoverBorder : baseBorder,
            width: _hovered ? 1.6 : 1.15,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? AlpesColors.oroGuatemalteco.withOpacity(0.12)
                  : const Color(0x10000000),
              blurRadius: _hovered ? 24 : 18,
              spreadRadius: _hovered ? 1 : 0,
              offset: Offset(0, _hovered ? 12 : 9),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    color: _hovered
                        ? AlpesColors.oroGuatemalteco.withOpacity(0.08)
                        : Colors.transparent,
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

class _InventarioForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;

  const _InventarioForm({
    super.key,
    this.item,
    required this.onGuardado,
  });

  @override
  State<_InventarioForm> createState() => __InventarioFormState();
}

class __InventarioFormState extends State<_InventarioForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool _guardando = false;

  List<Map<String, dynamic>> _productos = [];
  bool _loadingProductos = true;
  int? _productoId;

  @override
  void initState() {
    super.initState();

    controllers['stock'] = TextEditingController();
    controllers['stock_reservado'] = TextEditingController();
    controllers['stock_minimo'] = TextEditingController();

    if (widget.item != null) {
      controllers['stock']!.text =
          (widget.item!['STOCK'] ?? widget.item!['stock'] ?? '').toString();
      controllers['stock_reservado']!.text =
          (widget.item!['STOCK_RESERVADO'] ??
                  widget.item!['stock_reservado'] ??
                  '')
              .toString();
      controllers['stock_minimo']!.text =
          (widget.item!['STOCK_MINIMO'] ?? widget.item!['stock_minimo'] ?? '')
              .toString();

      _productoId = _toInt(
        widget.item!['PRODUCTO_ID'] ?? widget.item!['producto_id'],
      );
    }

    _cargarProductos();
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  int? _validDropdownValue(
    int? selectedValue,
    List<Map<String, dynamic>> items,
    String primaryKey,
    String secondaryKey,
  ) {
    if (selectedValue == null) return null;

    final exists = items.any((item) {
      final value = _toInt(item[primaryKey] ?? item[secondaryKey]);
      return value == selectedValue;
    });

    return exists ? selectedValue : null;
  }

  Future<void> _cargarProductos() async {
    setState(() => _loadingProductos = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}'),
      );
      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        _productos = List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loadingProductos = false);
      }
    }
  }

  @override
  void dispose() {
    controllers['stock']?.dispose();
    controllers['stock_reservado']?.dispose();
    controllers['stock_minimo']?.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_productoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un producto')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final body = <String, dynamic>{
        'producto_id': _productoId,
        'stock': int.tryParse(controllers['stock']!.text.trim()) ?? 0,
        'stock_reservado':
            int.tryParse(controllers['stock_reservado']!.text.trim()) ?? 0,
        'stock_minimo':
            int.tryParse(controllers['stock_minimo']!.text.trim()) ?? 0,
      };

      final id = widget.item?['INV_PROD_ID'] ??
          widget.item?['inv_prod_id'] ??
          widget.item?['INVENTARIO_PRODUCTO_ID'] ??
          widget.item?['inventario_producto_id'] ??
          widget.item?['ID'] ??
          widget.item?['id'];

      http.Response res;

      if (id != null) {
        res = await http.put(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventarioProducto}/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } else {
        res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventarioProducto}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      }

      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        widget.onGuardado();
        if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['mensaje'] ?? 'Error'),
              backgroundColor: AlpesColors.rojoColonial,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AlpesColors.rojoColonial,
          ),
        );
      }
    } finally {
      setState(() => _guardando = false);
    }
  }

  Widget _campo(
    String label,
    String key, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controllers[key],
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AlpesColors.cremaFondo,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AlpesColors.arenaCalida,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.item == null ? 'Nuevo inventario' : 'Editar inventario',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _loadingProductos
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AlpesColors.cafeOscuro,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<int>(
                          value: _validDropdownValue(
                            _productoId,
                            _productos,
                            'PRODUCTO_ID',
                            'producto_id',
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Producto',
                          ),
                          items: _productos
                              .map((producto) {
                                final id = _toInt(
                                  producto['PRODUCTO_ID'] ??
                                      producto['producto_id'],
                                );
                                final nombre = (producto['NOMBRE'] ??
                                        producto['nombre'] ??
                                        '')
                                    .toString();
                                final referencia = (producto['REFERENCIA'] ??
                                        producto['referencia'] ??
                                        '')
                                    .toString();

                                if (id == null || nombre.isEmpty) return null;

                                final label = referencia.isNotEmpty
                                    ? '$nombre ($referencia)'
                                    : nombre;

                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(label),
                                );
                              })
                              .whereType<DropdownMenuItem<int>>()
                              .toList(),
                          onChanged: (value) {
                            setState(() => _productoId = value);
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Seleccione un producto';
                            }
                            return null;
                          },
                        ),
                      ),
                _campo(
                  'Stock',
                  'stock',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el stock';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
                _campo(
                  'Stock Reservado',
                  'stock_reservado',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el stock reservado';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
                _campo(
                  'Stock Mínimo',
                  'stock_minimo',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el stock mínimo';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('GUARDAR'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
