import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../../../config/theme.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

enum _TrendChartMode { columnas, linea, area }

class _ReportesScreenState extends State<ReportesScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _ordenes = [];
  final List<Map<String, dynamic>> _detallesOrden = [];
  final List<Map<String, dynamic>> _estadosOrden = [];
  final List<Map<String, dynamic>> _clientes = [];
  final List<Map<String, dynamic>> _inventario = [];
  final List<Map<String, dynamic>> _productos = [];

  bool _loading = true;
  String? _error;
  bool _apiConectada = false;

  late final AnimationController _fadeController;
  late final AnimationController _chartsController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _chartsAnimation;

  int _selectedYear = DateTime.now().year;
  int? _compareYear;
  _TrendChartMode _chartMode = _TrendChartMode.linea;

  // Nuevo: mes seleccionado para filtro de trimestre (0 = Enero, 11 = Diciembre, -1 = Anual)
  int _selectedMonth = -1; // -1 significa "Anual"

  // Lista de meses con opción anual
  final List<MapEntry<String, int>> _monthOptions = [
    const MapEntry('📅 Anual', -1),
    const MapEntry('Ene', 0),
    const MapEntry('Feb', 1),
    const MapEntry('Mar', 2),
    const MapEntry('Abr', 3),
    const MapEntry('May', 4),
    const MapEntry('Jun', 5),
    const MapEntry('Jul', 6),
    const MapEntry('Ago', 7),
    const MapEntry('Sep', 8),
    const MapEntry('Oct', 9),
    const MapEntry('Nov', 10),
    const MapEntry('Dic', 11),
  ];

  final Map<int, List<double>> _ventasPorAnio = {};
  final Map<int, List<int>> _usuariosActivosPorAnio = {};
  final Map<int, List<int>> _usuariosAcumuladosPorAnio = {};

  final Map<String, int> _conteoEstados = {
    'Pendiente': 0,
    'En proceso': 0,
    'Entregado': 0,
    'Cancelado': 0,
  };

  double _ventasTotales = 0;
  int _totalOrdenes = 0;
  int _totalClientes = 0;
  int _stockBajo = 0;
  int _canceladas = 0;
  double _ticketPromedio = 0;
  int _itemsVendidos = 0;
  int _clientesActivosGenerales = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _chartsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _chartsAnimation = CurvedAnimation(
      parent: _chartsController,
      curve: Curves.easeOutCubic,
    );
    _cargarDatos();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _chartsController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    _fadeController.reset();
    _chartsController.reset();

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVentaDet}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.estadoOrden}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cliente}')),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventarioProducto}'),
        ),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productos}')),
      ]);

      final decoded = responses.map((response) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('HTTP ${response.statusCode}');
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      }).toList();

      _apiConectada = true;
      _cargarLista(_ordenes, decoded[0]['data']);
      _cargarLista(_detallesOrden, decoded[1]['data']);
      _cargarLista(_estadosOrden, decoded[2]['data']);
      _cargarLista(_clientes, decoded[3]['data']);
      _cargarLista(_inventario, decoded[4]['data']);
      _cargarLista(_productos, decoded[5]['data']);

      _calcularMetricas();
    } catch (e) {
      _apiConectada = false;
      _error =
          'No se pudieron cargar los reportes. Verifica la API y la conexión a la base de datos.';
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
      _fadeController.forward();
      _chartsController.forward();
    }
  }

  void _cargarLista(List<Map<String, dynamic>> destino, dynamic rawData) {
    destino
      ..clear()
      ..addAll(
        rawData is List
            ? rawData
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : <Map<String, dynamic>>[],
      );
  }

  void _calcularMetricas() {
    _ventasTotales = 0;
    _totalOrdenes = _ordenes.length;
    _totalClientes = _clientes.length;
    _canceladas = 0;
    _itemsVendidos = 0;
    _stockBajo = 0;
    _ticketPromedio = 0;
    _clientesActivosGenerales = 0;

    _ventasPorAnio.clear();
    _usuariosActivosPorAnio.clear();
    _usuariosAcumuladosPorAnio.clear();

    _conteoEstados
      ..clear()
      ..addAll({
        'Pendiente': 0,
        'En proceso': 0,
        'Entregado': 0,
        'Cancelado': 0,
      });

    for (final cliente in _clientes) {
      final activo = (_readValue(cliente, const ['ACTIVO', 'activo']) ?? 1)
              .toString()
              .trim() ==
          '1';
      if (activo) _clientesActivosGenerales++;
    }

    for (final detalle in _detallesOrden) {
      _itemsVendidos += _toInt(
        _readValue(detalle, const ['CANTIDAD', 'cantidad']),
      );
    }

    final Map<int, Map<int, Set<String>>> monthlyActiveClients = {};
    final Map<int, Set<String>> cumulativeClientsByYear = {};

    for (final orden in _ordenes) {
      final total = _toDouble(_readValue(orden, const ['TOTAL', 'total']));
      final fecha = _parseDate(
        _readValue(orden, const ['FECHA_ORDEN', 'fecha_orden']),
      );
      final estado = _prettyEstado(_resolverEstado(orden));
      final clienteId = _orderClientId(orden);

      _ventasTotales += total;

      if (fecha != null) {
        _ventasPorAnio.putIfAbsent(fecha.year, () => List<double>.filled(12, 0));
        _ventasPorAnio[fecha.year]![fecha.month - 1] += total;

        monthlyActiveClients.putIfAbsent(fecha.year, () => {});
        monthlyActiveClients[fecha.year]!
            .putIfAbsent(fecha.month, () => <String>{});

        if (clienteId != null && clienteId.isNotEmpty) {
          monthlyActiveClients[fecha.year]![fecha.month]!.add(clienteId);
        }
      }

      if (_conteoEstados.containsKey(estado)) {
        _conteoEstados[estado] = (_conteoEstados[estado] ?? 0) + 1;
      }

      if (estado.toLowerCase() == 'cancelado') {
        _canceladas++;
      }
    }

    for (final year in monthlyActiveClients.keys) {
      final activosMensuales = List<int>.filled(12, 0);
      final acumuladosMensuales = List<int>.filled(12, 0);
      final uniqueSet = <String>{};

      for (int month = 1; month <= 12; month++) {
        final monthlySet = monthlyActiveClients[year]?[month] ?? <String>{};
        activosMensuales[month - 1] = monthlySet.length;

        uniqueSet.addAll(monthlySet);
        acumuladosMensuales[month - 1] = uniqueSet.length;
      }

      _usuariosActivosPorAnio[year] = activosMensuales;
      _usuariosAcumuladosPorAnio[year] = acumuladosMensuales;
      cumulativeClientsByYear[year] = uniqueSet;
    }

    for (final item in _inventario) {
      final stock = _toInt(
        _readValue(item, const ['STOCK', 'stock', 'CANTIDAD', 'cantidad']),
      );
      final minimo = _toInt(
        _readValue(item, const ['STOCK_MINIMO', 'stock_minimo']),
      );
      if (stock <= 5 || (minimo > 0 && stock <= minimo)) {
        _stockBajo++;
      }
    }

    _ticketPromedio = _totalOrdenes > 0 ? _ventasTotales / _totalOrdenes : 0;

    final years = _ventasPorAnio.keys.toList()..sort();
    if (years.isNotEmpty && !_ventasPorAnio.containsKey(_selectedYear)) {
      _selectedYear = years.last;
    }

    final compareCandidates = _comparisonYearsFor(_selectedYear);
    if (compareCandidates.isNotEmpty) {
      if (_compareYear == null || !compareCandidates.contains(_compareYear)) {
        _compareYear = compareCandidates.first;
      }
    } else {
      _compareYear = _selectedYear - 1;
    }
  }

  String? _orderClientId(Map<String, dynamic> orden) {
    final value = _readValue(
      orden,
      const ['CLIENTE_ID', 'cliente_id', 'CLI_ID', 'cli_id'],
    );
    if (value == null) return null;
    return value.toString();
  }

  dynamic _readValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) return data[key];
    }
    return null;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim()) ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    try {
      return DateTime.parse(raw.replaceFirst(' ', 'T'));
    } catch (_) {}

    final slash = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(raw);
    if (slash != null) {
      return DateTime(
        int.parse(slash.group(3)!),
        int.parse(slash.group(2)!),
        int.parse(slash.group(1)!),
      );
    }

    final dash = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
    if (dash != null) {
      return DateTime(
        int.parse(dash.group(1)!),
        int.parse(dash.group(2)!),
        int.parse(dash.group(3)!),
      );
    }

    return null;
  }

  String _formatCurrency(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final integer = parts[0];
    final buffer = StringBuffer();

    for (int i = 0; i < integer.length; i++) {
      final position = integer.length - i;
      buffer.write(integer[i]);
      if (position > 1 && position % 3 == 1) {
        buffer.write(',');
      }
    }

    return 'Q ${buffer.toString()}.${parts[1]}';
  }

  String _formatCompactMoney(double value) {
    if (value >= 1000000) {
      return 'Q ${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return 'Q ${(value / 1000).toStringAsFixed(1)}k';
    }
    return _formatCurrency(value);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _prettyEstado(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.contains('proceso')) return 'En proceso';
    if (normalized.contains('entreg')) return 'Entregado';
    if (normalized.contains('cancel')) return 'Cancelado';
    return 'Pendiente';
  }

  String _resolverEstado(Map<String, dynamic> orden) {
    final estadoId = _readValue(
      orden,
      const ['ESTADO_ORDEN_ID', 'estado_orden_id'],
    );
    if (estadoId != null) {
      for (final estado in _estadosOrden) {
        final id = _readValue(
          estado,
          const ['ESTADO_ORDEN_ID', 'estado_orden_id'],
        );
        if ('$id' == '$estadoId') {
          final codigo = _readValue(estado, const ['CODIGO', 'codigo']);
          final nombre = _readValue(estado, const ['NOMBRE', 'nombre']);
          final raw = (codigo ?? nombre ?? '').toString();
          if (raw.isNotEmpty) return raw;
        }
      }
    }
    return (_readValue(orden, const ['ESTADO', 'estado']) ?? 'Pendiente')
        .toString();
  }

  int _itemsPorOrden(Map<String, dynamic> orden) {
    final orderId = _readValue(
      orden,
      const ['ORDEN_VENTA_ID', 'orden_venta_id'],
    );
    if (orderId == null) return 0;

    int total = 0;
    for (final detalle in _detallesOrden) {
      final detalleOrderId = _readValue(
        detalle,
        const ['ORDEN_VENTA_ID', 'orden_venta_id'],
      );
      if ('$detalleOrderId' == '$orderId') {
        total += _toInt(_readValue(detalle, const ['CANTIDAD', 'cantidad']));
      }
    }
    return total;
  }

  String _resolverProducto(Map<String, dynamic> inventario) {
    final productoId = _readValue(
      inventario,
      const ['PRODUCTO_ID', 'producto_id'],
    );
    if (productoId == null) return 'Producto sin referencia';

    for (final producto in _productos) {
      final currentId = _readValue(
        producto,
        const ['PRODUCTO_ID', 'producto_id'],
      );
      if ('$currentId' == '$productoId') {
        final nombre =
            (_readValue(producto, const ['NOMBRE', 'nombre']) ?? '')
                .toString()
                .trim();
        final referencia =
            (_readValue(producto, const ['REFERENCIA', 'referencia']) ?? '')
                .toString()
                .trim();
        if (nombre.isNotEmpty && referencia.isNotEmpty) {
          return '$nombre · $referencia';
        }
        if (nombre.isNotEmpty) return nombre;
        if (referencia.isNotEmpty) return 'Ref. $referencia';
      }
    }

    return 'Producto #$productoId';
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'Pendiente':
        return const Color(0xFFB7841B);
      case 'En proceso':
        return const Color(0xFF2F6FB2);
      case 'Entregado':
        return const Color(0xFF2E7D32);
      case 'Cancelado':
        return AlpesColors.rojoColonial;
      default:
        return AlpesColors.nogalMedio;
    }
  }

  List<int> get _availableYears {
    final years = <int>{..._ventasPorAnio.keys};
    years.add(DateTime.now().year);
    years.add(2025);
    final list = years.toList()..sort();
    return list.reversed.toList();
  }

  List<int> _comparisonYearsFor(int baseYear) {
    final set = <int>{2025, baseYear - 1};
    for (final year in _availableYears) {
      if (year != baseYear) set.add(year);
    }
    final list = set.where((year) => year != baseYear).toList()
      ..sort((a, b) => b.compareTo(a));
    return list;
  }

  List<double> _salesForYear(int year) =>
      _ventasPorAnio[year] ?? List<double>.filled(12, 0);

  List<int> _activeUsersForYear(int year) =>
      _usuariosActivosPorAnio[year] ?? List<int>.filled(12, 0);

  List<int> _cumulativeUsersForYear(int year) =>
      _usuariosAcumuladosPorAnio[year] ?? List<int>.filled(12, 0);

  int? get _previousYear {
    if (_compareYear != null) return _compareYear;
    final candidates = _comparisonYearsFor(_selectedYear);
    return candidates.isEmpty ? null : candidates.first;
  }

  double get _selectedYearTotal =>
      _salesForYear(_selectedYear).fold<double>(0, (sum, value) => sum + value);

  double get _compareYearTotal {
    final year = _previousYear;
    if (year == null) return 0;
    return _salesForYear(year).fold<double>(0, (sum, value) => sum + value);
  }

  double get _comparisonDeltaPercent {
    final previous = _compareYearTotal;
    if (previous <= 0) return _selectedYearTotal > 0 ? 100 : 0;
    return ((_selectedYearTotal - previous) / previous) * 100;
  }

  int get _selectedYearActiveUsersTotal {
    final values = _cumulativeUsersForYear(_selectedYear);
    return values.isEmpty ? 0 : values.last;
  }

  int get _compareYearActiveUsersTotal {
    final year = _previousYear;
    if (year == null) return 0;
    final values = _cumulativeUsersForYear(year);
    return values.isEmpty ? 0 : values.last;
  }

  double get _activeUsersDeltaPercent {
    final previous = _compareYearActiveUsersTotal;
    final current = _selectedYearActiveUsersTotal;
    if (previous <= 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  // Obtener el trimestre del mes seleccionado
  int _getQuarterFromMonth(int monthIndex) {
    if (monthIndex < 0) return -1; // Anual
    return (monthIndex ~/ 3) + 1;
  }

  // Obtener los índices de los meses del trimestre
  List<int> _getMonthsInQuarter(int quarter) {
    switch (quarter) {
      case 1:
        return [0, 1, 2];
      case 2:
        return [3, 4, 5];
      case 3:
        return [6, 7, 8];
      case 4:
        return [9, 10, 11];
      default:
        return [0, 1, 2];
    }
  }

  // Obtener suma de ventas del trimestre para un año
  double _getQuarterSales(int year, int quarter) {
    final months = _getMonthsInQuarter(quarter);
    final sales = _salesForYear(year);
    double total = 0;
    for (final month in months) {
      if (month < sales.length) {
        total += sales[month];
      }
    }
    return total;
  }

  // Obtener suma de usuarios activos del trimestre para un año (suma total, no promedio)
  int _getQuarterActiveUsers(int year, int quarter) {
    final months = _getMonthsInQuarter(quarter);
    final users = _activeUsersForYear(year);
    int total = 0;
    for (final month in months) {
      if (month < users.length) {
        total += users[month];
      }
    }
    return total;
  }

  // Obtener datos de ventas por mes para un trimestre específico
  List<double> _getMonthlySalesForQuarter(int year, int quarter) {
    final months = _getMonthsInQuarter(quarter);
    final sales = _salesForYear(year);
    final List<double> result = [];
    for (final month in months) {
      if (month < sales.length) {
        result.add(sales[month]);
      } else {
        result.add(0);
      }
    }
    return result;
  }

  // Obtener datos de usuarios por mes para un trimestre específico
  List<int> _getMonthlyUsersForQuarter(int year, int quarter) {
    final months = _getMonthsInQuarter(quarter);
    final users = _activeUsersForYear(year);
    final List<int> result = [];
    for (final month in months) {
      if (month < users.length) {
        result.add(users[month]);
      } else {
        result.add(0);
      }
    }
    return result;
  }

  String _getQuarterName(int quarter) {
    switch (quarter) {
      case 1:
        return 'Q1 (Ene-Mar)';
      case 2:
        return 'Q2 (Abr-Jun)';
      case 3:
        return 'Q3 (Jul-Sep)';
      case 4:
        return 'Q4 (Oct-Dic)';
      default:
        return 'Q1';
    }
  }

  String _getMonthName(int monthIndex) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    if (monthIndex >= 0 && monthIndex < months.length) {
      return months[monthIndex];
    }
    return '';
  }

  List<Map<String, dynamic>> get _ultimasOrdenes {
    final copia = [..._ordenes];
    copia.sort((a, b) {
      final fechaA = _parseDate(
            _readValue(a, const ['FECHA_ORDEN', 'fecha_orden']),
          ) ??
          DateTime(1900);
      final fechaB = _parseDate(
            _readValue(b, const ['FECHA_ORDEN', 'fecha_orden']),
          ) ??
          DateTime(1900);
      return fechaB.compareTo(fechaA);
    });
    return copia.take(10).toList();
  }

  List<Map<String, dynamic>> get _inventarioVigilancia {
    final copia = [..._inventario];
    copia.sort((a, b) {
      final ratioA = _ratioRiesgo(a);
      final ratioB = _ratioRiesgo(b);
      return ratioB.compareTo(ratioA);
    });
    return copia.where((item) {
      final stock = _toInt(
        _readValue(item, const ['STOCK', 'stock', 'CANTIDAD', 'cantidad']),
      );
      final minimo = _toInt(
        _readValue(item, const ['STOCK_MINIMO', 'stock_minimo']),
      );
      return stock <= 5 || (minimo > 0 && stock <= minimo);
    }).take(8).toList();
  }

  double _ratioRiesgo(Map<String, dynamic> inventario) {
    final stock = _toInt(
      _readValue(inventario, const ['STOCK', 'stock', 'CANTIDAD', 'cantidad']),
    );
    final minimo = _toInt(
      _readValue(inventario, const ['STOCK_MINIMO', 'stock_minimo']),
    );
    if (minimo <= 0) return stock <= 5 ? 1 : 0;
    return 1 - (stock / minimo).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: RefreshIndicator(
        color: AlpesColors.oroGuatemalteco,
        onRefresh: _cargarDatos,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              expandedHeight: 138,
              pinned: true,
              backgroundColor: AlpesColors.cafeOscuro,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/admin'),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 18,
                  bottom: 16,
                ),
                title: const Text(
                  'Reportes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                  ),
                ),
                background: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AlpesColors.cafeOscuro, Color(0xFF3B2419)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -26,
                      right: -12,
                      child: _decorativeCircle(
                        118,
                        AlpesColors.oroGuatemalteco.withOpacity(.12),
                      ),
                    ),
                    Positioned(
                      bottom: -36,
                      left: -18,
                      child: _decorativeCircle(
                        90,
                        AlpesColors.oroGuatemalteco.withOpacity(.10),
                      ),
                    ),
                    Positioned(
                      top: 42,
                      right: 70,
                      child: _decorativeCircle(
                        22,
                        AlpesColors.oroGuatemalteco.withOpacity(.16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildConnectionBanner(),
                            const SizedBox(height: 12),
                            _buildSectionTitle('Resumen ejecutivo'),
                            const SizedBox(height: 12),
                            _buildKpiGrid(),
                            const SizedBox(height: 18),
                            _buildSectionTitle('Tendencia de ventas'),
                            const SizedBox(height: 12),
                            _buildTrendCard(),
                            const SizedBox(height: 18),
                            _buildSectionTitle('Comparación por trimestre'),
                            const SizedBox(height: 12),
                            _buildQuarterComparisonCard(),
                            const SizedBox(height: 18),
                            _buildSectionTitle('Estados de órdenes'),
                            const SizedBox(height: 12),
                            _buildEstadoCharts(),
                            const SizedBox(height: 18),
                            _buildSectionTitle('Inventario en vigilancia'),
                            const SizedBox(height: 12),
                            _buildInventarioCard(),
                            const SizedBox(height: 18),
                            _buildSectionTitle('Últimas órdenes'),
                            const SizedBox(height: 12),
                            _buildUltimasOrdenesCard(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildConnectionBanner() {
    final isError = !_apiConectada || _error != null;
    final bg = isError ? const Color(0xFFF7E2DE) : const Color(0xFFE8F1E7);
    final fg = isError ? AlpesColors.rojoColonial : AlpesColors.exito;
    final text = isError
        ? (_error ?? 'No se pudo establecer conexión con la API.')
        : 'Conexión activa con la API. Datos sincronizados para órdenes, clientes, productos e inventario.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withOpacity(.20)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.wifi_off_rounded : Icons.cloud_done_rounded,
            color: fg,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 12.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AlpesColors.oroGuatemalteco,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AlpesColors.cafeOscuro,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid() {
    final cards = [
      _KpiData(
        'Ventas totales',
        _formatCompactMoney(_ventasTotales),
        Icons.trending_up_rounded,
        const [Color(0xFF2C1810), Color(0xFF5A3A26)],
      ),
      _KpiData(
        'Órdenes',
        '$_totalOrdenes',
        Icons.receipt_long_rounded,
        const [Color(0xFF4A301C), Color(0xFF7B5B33)],
      ),
      _KpiData(
        'Ticket promedio',
        _formatCurrency(_ticketPromedio),
        Icons.payments_rounded,
        const [Color(0xFF5C4423), Color(0xFF8B6F47)],
      ),
      _KpiData(
        'Clientes',
        '$_totalClientes',
        Icons.groups_2_rounded,
        const [Color(0xFF2C1810), Color(0xFF6A5437)],
      ),
      _KpiData(
        'Stock bajo ≤5',
        '$_stockBajo',
        Icons.inventory_2_rounded,
        const [Color(0xFF6A4A28), Color(0xFF9B7341)],
      ),
      _KpiData(
        'Canceladas',
        '$_canceladas',
        Icons.cancel_outlined,
        const [Color(0xFF5E2020), Color(0xFF8B2E2E)],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 760;
        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isNarrow ? 1 : 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isNarrow ? 2.9 : 3.8,
          ),
          itemBuilder: (_, index) => _buildKpiCard(cards[index]),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiData data) {
    return ScaleTransition(
      scale: Tween<double>(begin: .97, end: 1).animate(_fadeAnimation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: data.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AlpesColors.oroGuatemalteco.withOpacity(.22),
          ),
          boxShadow: [
            BoxShadow(
              color: AlpesColors.cafeOscuro.withOpacity(.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(.10)),
              ),
              child: Icon(
                data.icon,
                color: AlpesColors.oroGuatemalteco,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8E0D5),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard() {
    final currentData = _salesForYear(_selectedYear);
    final compareYear = _previousYear;
    final previousData =
        compareYear != null ? _salesForYear(compareYear) : null;
    final activeCurrent = _activeUsersForYear(_selectedYear);
    final activeCompare =
        compareYear != null ? _activeUsersForYear(compareYear) : null;
    final labels = const [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    final highlightedIndex = currentData.every((e) => e == 0)
        ? null
        : currentData.indexWhere((e) => e == currentData.reduce(math.max));
    final bestMonth =
        highlightedIndex != null ? labels[highlightedIndex] : 'Sin ventas';
    final deltaVentas = _comparisonDeltaPercent;
    final deltaUsuarios = _activeUsersDeltaPercent;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ventas por mes y comparación anual',
                  style: TextStyle(
                    color: AlpesColors.cafeOscuro,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildYearSelector(),
              const SizedBox(width: 8),
              _buildCompareYearSelector(),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChartModeChip('Columnas', _TrendChartMode.columnas),
              _buildChartModeChip('Línea', _TrendChartMode.linea),
              _buildChartModeChip('Área', _TrendChartMode.area),
              const SizedBox(width: 4),
              _legendDot(const Color(0xFF0F7B5F), '$_selectedYear'),
              if (compareYear != null)
                _legendDot(const Color(0xFF2F6FB2), '$compareYear'),
              _deltaChip(
                '${deltaVentas >= 0 ? '+' : ''}${deltaVentas.toStringAsFixed(1)}% ventas',
                deltaVentas >= 0,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 290,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AlpesColors.arenaCalida.withOpacity(.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AlpesColors.cafeOscuro.withOpacity(.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _chartsAnimation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SalesTrendPainter(
                    currentData: currentData,
                    previousData: previousData,
                    labels: labels,
                    progress: _chartsAnimation.value,
                    mode: _chartMode,
                    currentLineColor: const Color(0xFF0F7B5F),
                    currentGlowColor: const Color(0xFF39C6A3),
                    compareLineColor: const Color(0xFF2F6FB2),
                    compareGlowColor: const Color(0xFF7DB7F2),
                    barCurrentColor: const Color(0xFF0F7B5F),
                    barCompareColor: const Color(0xFF2F6FB2),
                    gridColor: AlpesColors.arenaCalida.withOpacity(.20),
                    textColor: AlpesColors.nogalMedio,
                    highlightedIndex: highlightedIndex,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 124,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AlpesColors.arenaCalida.withOpacity(.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Usuarios activos por mes',
                      style: TextStyle(
                        color: AlpesColors.cafeOscuro,
                        fontSize: 14.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _legendDot(const Color(0xFF0F7B5F), 'Activos $_selectedYear'),
                    if (compareYear != null)
                      _legendDot(
                        const Color(0xFF2F6FB2),
                        'Activos $compareYear',
                      ),
                    _deltaChip(
                      '${deltaUsuarios >= 0 ? '+' : ''}${deltaUsuarios.toStringAsFixed(1)}% usuarios',
                      deltaUsuarios >= 0,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _chartsAnimation,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _UsersActivityPainter(
                          currentData: activeCurrent,
                          previousData: activeCompare,
                          progress: _chartsAnimation.value,
                          currentColor: const Color(0xFF0F7B5F),
                          currentGlow: const Color(0xFF39C6A3),
                          previousColor: const Color(0xFF2F6FB2),
                          previousGlow: const Color(0xFF7DB7F2),
                          gridColor: AlpesColors.arenaCalida.withOpacity(.18),
                        ),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final children = [
                _metricCapsule('Mes destacado', '$bestMonth $_selectedYear'),
                _metricCapsule(
                  'Año comparado',
                  compareYear?.toString() ?? 'Sin dato',
                ),
                _metricCapsule(
                  'Usuarios activos',
                  '$_clientesActivosGenerales',
                ),
                _metricCapsule(
                  'Usuarios año $_selectedYear',
                  '$_selectedYearActiveUsersTotal',
                ),
                _metricCapsule('Items vendidos', '$_itemsVendidos'),
              ];
              if (constraints.maxWidth < 920) {
                return Column(
                  children: [
                    for (int i = 0; i < children.length; i++) ...[
                      children[i],
                      if (i != children.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    Expanded(child: children[i]),
                    if (i != children.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Tarjeta de comparación por trimestre mejorada
  Widget _buildQuarterComparisonCard() {
    final compareYear = _previousYear;
    final isAnnualView = _selectedMonth == -1;
    final currentQuarter = isAnnualView ? -1 : _getQuarterFromMonth(_selectedMonth);

    // Datos para la gráfica de barras de los 4 trimestres
    final List<double> currentQuarterSalesList = [];
    final List<double> compareQuarterSalesList = [];
    for (int q = 1; q <= 4; q++) {
      currentQuarterSalesList.add(_getQuarterSales(_selectedYear, q));
      if (compareYear != null) {
        compareQuarterSalesList.add(_getQuarterSales(compareYear, q));
      } else {
        compareQuarterSalesList.add(0);
      }
    }

    final quarterLabels = ['Q1', 'Q2', 'Q3', 'Q4'];

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Comparación por trimestre',
                  style: TextStyle(
                    color: AlpesColors.cafeOscuro,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildMonthSelector(),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isAnnualView
                ? _buildAnnualQuarterView(
                    currentQuarterSalesList,
                    compareQuarterSalesList,
                    quarterLabels,
                    compareYear,
                  )
                : _buildDetailedQuarterView(
                    currentQuarter,
                    compareYear,
                  ),
          ),
        ],
      ),
    );
  }

  // Vista anual con todos los trimestres
  Widget _buildAnnualQuarterView(
    List<double> currentSales,
    List<double> compareSales,
    List<String> labels,
    int? compareYear,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AlpesColors.arenaCalida.withOpacity(.18)),
      ),
      child: Column(
        children: [
          const Text(
            'Ventas por trimestre - Comparación anual',
            style: TextStyle(
              color: AlpesColors.cafeOscuro,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: AnimatedBuilder(
              animation: _chartsAnimation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _QuarterComparisonPainter(
                    currentData: currentSales,
                    previousData: compareSales,
                    labels: labels,
                    progress: _chartsAnimation.value,
                    currentColor: const Color(0xFF0F7B5F),
                    compareColor: const Color(0xFF2F6FB2),
                    gridColor: AlpesColors.arenaCalida.withOpacity(.20),
                    textColor: AlpesColors.nogalMedio,
                    highlightedQuarter: -1,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _legendDot(const Color(0xFF0F7B5F), '$_selectedYear'),
              if (compareYear != null)
                _legendDot(const Color(0xFF2F6FB2), '$compareYear'),
            ],
          ),
        ],
      ),
    );
  }

  // Vista detallada del trimestre seleccionado
  Widget _buildDetailedQuarterView(int quarter, int? compareYear) {
    final quarterName = _getQuarterName(quarter);
    final monthsInQuarter = _getMonthsInQuarter(quarter);
    final monthNames = monthsInQuarter.map((m) => _getMonthName(m)).toList();

    final currentSales = _getQuarterSales(_selectedYear, quarter);
    final compareSales = compareYear != null ? _getQuarterSales(compareYear, quarter) : 0.0;
    final currentUsers = _getQuarterActiveUsers(_selectedYear, quarter);
    final compareUsers = compareYear != null ? _getQuarterActiveUsers(compareYear, quarter) : 0;

    final currentMonthlySales = _getMonthlySalesForQuarter(_selectedYear, quarter);
    final compareMonthlySales = compareYear != null ? _getMonthlySalesForQuarter(compareYear, quarter) : [0.0, 0.0, 0.0];
    final currentMonthlyUsers = _getMonthlyUsersForQuarter(_selectedYear, quarter);
    final compareMonthlyUsers = compareYear != null ? _getMonthlyUsersForQuarter(compareYear, quarter) : [0, 0, 0];

    final double salesDelta = compareSales > 0 ? ((currentSales - compareSales) / compareSales) * 100 : (currentSales > 0 ? 100 : 0);
    final double usersDelta = compareUsers > 0 ? ((currentUsers - compareUsers) / compareUsers) * 100 : (currentUsers > 0 ? 100 : 0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AlpesColors.arenaCalida.withOpacity(.18)),
      ),
      child: Column(
        children: [
          // Encabezado del trimestre
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AlpesColors.oroGuatemalteco.withOpacity(.15), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: AlpesColors.oroGuatemalteco, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quarterName,
                        style: const TextStyle(
                          color: AlpesColors.cafeOscuro,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${monthNames[0]} - ${monthNames[2]}',
                        style: TextStyle(
                          color: AlpesColors.nogalMedio,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AlpesColors.exito.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 14, color: AlpesColors.exito),
                      const SizedBox(width: 4),
                      Text(
                        '${salesDelta >= 0 ? '+' : ''}${salesDelta.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: salesDelta >= 0 ? AlpesColors.exito : AlpesColors.rojoColonial,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tarjetas de resumen
          Row(
            children: [
              Expanded(
                child: _quarterMetricCard(
                  title: 'Ventas $_selectedYear',
                  value: _formatCompactMoney(currentSales),
                  delta: salesDelta,
                  isCurrent: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quarterMetricCard(
                  title: 'Ventas ${compareYear ?? 'N/A'}',
                  value: compareYear != null ? _formatCompactMoney(compareSales) : 'Sin dato',
                  delta: salesDelta,
                  isCurrent: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quarterMetricCard(
                  title: 'Usuarios $_selectedYear',
                  value: '$currentUsers',
                  delta: usersDelta,
                  isCurrent: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quarterMetricCard(
                  title: 'Usuarios ${compareYear ?? 'N/A'}',
                  value: compareYear != null ? '$compareUsers' : 'Sin dato',
                  delta: usersDelta,
                  isCurrent: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Gráfica mensual del trimestre
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Desglose mensual del trimestre',
            style: TextStyle(
              color: AlpesColors.cafeOscuro,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: AnimatedBuilder(
              animation: _chartsAnimation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _MonthlyQuarterPainter(
                    currentSales: currentMonthlySales,
                    previousSales: compareMonthlySales,
                    currentUsers: currentMonthlyUsers,
                    previousUsers: compareMonthlyUsers,
                    labels: monthNames,
                    progress: _chartsAnimation.value,
                    currentColor: const Color(0xFF0F7B5F),
                    compareColor: const Color(0xFF2F6FB2),
                    gridColor: AlpesColors.arenaCalida.withOpacity(.20),
                    textColor: AlpesColors.nogalMedio,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _legendDot(const Color(0xFF0F7B5F), '$_selectedYear'),
              if (compareYear != null)
                _legendDot(const Color(0xFF2F6FB2), '$compareYear'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quarterMetricCard({
    required String title,
    required String value,
    required double delta,
    required bool isCurrent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF0F7B5F).withOpacity(.08)
            : const Color(0xFF2F6FB2).withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isCurrent ? const Color(0xFF0F7B5F) : const Color(0xFF2F6FB2))
              .withOpacity(.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AlpesColors.nogalMedio,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isCurrent ? const Color(0xFF0F7B5F) : const Color(0xFF2F6FB2),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (delta != 0.0 && isCurrent && value != 'Sin dato')
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (delta >= 0.0 ? AlpesColors.exito : AlpesColors.rojoColonial)
                    .withOpacity(.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${delta >= 0.0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: delta >= 0.0 ? AlpesColors.exito : AlpesColors.rojoColonial,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AlpesColors.pergamino,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AlpesColors.arenaCalida.withOpacity(.45)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMonth,
          icon: const Icon(
            Icons.calendar_month_rounded,
            color: AlpesColors.cafeOscuro,
            size: 18,
          ),
          style: const TextStyle(
            color: AlpesColors.cafeOscuro,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          items: _monthOptions.map((entry) {
            return DropdownMenuItem<int>(
              value: entry.value,
              child: Text(entry.key),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMonth = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AlpesColors.pergamino,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AlpesColors.arenaCalida.withOpacity(.45)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AlpesColors.cafeOscuro,
          ),
          style: const TextStyle(
            color: AlpesColors.cafeOscuro,
            fontWeight: FontWeight.w700,
          ),
          items: _availableYears
              .map(
                (year) => DropdownMenuItem<int>(
                  value: year,
                  child: Text('$year'),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            final candidates = _comparisonYearsFor(value);
            setState(() {
              _selectedYear = value;
              if (candidates.isEmpty) {
                _compareYear = value - 1;
              } else if (_compareYear == null ||
                  _compareYear == value ||
                  !candidates.contains(_compareYear)) {
                _compareYear = candidates.first;
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildCompareYearSelector() {
    final candidates = _comparisonYearsFor(_selectedYear);
    final selectedValue =
        candidates.contains(_compareYear) ? _compareYear : candidates.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AlpesColors.pergamino,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AlpesColors.arenaCalida.withOpacity(.45)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedValue,
          icon: const Icon(
            Icons.compare_arrows_rounded,
            color: AlpesColors.cafeOscuro,
            size: 18,
          ),
          style: const TextStyle(
            color: AlpesColors.cafeOscuro,
            fontWeight: FontWeight.w700,
          ),
          items: candidates
              .map(
                (year) => DropdownMenuItem<int>(
                  value: year,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14),
                      const SizedBox(width: 6),
                      Text('$year'),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _compareYear = value);
          },
        ),
      ),
    );
  }

  Widget _buildChartModeChip(String label, _TrendChartMode mode) {
    final selected = _chartMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _chartMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AlpesColors.cafeOscuro : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AlpesColors.cafeOscuro
                : AlpesColors.arenaCalida.withOpacity(.35),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AlpesColors.cafeOscuro.withOpacity(.10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AlpesColors.cafeOscuro,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.22),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AlpesColors.nogalMedio,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _deltaChip(String label, bool positive) {
    final color = positive ? AlpesColors.exito : AlpesColors.rojoColonial;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _metricCapsule(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AlpesColors.arenaCalida.withOpacity(.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AlpesColors.nogalMedio,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AlpesColors.cafeOscuro,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoCharts() {
    final total =
        _conteoEstados.values.fold<int>(0, (sum, value) => sum + value);

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución general y composición por estado',
            style: TextStyle(
              color: AlpesColors.cafeOscuro,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              if (compact) {
                return Column(
                  children: [
                    SizedBox(
                      height: 320,
                      child: _buildChartCard('Gráfica pie general', false, total),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: _buildChartCard(
                        'Gráfica donut por estado',
                        true,
                        total,
                      ),
                    ),
                  ],
                );
              }
              return SizedBox(
                height: 320,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildChartCard('Gráfica pie general', false, total),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildChartCard(
                        'Gráfica donut por estado',
                        true,
                        total,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _conteoEstados.entries.map((entry) {
              final color = _estadoColor(entry.key);
              final percent = total == 0 ? 0 : (entry.value / total * 100);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withOpacity(.22)),
                ),
                child: Text(
                  '${entry.key}: ${entry.value} · ${percent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AlpesColors.cafeOscuro,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, bool donut, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AlpesColors.arenaCalida.withOpacity(.20)),
        boxShadow: [
          BoxShadow(
            color: AlpesColors.cafeOscuro.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AlpesColors.cafeOscuro,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedBuilder(
              animation: _chartsAnimation,
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final chartSize = math.min(
                      math.max(150, constraints.maxWidth * .34),
                      180,
                    ).toDouble();

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: chartSize,
                          height: chartSize,
                          child: CustomPaint(
                            painter: _EstadoChartPainter(
                              data: _conteoEstados,
                              progress: Curves.easeOutBack.transform(
                                _chartsAnimation.value.clamp(0.0, 1.0),
                              ),
                              holeFraction: donut ? .58 : 0,
                            ),
                            child: donut
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$total',
                                          style: const TextStyle(
                                            color: AlpesColors.cafeOscuro,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'órdenes',
                                          style: TextStyle(
                                            color: AlpesColors.nogalMedio,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.expand(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _conteoEstados.entries.map((entry) {
                              final color = _estadoColor(entry.key);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(.18),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          color: AlpesColors.cafeOscuro,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${entry.value}',
                                      style: const TextStyle(
                                        color: AlpesColors.nogalMedio,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventarioCard() {
    final items = _inventarioVigilancia;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos con riesgo operativo o necesidad de reposición',
            style: TextStyle(
              color: AlpesColors.cafeOscuro,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            _buildEmptyState(
              'No hay productos bajo el mínimo o en estado crítico.',
            )
          else
            ...items.map((item) {
              final stock = _toInt(
                _readValue(
                    item, const ['STOCK', 'stock', 'CANTIDAD', 'cantidad']),
              );
              final reservado = _toInt(
                _readValue(item, const ['STOCK_RESERVADO', 'stock_reservado']),
              );
              final minimo = _toInt(
                _readValue(item, const ['STOCK_MINIMO', 'stock_minimo']),
              );
              final riesgo = _ratioRiesgo(item).clamp(0, 1).toDouble();
              final disponible = math.max(stock - reservado, 0);
              final riskColor = riesgo >= .70
                  ? AlpesColors.rojoColonial
                  : riesgo >= .40
                      ? const Color(0xFFB7841B)
                      : AlpesColors.exito;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: riskColor.withOpacity(.18)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: riskColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _resolverProducto(item),
                                  style: const TextStyle(
                                    color: AlpesColors.cafeOscuro,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: riskColor.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  riesgo >= .7 ? 'Crítico' : 'Vigilancia',
                                  style: TextStyle(
                                    color: riskColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              _infoPill(
                                Icons.inventory_2_outlined,
                                'Stock',
                                '$stock',
                              ),
                              _infoPill(
                                Icons.bookmark_outline_rounded,
                                'Reservado',
                                '$reservado',
                              ),
                              _infoPill(
                                Icons.flag_outlined,
                                'Mínimo',
                                '$minimo',
                              ),
                              _infoPill(
                                Icons.layers_outlined,
                                'Disponible',
                                '$disponible',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: riesgo,
                              backgroundColor: AlpesColors.pergamino,
                              color: riskColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            minimo > 0
                                ? 'Cobertura actual: ${(stock / minimo * 100).clamp(0, 999).toStringAsFixed(0)}% del mínimo esperado.'
                                : 'Producto sin mínimo registrado. Se marca por stock crítico.',
                            style: const TextStyle(
                              color: AlpesColors.nogalMedio,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AlpesColors.arenaCalida.withOpacity(.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AlpesColors.nogalMedio),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: const TextStyle(
              color: AlpesColors.cafeOscuro,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltimasOrdenesCard() {
    final rows = _ultimasOrdenes;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimas 10 órdenes',
            style: TextStyle(
              color: AlpesColors.cafeOscuro,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            _buildEmptyState('No hay órdenes disponibles para mostrar.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final minTableWidth = math.max(constraints.maxWidth, 980.0);

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: minTableWidth),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFFF2ECE4),
                        ),
                        dataRowMinHeight: 58,
                        dataRowMaxHeight: 66,
                        horizontalMargin: 18,
                        columnSpacing: 70,
                        headingTextStyle: const TextStyle(
                          color: AlpesColors.cafeOscuro,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        columns: const [
                          DataColumn(label: Text('Orden')),
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Items')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Estado')),
                        ],
                        rows: rows.map((orden) {
                          final numero = (_readValue(
                                    orden,
                                    const [
                                      'NUM_ORDEN',
                                      'num_orden',
                                      'ORDEN_VENTA_ID',
                                      'orden_venta_id',
                                    ],
                                  ) ??
                                  '—')
                              .toString();
                          final fecha = _parseDate(
                            _readValue(
                              orden,
                              const ['FECHA_ORDEN', 'fecha_orden'],
                            ),
                          );
                          final total = _toDouble(
                            _readValue(orden, const ['TOTAL', 'total']),
                          );
                          final estado = _prettyEstado(_resolverEstado(orden));
                          final color = _estadoColor(estado);
                          final items = _itemsPorOrden(orden);

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  numero,
                                  style: const TextStyle(
                                    color: AlpesColors.cafeOscuro,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DataCell(Text(_formatDate(fecha))),
                              DataCell(Text('$items')),
                              DataCell(
                                Text(
                                  _formatCurrency(total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    estado,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AlpesColors.arenaCalida.withOpacity(.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AlpesColors.nogalMedio,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AlpesColors.arenaCalida.withOpacity(.16)),
        boxShadow: [
          BoxShadow(
            color: AlpesColors.cafeOscuro.withOpacity(.06),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _KpiData(this.title, this.value, this.icon, this.gradient);
}

class _SalesTrendPainter extends CustomPainter {
  final List<double> currentData;
  final List<double>? previousData;
  final List<String> labels;
  final double progress;
  final _TrendChartMode mode;
  final Color currentLineColor;
  final Color currentGlowColor;
  final Color compareLineColor;
  final Color compareGlowColor;
  final Color barCurrentColor;
  final Color barCompareColor;
  final Color gridColor;
  final Color textColor;
  final int? highlightedIndex;

  _SalesTrendPainter({
    required this.currentData,
    required this.previousData,
    required this.labels,
    required this.progress,
    required this.mode,
    required this.currentLineColor,
    required this.currentGlowColor,
    required this.compareLineColor,
    required this.compareGlowColor,
    required this.barCurrentColor,
    required this.barCompareColor,
    required this.gridColor,
    required this.textColor,
    required this.highlightedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double left = 8;
    const double right = 8;
    const double top = 12;
    const double bottom = 34;

    final chart = Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top - bottom,
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = chart.top + chart.height * (i / 4);
      canvas.drawLine(
        Offset(chart.left, y),
        Offset(chart.right, y),
        gridPaint,
      );
    }

    final double maxCurrent =
        currentData.isEmpty ? 0.0 : currentData.reduce(math.max).toDouble();
    final double maxPrevious = previousData == null || previousData!.isEmpty
        ? 0.0
        : previousData!.reduce(math.max).toDouble();
    final double maxValue = math.max(maxCurrent, maxPrevious).toDouble();
    final double safeMax = maxValue <= 0 ? 1.0 : maxValue;

    final spacing = chart.width / labels.length;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < labels.length; i++) {
      final x = chart.left + spacing * i + spacing / 2;
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: textColor,
          fontSize: 11.4,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout(maxWidth: spacing);
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chart.bottom + 8),
      );
    }

    switch (mode) {
      case _TrendChartMode.columnas:
        _drawBarsComparison(canvas, chart, safeMax, spacing);
        break;
      case _TrendChartMode.linea:
        if (previousData != null) {
          _drawCompareAsActiveUsers(
            canvas,
            chart,
            previousData!,
            safeMax,
            spacing,
          );
        }
        _drawCurrentLine(canvas, chart, safeMax, spacing);
        break;
      case _TrendChartMode.area:
        if (previousData != null) {
          _drawCompareAsActiveUsers(
            canvas,
            chart,
            previousData!,
            safeMax,
            spacing,
          );
        }
        _drawAreaSeries(canvas, chart, safeMax, spacing);
        break;
    }
  }

  void _drawBarsComparison(
    Canvas canvas,
    Rect chart,
    double maxValue,
    double spacing,
  ) {
    final groupWidth = spacing * .70;
    final barWidth = groupWidth / 2.5;

    for (int i = 0; i < currentData.length; i++) {
      final xCenter = chart.left + spacing * i + spacing / 2;

      if (previousData != null) {
        final prevHeight =
            (previousData![i] / maxValue) * chart.height * progress;
        final prevRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            xCenter - barWidth - 2,
            chart.bottom - prevHeight,
            barWidth,
            math.max(prevHeight, 2),
          ),
          const Radius.circular(10),
        );

        final prevPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              barCompareColor.withOpacity(.95),
              barCompareColor.withOpacity(.40),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(prevRect.outerRect);

        canvas.drawRRect(prevRect, prevPaint);
      }

      final currentHeight =
          (currentData[i] / maxValue) * chart.height * progress;
      final currentRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          xCenter + 2,
          chart.bottom - currentHeight,
          barWidth,
          math.max(currentHeight, 2),
        ),
        const Radius.circular(10),
      );

      final isHighlight = highlightedIndex == i;
      final currentPaint = Paint()
        ..shader = LinearGradient(
          colors: isHighlight
              ? [barCurrentColor, currentGlowColor]
              : [
                  barCurrentColor.withOpacity(.90),
                  currentGlowColor.withOpacity(.55),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(currentRect.outerRect);

      canvas.drawRRect(currentRect, currentPaint);

      if (isHighlight && currentData[i] > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: _compactValue(currentData[i]),
            style: TextStyle(
              color: barCurrentColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(
          canvas,
          Offset(
            xCenter - tp.width / 2,
            chart.bottom - currentHeight - 16,
          ),
        );
      }
    }
  }

  void _drawCompareAsActiveUsers(
    Canvas canvas,
    Rect chart,
    List<double> data,
    double maxValue,
    double spacing,
  ) {
    final points = <Offset>[];
    final allZero = data.every((e) => e == 0);

    for (int i = 0; i < data.length; i++) {
      final x = chart.left + spacing * i + spacing / 2;
      final y = allZero
          ? chart.bottom - 2
          : chart.bottom - ((data[i] / maxValue) * chart.height * progress);
      points.add(Offset(x, y));
    }

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    final glowPaint = Paint()
      ..color = compareGlowColor.withOpacity(.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _drawDashedPath(canvas, path, glowPaint);

    final paint = Paint()
      ..color = compareLineColor.withOpacity(allZero ? .78 : 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _drawDashedPath(canvas, path, paint);

    for (final point in points) {
      canvas.drawCircle(
        point,
        8,
        Paint()
          ..color = compareGlowColor.withOpacity(.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        point,
        4.2,
        Paint()..color = compareLineColor.withOpacity(allZero ? .78 : 1),
      );
      canvas.drawCircle(
        point,
        2.2,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawCurrentLine(
    Canvas canvas,
    Rect chart,
    double maxValue,
    double spacing,
  ) {
    final allZero = currentData.every((e) => e == 0);

    final path = Path();
    for (int i = 0; i < currentData.length; i++) {
      final x = chart.left + spacing * i + spacing / 2;
      final y = allZero
          ? chart.bottom - 2
          : chart.bottom -
              ((currentData[i] / maxValue) * chart.height * progress);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glowPaint = Paint()
      ..color = currentGlowColor.withOpacity(.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, glowPaint);

    final linePaint = Paint()
      ..color = currentLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < currentData.length; i++) {
      final x = chart.left + spacing * i + spacing / 2;
      final y = allZero
          ? chart.bottom - 2
          : chart.bottom -
              ((currentData[i] / maxValue) * chart.height * progress);

      canvas.drawCircle(
        Offset(x, y),
        7.5,
        Paint()
          ..color = currentGlowColor.withOpacity(.20)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        4.3,
        Paint()..color = currentLineColor,
      );
      canvas.drawCircle(
        Offset(x, y),
        2.1,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawAreaSeries(
    Canvas canvas,
    Rect chart,
    double maxValue,
    double spacing,
  ) {
    if (currentData.every((e) => e == 0)) {
      _drawCurrentLine(canvas, chart, maxValue, spacing);
      return;
    }

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < currentData.length; i++) {
      final x = chart.left + spacing * i + spacing / 2;
      final y = chart.bottom -
          ((currentData[i] / maxValue) * chart.height * progress);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chart.bottom);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(
      chart.left + spacing * (currentData.length - 1) + spacing / 2,
      chart.bottom,
    );
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          currentGlowColor.withOpacity(.34),
          currentGlowColor.withOpacity(.04),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chart);
    canvas.drawPath(fillPath, fillPaint);

    _drawCurrentLine(canvas, chart, maxValue, spacing);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      const dashLength = 10.0;
      const dashSpace = 6.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashLength + dashSpace;
      }
    }
  }

  String _compactValue(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _SalesTrendPainter oldDelegate) {
    return oldDelegate.currentData != currentData ||
        oldDelegate.previousData != previousData ||
        oldDelegate.progress != progress ||
        oldDelegate.mode != mode ||
        oldDelegate.highlightedIndex != highlightedIndex ||
        oldDelegate.currentLineColor != currentLineColor ||
        oldDelegate.compareLineColor != compareLineColor;
  }
}

class _UsersActivityPainter extends CustomPainter {
  final List<int> currentData;
  final List<int>? previousData;
  final double progress;
  final Color currentColor;
  final Color currentGlow;
  final Color previousColor;
  final Color previousGlow;
  final Color gridColor;

  _UsersActivityPainter({
    required this.currentData,
    required this.previousData,
    required this.progress,
    required this.currentColor,
    required this.currentGlow,
    required this.previousColor,
    required this.previousGlow,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 4.0;
    const right = 4.0;
    const top = 4.0;
    const bottom = 4.0;

    final chart = Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top - bottom,
    );

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= 2; i++) {
      final y = chart.top + chart.height * (i / 2);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }

    final maxCurrent = currentData.isEmpty
        ? 0
        : currentData.reduce((a, b) => a > b ? a : b);
    final maxPrevious =
        previousData == null || previousData!.isEmpty
            ? 0
            : previousData!.reduce((a, b) => a > b ? a : b);

    final maxValue = math.max(maxCurrent, maxPrevious).toDouble();
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final spacing = chart.width / math.max(currentData.length - 1, 1);

    if (previousData != null) {
      final previousPath = Path();
      for (int i = 0; i < previousData!.length; i++) {
        final x = chart.left + spacing * i;
        final y = chart.bottom -
            ((previousData![i] / safeMax) * chart.height * progress);
        if (i == 0) {
          previousPath.moveTo(x, y);
        } else {
          previousPath.lineTo(x, y);
        }
      }

      final previousGlowPaint = Paint()
        ..color = previousGlow.withOpacity(.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(previousPath, previousGlowPaint);

      final previousPaint = Paint()
        ..color = previousColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(previousPath, previousPaint);
    }

    final currentPath = Path();
    for (int i = 0; i < currentData.length; i++) {
      final x = chart.left + spacing * i;
      final y = chart.bottom -
          ((currentData[i] / safeMax) * chart.height * progress);
      if (i == 0) {
        currentPath.moveTo(x, y);
      } else {
        currentPath.lineTo(x, y);
      }
    }

    final currentGlowPaint = Paint()
      ..color = currentGlow.withOpacity(.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(currentPath, currentGlowPaint);

    final currentPaint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(currentPath, currentPaint);

    for (int i = 0; i < currentData.length; i++) {
      final x = chart.left + spacing * i;
      final y = chart.bottom -
          ((currentData[i] / safeMax) * chart.height * progress);
      canvas.drawCircle(
        Offset(x, y),
        5.5,
        Paint()..color = currentGlow.withOpacity(.20),
      );
      canvas.drawCircle(
        Offset(x, y),
        3.2,
        Paint()..color = currentColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UsersActivityPainter oldDelegate) {
    return oldDelegate.currentData != currentData ||
        oldDelegate.previousData != previousData ||
        oldDelegate.progress != progress;
  }
}

class _EstadoChartPainter extends CustomPainter {
  final Map<String, int> data;
  final double progress;
  final double holeFraction;

  _EstadoChartPainter({
    required this.data,
    required this.progress,
    required this.holeFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold<int>(0, (sum, item) => sum + item);
    if (total == 0) {
      final paint = Paint()
        ..color = AlpesColors.pergamino
        ..style = PaintingStyle.stroke
        ..strokeWidth = holeFraction > 0 ? size.width * .14 : 20;
      canvas.drawCircle(
        size.center(Offset.zero),
        size.shortestSide * .34,
        paint,
      );
      return;
    }

    const order = ['Pendiente', 'En proceso', 'Entregado', 'Cancelado'];
    final colors = {
      'Pendiente': const Color(0xFFB7841B),
      'En proceso': const Color(0xFF2F6FB2),
      'Entregado': const Color(0xFF2E7D32),
      'Cancelado': AlpesColors.rojoColonial,
    };

    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .38;
    final strokeWidth =
        holeFraction > 0 ? radius * (1 - holeFraction) : radius;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double start = -math.pi / 2;
    for (final key in order) {
      final value = data[key] ?? 0;
      if (value <= 0) continue;
      final sweep = (value / total) * math.pi * 2 * progress;

      final shadowPaint = Paint()
        ..color = colors[key]!.withOpacity(.12)
        ..style = holeFraction > 0 ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = strokeWidth + (holeFraction > 0 ? 6 : 0)
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, holeFraction == 0, shadowPaint);

      final paint = Paint()
        ..color = colors[key]!
        ..style = holeFraction > 0 ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, holeFraction == 0, paint);

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _EstadoChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.progress != progress ||
        oldDelegate.holeFraction != holeFraction;
  }
}

// Painter para la comparación por trimestre (vista anual)
class _QuarterComparisonPainter extends CustomPainter {
  final List<double> currentData;
  final List<double> previousData;
  final List<String> labels;
  final double progress;
  final Color currentColor;
  final Color compareColor;
  final Color gridColor;
  final Color textColor;
  final int highlightedQuarter;

  _QuarterComparisonPainter({
    required this.currentData,
    required this.previousData,
    required this.labels,
    required this.progress,
    required this.currentColor,
    required this.compareColor,
    required this.gridColor,
    required this.textColor,
    required this.highlightedQuarter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double left = 30;
    const double right = 12;
    const double top = 12;
    const double bottom = 28;

    final chart = Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top - bottom,
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = chart.top + chart.height * (i / 4);
      canvas.drawLine(
        Offset(chart.left, y),
        Offset(chart.right, y),
        gridPaint,
      );
    }

    final double maxCurrent =
        currentData.isEmpty ? 0.0 : currentData.reduce(math.max).toDouble();
    final double maxPrevious =
        previousData.isEmpty ? 0.0 : previousData.reduce(math.max).toDouble();
    final double maxValue = math.max(maxCurrent, maxPrevious).toDouble();
    final double safeMax = maxValue <= 0 ? 1.0 : maxValue;

    final spacing = chart.width / labels.length;
    final barWidth = spacing * 0.35;
    final groupSpacing = (spacing - barWidth * 2) / 3;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < labels.length; i++) {
      final x = chart.left + spacing * i + spacing / 2;
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout(maxWidth: spacing);
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chart.bottom + 6),
      );

      final isHighlighted = highlightedQuarter == (i + 1);

      // Barra del año comparado
      if (i < previousData.length) {
        final prevHeight = (previousData[i] / safeMax) * chart.height * progress;
        final prevRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - barWidth - groupSpacing,
            chart.bottom - prevHeight,
            barWidth,
            math.max(prevHeight, 2),
          ),
          const Radius.circular(6),
        );
        final prevPaint = Paint()..color = compareColor.withOpacity(0.85);
        canvas.drawRRect(prevRect, prevPaint);
      }

      // Barra del año seleccionado
      if (i < currentData.length) {
        final currHeight = (currentData[i] / safeMax) * chart.height * progress;
        final currRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + groupSpacing,
            chart.bottom - currHeight,
            barWidth,
            math.max(currHeight, 2),
          ),
          const Radius.circular(6),
        );

        final currPaint = Paint()
          ..shader = LinearGradient(
            colors: isHighlighted
                ? [currentColor, currentColor.withOpacity(0.7)]
                : [currentColor.withOpacity(0.85), currentColor.withOpacity(0.55)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(currRect.outerRect);

        canvas.drawRRect(currRect, currPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QuarterComparisonPainter oldDelegate) {
    return oldDelegate.currentData != currentData ||
        oldDelegate.previousData != previousData ||
        oldDelegate.progress != progress ||
        oldDelegate.highlightedQuarter != highlightedQuarter;
  }
}

// Nuevo painter para el desglose mensual del trimestre
class _MonthlyQuarterPainter extends CustomPainter {
  final List<double> currentSales;
  final List<double> previousSales;
  final List<int> currentUsers;
  final List<int> previousUsers;
  final List<String> labels;
  final double progress;
  final Color currentColor;
  final Color compareColor;
  final Color gridColor;
  final Color textColor;

  _MonthlyQuarterPainter({
    required this.currentSales,
    required this.previousSales,
    required this.currentUsers,
    required this.previousUsers,
    required this.labels,
    required this.progress,
    required this.currentColor,
    required this.compareColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double left = 30;
    const double right = 12;
    const double top = 12;
    const double bottom = 28;

    final chart = Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top - bottom,
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = chart.top + chart.height * (i / 4);
      canvas.drawLine(
        Offset(chart.left, y),
        Offset(chart.right, y),
        gridPaint,
      );
    }

    final double maxCurrentSales =
        currentSales.isEmpty ? 0.0 : currentSales.reduce(math.max).toDouble();
    final double maxPreviousSales =
        previousSales.isEmpty ? 0.0 : previousSales.reduce(math.max).toDouble();
    final double maxSales = math.max(maxCurrentSales, maxPreviousSales).toDouble();
    final double safeMax = maxSales <= 0 ? 1.0 : maxSales;

    final spacing = chart.width / labels.length;
    final barWidth = spacing * 0.35;
    final groupSpacing = (spacing - barWidth * 2) / 3;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < labels.length; i++) {
      final x = chart.left + spacing * i + spacing / 2;
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout(maxWidth: spacing);
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chart.bottom + 6),
      );

      // Barra del año comparado
      if (i < previousSales.length) {
        final prevHeight = (previousSales[i] / safeMax) * chart.height * progress;
        final prevRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - barWidth - groupSpacing,
            chart.bottom - prevHeight,
            barWidth,
            math.max(prevHeight, 2),
          ),
          const Radius.circular(6),
        );
        final prevPaint = Paint()..color = compareColor.withOpacity(0.85);
        canvas.drawRRect(prevRect, prevPaint);
      }

      // Barra del año seleccionado
      if (i < currentSales.length) {
        final currHeight = (currentSales[i] / safeMax) * chart.height * progress;
        final currRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + groupSpacing,
            chart.bottom - currHeight,
            barWidth,
            math.max(currHeight, 2),
          ),
          const Radius.circular(6),
        );

        final currPaint = Paint()
          ..shader = LinearGradient(
            colors: [currentColor.withOpacity(0.85), currentColor.withOpacity(0.55)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(currRect.outerRect);

        canvas.drawRRect(currRect, currPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyQuarterPainter oldDelegate) {
    return oldDelegate.currentSales != currentSales ||
        oldDelegate.previousSales != previousSales ||
        oldDelegate.progress != progress;
  }
}