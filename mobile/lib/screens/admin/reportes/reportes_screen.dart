import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../config/api_config.dart';
import '../../../config/theme.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

enum _TrendChartMode { columnas, linea, area }
enum _ReportOutputFormat { pdf, excel }
enum _ReportPeriodType { rangoMeses, trimestre, anual }

class _ReportesScreenState extends State<ReportesScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _ordenes = [];
  final List<Map<String, dynamic>> _detallesOrden = [];
  final List<Map<String, dynamic>> _estadosOrden = [];
  final List<Map<String, dynamic>> _clientes = [];
  final List<Map<String, dynamic>> _inventario = [];
  final List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _ultimasOrdenesCache = [];

  bool _loading = true;
  bool _recargandoUltimasOrdenes = false;
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
  bool _generandoReporte = false;

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
      _ultimasOrdenesCache = _computeUltimasOrdenes(_ordenes);
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
    if (normalized.isEmpty) return 'Pendiente';
    if (normalized.contains('entreg') ||
        normalized.contains('complet') ||
        normalized.contains('finaliz') ||
        normalized.contains('cerrad')) {
      return 'Entregado';
    }
    if (normalized.contains('cancel') ||
        normalized.contains('anulad') ||
        normalized.contains('rechaz')) {
      return 'Cancelado';
    }
    if (normalized.contains('proceso') ||
        normalized.contains('prepar') ||
        normalized.contains('despach') ||
        normalized.contains('camino') ||
        normalized.contains('curso')) {
      return 'En proceso';
    }
    if (normalized.contains('pend') ||
        normalized.contains('ingres') ||
        normalized.contains('nueva') ||
        normalized.contains('nuevo') ||
        normalized.contains('cread')) {
      return 'Pendiente';
    }
    return 'Pendiente';
  }

  String _resolverEstado(Map<String, dynamic> orden) {
    final observaciones = (_readValue(
              orden,
              const ['OBSERVACIONES', 'observaciones'],
            ) ??
            '')
        .toString()
        .trim();
    if (observaciones.isNotEmpty) {
      final pretty = _prettyEstado(observaciones);
      if (pretty != 'Pendiente' ||
          observaciones.toLowerCase().contains('pend')) {
        return observaciones;
      }
    }

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
          final descripcion = _readValue(
            estado,
            const ['DESCRIPCION', 'descripcion'],
          );
          final raw = (codigo ?? nombre ?? descripcion ?? '')
              .toString()
              .trim();
          if (raw.isNotEmpty) return raw;
        }
      }
    }

    final directo = (_readValue(
              orden,
              const ['ESTADO', 'estado', 'STATUS', 'status'],
            ) ??
            '')
        .toString()
        .trim();
    if (directo.isNotEmpty) return directo;

    return 'Pendiente';
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

  List<Map<String, dynamic>> _computeUltimasOrdenes(
    List<Map<String, dynamic>> source,
  ) {
    final copia = [...source];
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

  Future<void> _recargarUltimasOrdenes() async {
    if (_recargandoUltimasOrdenes) return;

    setState(() => _recargandoUltimasOrdenes = true);

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVentaDet}')),
        http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.estadoOrden}')),
      ]);

      final decoded = responses.map((response) {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('HTTP ${response.statusCode}');
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      }).toList();

      _cargarLista(_ordenes, decoded[0]['data']);
      _cargarLista(_detallesOrden, decoded[1]['data']);
      _cargarLista(_estadosOrden, decoded[2]['data']);

      if (!mounted) return;
      setState(() {
        _apiConectada = true;
        _error = null;
        _ultimasOrdenesCache = _computeUltimasOrdenes(_ordenes);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiConectada = false;
        _error = 'No se pudieron recargar las últimas órdenes.';
      });
    } finally {
      if (!mounted) return;
      setState(() => _recargandoUltimasOrdenes = false);
    }
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



  Future<void> _mostrarDialogoReporte() async {
    if (_loading || _generandoReporte) return;

    var periodType = _ReportPeriodType.rangoMeses;
    var format = _ReportOutputFormat.pdf;
    var year = _selectedYear;
    var startMonth = 1;
    var endMonth = DateTime.now().month;
    var quarter = 1;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final monthItems = List.generate(
              12,
              (index) => DropdownMenuItem<int>(
                value: index + 1,
                child: Text(_getMonthName(index)),
              ),
            );

            return BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                backgroundColor: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFCF8), Color(0xFFF1E3D0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(.28)),
                      boxShadow: [
                        BoxShadow(
                          color: AlpesColors.cafeOscuro.withOpacity(.22),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: AlpesColors.oroGuatemalteco.withOpacity(.22),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.chair_alt_rounded,
                                  color: AlpesColors.cafeOscuro,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Generar reporte administrativo',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AlpesColors.cafeOscuro,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Muebles de los Alpes',
                                style: TextStyle(
                                  color: AlpesColors.nogalMedio,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _dialogLabel('Tipo de periodo'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _reportChoiceChip(
                              label: 'Rango de meses',
                              selected: periodType == _ReportPeriodType.rangoMeses,
                              onTap: () => setDialogState(() => periodType = _ReportPeriodType.rangoMeses),
                            ),
                            _reportChoiceChip(
                              label: 'Trimestre',
                              selected: periodType == _ReportPeriodType.trimestre,
                              onTap: () => setDialogState(() => periodType = _ReportPeriodType.trimestre),
                            ),
                            _reportChoiceChip(
                              label: 'Anual',
                              selected: periodType == _ReportPeriodType.anual,
                              onTap: () => setDialogState(() => periodType = _ReportPeriodType.anual),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _dialogDropdown<int>(
                                label: 'Año',
                                value: year,
                                items: _availableYears
                                    .map((item) => DropdownMenuItem<int>(value: item, child: Text('$item')))
                                    .toList(),
                                onChanged: (value) => setDialogState(() => year = value ?? year),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (periodType == _ReportPeriodType.trimestre)
                              Expanded(
                                child: _dialogDropdown<int>(
                                  label: 'Trimestre',
                                  value: quarter,
                                  items: const [
                                    DropdownMenuItem(value: 1, child: Text('Q1 · Ene-Mar')),
                                    DropdownMenuItem(value: 2, child: Text('Q2 · Abr-Jun')),
                                    DropdownMenuItem(value: 3, child: Text('Q3 · Jul-Sep')),
                                    DropdownMenuItem(value: 4, child: Text('Q4 · Oct-Dic')),
                                  ],
                                  onChanged: (value) => setDialogState(() => quarter = value ?? quarter),
                                ),
                              ),
                          ],
                        ),
                        if (periodType == _ReportPeriodType.rangoMeses) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _dialogDropdown<int>(
                                  label: 'Mes inicial',
                                  value: startMonth,
                                  items: monthItems,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      startMonth = value ?? startMonth;
                                      if (startMonth > endMonth) endMonth = startMonth;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _dialogDropdown<int>(
                                  label: 'Mes final',
                                  value: endMonth,
                                  items: monthItems,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      endMonth = value ?? endMonth;
                                      if (endMonth < startMonth) startMonth = endMonth;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        _dialogLabel('Formato'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _reportChoiceChip(
                                label: 'PDF profesional',
                                icon: Icons.picture_as_pdf_rounded,
                                selected: format == _ReportOutputFormat.pdf,
                                onTap: () => setDialogState(() => format = _ReportOutputFormat.pdf),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _reportChoiceChip(
                                label: 'Excel editable',
                                icon: Icons.table_chart_rounded,
                                selected: format == _ReportOutputFormat.excel,
                                onTap: () => setDialogState(() => format = _ReportOutputFormat.excel),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AlpesColors.cafeOscuro,
                                  side: BorderSide(color: AlpesColors.arenaCalida.withOpacity(.6)),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  Navigator.of(dialogContext).pop();
                                  await _generarReporte(
                                    periodType: periodType,
                                    format: format,
                                    year: year,
                                    startMonth: startMonth,
                                    endMonth: endMonth,
                                    quarter: quarter,
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AlpesColors.cafeOscuro,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.download_rounded, size: 18),
                                label: const Text('Generar', style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dialogLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AlpesColors.cafeOscuro,
        fontWeight: FontWeight.w900,
        fontSize: 13,
      ),
    );
  }

  Widget _dialogDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dialogLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AlpesColors.arenaCalida.withOpacity(.35)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AlpesColors.cafeOscuro),
              style: const TextStyle(color: AlpesColors.cafeOscuro, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reportChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AlpesColors.cafeOscuro : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AlpesColors.cafeOscuro : AlpesColors.arenaCalida.withOpacity(.42),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : AlpesColors.cafeOscuro),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AlpesColors.cafeOscuro,
                  fontSize: 12.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generarReporte({
    required _ReportPeriodType periodType,
    required _ReportOutputFormat format,
    required int year,
    required int startMonth,
    required int endMonth,
    required int quarter,
  }) async {
    setState(() => _generandoReporte = true);
    try {
      final range = _ReportRange.fromSelection(
        periodType: periodType,
        year: year,
        startMonth: startMonth,
        endMonth: endMonth,
        quarter: quarter,
        getMonthName: _getMonthName,
        getQuarterName: _getQuarterName,
      );
      final data = _buildReportData(range);

      if (format == _ReportOutputFormat.pdf) {
        final bytes = await _crearPdfReporte(data);
        await FileSaver.instance.saveFile(
          name: 'reporte_muebles_de_los_alpes_${range.fileSuffix}',
          bytes: bytes,
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
      } else {
        final bytes = _crearExcelReporte(data);
        await FileSaver.instance.saveFile(
          name: 'reporte_muebles_de_los_alpes_${range.fileSuffix}',
          bytes: bytes,
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(format == _ReportOutputFormat.pdf
              ? 'PDF generado correctamente.'
              : 'Excel generado correctamente.'),
          backgroundColor: AlpesColors.exito,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar el reporte: $e'),
          backgroundColor: AlpesColors.rojoColonial,
        ),
      );
    } finally {
      if (mounted) setState(() => _generandoReporte = false);
    }
  }

  _ReportData _buildReportData(_ReportRange range) {
    final ordersInRange = _ordenes.where((orden) {
      final fecha = _parseDate(_readValue(orden, const ['FECHA_ORDEN', 'fecha_orden']));
      if (fecha == null) return false;
      return fecha.year == range.year &&
          fecha.month >= range.startMonth &&
          fecha.month <= range.endMonth;
    }).toList()
      ..sort((a, b) {
        final fechaA = _parseDate(_readValue(a, const ['FECHA_ORDEN', 'fecha_orden'])) ?? DateTime(1900);
        final fechaB = _parseDate(_readValue(b, const ['FECHA_ORDEN', 'fecha_orden'])) ?? DateTime(1900);
        return fechaA.compareTo(fechaB);
      });

    final orderIds = ordersInRange.map(_orderId).where((id) => id.isNotEmpty).toSet();
    final detailsByOrder = <String, List<Map<String, dynamic>>>{};

    for (final detalle in _detallesOrden) {
      final orderId = (_readValue(detalle, const ['ORDEN_VENTA_ID', 'orden_venta_id']) ?? '').toString();
      if (!orderIds.contains(orderId)) continue;
      detailsByOrder.putIfAbsent(orderId, () => <Map<String, dynamic>>[]).add(detalle);
    }

    final monthlyProductMap = <String, _ProductMonthlyReportRow>{};
    int items = 0;

    for (final orden in ordersInRange) {
      final orderId = _orderId(orden);
      final fecha = _parseDate(_readValue(orden, const ['FECHA_ORDEN', 'fecha_orden']));
      if (fecha == null) continue;

      final orderDetails = detailsByOrder[orderId] ?? const <Map<String, dynamic>>[];
      final orderTotal = _orderTotal(orden);
      final rawTotals = <Map<String, dynamic>, double>{};
      int orderQty = 0;
      double rawTotalSum = 0;

      for (final detalle in orderDetails) {
        final quantity = _toInt(_readValue(detalle, const ['CANTIDAD', 'cantidad']));
        final price = _toDouble(_readValue(detalle, const ['PRECIO_UNITARIO', 'precio_unitario', 'PRECIO', 'precio', 'VALOR_UNITARIO', 'valor_unitario']));
        final explicitSubtotal = _readValue(detalle, const ['SUBTOTAL', 'subtotal', 'TOTAL', 'total', 'MONTO', 'monto', 'IMPORTE', 'importe']);
        final rawSubtotal = explicitSubtotal == null ? quantity * price : _toDouble(explicitSubtotal);
        rawTotals[detalle] = rawSubtotal;
        rawTotalSum += rawSubtotal;
        orderQty += quantity;
      }

      for (final detalle in orderDetails) {
        final productoId = _detailProductId(detalle);
        final producto = _productNameById(productoId);
        final quantity = _toInt(_readValue(detalle, const ['CANTIDAD', 'cantidad']));
        items += quantity;

        double allocatedTotal;
        final rawSubtotal = rawTotals[detalle] ?? 0;
        if (rawTotalSum > 0) {
          allocatedTotal = orderTotal > 0 ? orderTotal * (rawSubtotal / rawTotalSum) : rawSubtotal;
        } else if (orderQty > 0) {
          allocatedTotal = orderTotal * (quantity / orderQty);
        } else {
          allocatedTotal = 0;
        }

        final key = '$productoId|${fecha.month}';
        final row = monthlyProductMap.putIfAbsent(
          key,
          () => _ProductMonthlyReportRow(
            month: fecha.month,
            product: producto,
            productId: productoId,
          ),
        );
        row.quantity += quantity;
        row.total += allocatedTotal;
      }
    }

    final rows = monthlyProductMap.values.toList()
      ..sort((a, b) {
        final byMonth = a.month.compareTo(b.month);
        return byMonth != 0 ? byMonth : a.product.compareTo(b.product);
      });

    final totalSales = ordersInRange.fold<double>(0, (sum, orden) => sum + _orderTotal(orden));
    final cancelled = ordersInRange.where((orden) => _prettyEstado(_resolverEstado(orden)) == 'Cancelado').length;
    final delivered = ordersInRange.where((orden) => _prettyEstado(_resolverEstado(orden)) == 'Entregado').length;
    final clients = ordersInRange
        .map(_orderClientName)
        .where((name) => name.trim().isNotEmpty && name != 'Cliente sin identificar')
        .toSet()
        .length;

    return _ReportData(
      range: range,
      generatedAt: DateTime.now(),
      totalSales: totalSales,
      totalOrders: ordersInRange.length,
      totalClients: clients,
      cancelledOrders: cancelled,
      deliveredOrders: delivered,
      itemsSold: items,
      averageTicket: ordersInRange.isEmpty ? 0 : totalSales / ordersInRange.length,
      monthlyProducts: rows,
      orders: ordersInRange,
    );
  }

  String _orderId(Map<String, dynamic> orden) {
    return (_readValue(orden, const ['ORDEN_VENTA_ID', 'orden_venta_id', 'ID', 'id']) ?? '').toString();
  }

  String _orderNumber(Map<String, dynamic> orden) {
    return (_readValue(orden, const ['NUM_ORDEN', 'num_orden', 'NUMERO_ORDEN', 'numero_orden', 'ORDEN_VENTA_ID', 'orden_venta_id']) ?? '—').toString();
  }

  double _orderTotal(Map<String, dynamic> orden) {
    return _toDouble(_readValue(orden, const ['TOTAL', 'total', 'MONTO_TOTAL', 'monto_total', 'IMPORTE_TOTAL', 'importe_total']));
  }

  String _orderClientName(Map<String, dynamic> orden) {
    final direct = (_readValue(orden, const [
              'CLIENTE_NOMBRE',
              'cliente_nombre',
              'NOMBRE_CLIENTE',
              'nombre_cliente',
              'CLIENTE',
              'cliente',
            ]) ??
            '')
        .toString()
        .trim();
    if (direct.isNotEmpty) return _cleanClientDisplayName(direct);

    final id = _orderClientId(orden);
    if (id == null || id.isEmpty) return 'Cliente sin identificar';
    return _cleanClientDisplayName(_clientNameById(id));
  }

  String _cleanClientDisplayName(String value) {
    var clean = value.trim();
    if (clean.isEmpty) return clean;

    final separators = [
      RegExp(r'\s*[·|-]\s*NIT\s*[:#-]?\s*.+$', caseSensitive: false),
      RegExp(r'\s*NIT\s*[:#-]?\s*.+$', caseSensitive: false),
    ];

    for (final pattern in separators) {
      clean = clean.replaceAll(pattern, '').trim();
    }

    clean = clean.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return clean.isEmpty ? value.trim() : clean;
  }

  String _clientNameById(String clientId) {
    for (final cliente in _clientes) {
      final currentId = _readValue(cliente, const ['CLIENTE_ID', 'cliente_id', 'CLI_ID', 'cli_id', 'ID', 'id']);
      if ('$currentId' != clientId) continue;

      final nombre = (_readValue(cliente, const ['NOMBRE', 'nombre', 'NOMBRES', 'nombres', 'RAZON_SOCIAL', 'razon_social']) ?? '').toString().trim();
      final apellido = (_readValue(cliente, const ['APELLIDO', 'apellido', 'APELLIDOS', 'apellidos']) ?? '').toString().trim();
      final empresa = (_readValue(cliente, const ['EMPRESA', 'empresa']) ?? '').toString().trim();
      final fullName = [nombre, apellido].where((part) => part.isNotEmpty).join(' ').trim();
      if (fullName.isNotEmpty) return fullName;
      if (empresa.isNotEmpty) return empresa;
    }
    return 'Cliente #$clientId';
  }


  String _detailProductId(Map<String, dynamic> detalle) {
    final direct = _readValue(detalle, const [
      'PRODUCTO_ID',
      'producto_id',
      'PROD_ID',
      'prod_id',
      'ID_PRODUCTO',
      'id_producto',
    ]);
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString().trim();
    }

    final inventoryId = _readValue(detalle, const [
      'INVENTARIO_PRODUCTO_ID',
      'inventario_producto_id',
      'INVENTARIO_ID',
      'inventario_id',
    ]);
    if (inventoryId != null) {
      for (final item in _inventario) {
        final currentInventoryId = _readValue(item, const [
          'INVENTARIO_PRODUCTO_ID',
          'inventario_producto_id',
          'INVENTARIO_ID',
          'inventario_id',
          'ID',
          'id',
        ]);
        if ('$currentInventoryId' == '$inventoryId') {
          final productoId = _readValue(item, const ['PRODUCTO_ID', 'producto_id']);
          if (productoId != null && productoId.toString().trim().isNotEmpty) {
            return productoId.toString().trim();
          }
        }
      }
      return inventoryId.toString().trim();
    }

    final nombreDirecto = _readValue(detalle, const [
      'PRODUCTO',
      'producto',
      'NOMBRE_PRODUCTO',
      'nombre_producto',
    ]);
    if (nombreDirecto != null && nombreDirecto.toString().trim().isNotEmpty) {
      return nombreDirecto.toString().trim();
    }

    return 'SIN_REFERENCIA';
  }

  String _productNameById(String productId) {
    final cleanId = productId.trim();
    if (cleanId.isEmpty || cleanId == 'SIN_REFERENCIA') {
      return 'Producto sin referencia';
    }

    for (final producto in _productos) {
      final currentId = _readValue(producto, const [
        'PRODUCTO_ID',
        'producto_id',
        'PROD_ID',
        'prod_id',
        'ID',
        'id',
      ]);
      if ('$currentId' != cleanId) continue;

      final nombre = (_readValue(producto, const [
                'NOMBRE',
                'nombre',
                'NOMBRE_PRODUCTO',
                'nombre_producto',
                'DESCRIPCION',
                'descripcion',
              ]) ??
              '')
          .toString()
          .trim();
      final referencia = (_readValue(producto, const [
                'REFERENCIA',
                'referencia',
                'CODIGO',
                'codigo',
                'SKU',
                'sku',
              ]) ??
              '')
          .toString()
          .trim();

      if (nombre.isNotEmpty && referencia.isNotEmpty) return '$nombre · $referencia';
      if (nombre.isNotEmpty) return nombre;
      if (referencia.isNotEmpty) return 'Ref. $referencia';
    }

    for (final item in _inventario) {
      final currentId = _readValue(item, const ['PRODUCTO_ID', 'producto_id']);
      if ('$currentId' == cleanId) return _resolverProducto(item);
    }

    return cleanId == 'SIN_REFERENCIA' ? 'Producto sin referencia' : 'Producto #$cleanId';
  }


  Uint8List _crearExcelReporte(_ReportData data) {
    final ventasPorMes = <int, double>{};
    final ordenesPorMes = <int, int>{};
    final itemsPorMes = <int, int>{};

    for (int month = data.range.startMonth; month <= data.range.endMonth; month++) {
      ventasPorMes[month] = 0;
      ordenesPorMes[month] = 0;
      itemsPorMes[month] = 0;
    }

    for (final orden in data.orders) {
      final fecha = _parseDate(_readValue(orden, const ['FECHA_ORDEN', 'fecha_orden']));
      if (fecha == null) continue;
      final total = _orderTotal(orden);
      ventasPorMes[fecha.month] = (ventasPorMes[fecha.month] ?? 0) + total;
      ordenesPorMes[fecha.month] = (ordenesPorMes[fecha.month] ?? 0) + 1;
    }

    final productoTotales = <String, _ProductMonthlyReportRow>{};
    for (final row in data.monthlyProducts) {
      itemsPorMes[row.month] = (itemsPorMes[row.month] ?? 0) + row.quantity;
      final item = productoTotales.putIfAbsent(
        row.productId,
        () => _ProductMonthlyReportRow(month: 0, product: row.product, productId: row.productId),
      );
      item.quantity += row.quantity;
      item.total += row.total;
    }

    final rankingProductos = productoTotales.values.toList()
      ..sort((a, b) {
        final bySales = b.total.compareTo(a.total);
        if (bySales != 0) return bySales;
        return b.quantity.compareTo(a.quantity);
      });

    final sortedOrders = [...data.orders]..sort((a, b) {
      final fechaA = _parseDate(_readValue(a, const ['FECHA_ORDEN', 'fecha_orden'])) ?? DateTime(1900);
      final fechaB = _parseDate(_readValue(b, const ['FECHA_ORDEN', 'fecha_orden'])) ?? DateTime(1900);
      return fechaB.compareTo(fechaA);
    });

    String xml(String value) => value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    String colName(int index) {
      var n = index + 1;
      final buffer = StringBuffer();
      while (n > 0) {
        final rem = (n - 1) % 26;
        buffer.writeCharCode(65 + rem);
        n = (n - rem - 1) ~/ 26;
      }
      return buffer.toString().split('').reversed.join();
    }

    String cellRef(int row, int col) => '${colName(col)}$row';

    String textCell(int row, int col, String value, {int style = 0}) {
      return '<c r="${cellRef(row, col)}" s="$style" t="inlineStr"><is><t>${xml(value)}</t></is></c>';
    }

    String numCell(int row, int col, num value, {int style = 0}) {
      final clean = value.isFinite ? value.toStringAsFixed(value is int ? 0 : 2) : '0';
      return '<c r="${cellRef(row, col)}" s="$style"><v>$clean</v></c>';
    }

    String rowXml(int row, List<String> cells, {double? height}) {
      final h = height == null ? '' : ' ht="$height" customHeight="1"';
      return '<row r="$row"$h>${cells.join()}</row>';
    }

    String money(double value) => _formatCurrency(value);
    final generatedDate = _formatDate(data.generatedAt);
    final months = [for (int m = data.range.startMonth; m <= data.range.endMonth; m++) m];

    String worksheetXml({
      required List<String> rows,
      required int maxRow,
      required int maxCol,
      List<String> merges = const [],
      String? drawingRelId,
      List<num>? colWidths,
    }) {
      final widths = colWidths ?? List<double>.filled(maxCol, 16);
      final cols = StringBuffer('<cols>');
      for (int i = 0; i < widths.length; i++) {
        cols.write('<col min="${i + 1}" max="${i + 1}" width="${widths[i]}" customWidth="1"/>');
      }
      cols.write('</cols>');

      final mergeXml = merges.isEmpty
          ? ''
          : '<mergeCells count="${merges.length}">${merges.map((e) => '<mergeCell ref="$e"/>').join()}</mergeCells>';
      final drawingXml = drawingRelId == null ? '' : '<drawing r:id="$drawingRelId"/>';

      return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <dimension ref="A1:${colName(maxCol - 1)}$maxRow"/>
  <sheetViews><sheetView showGridLines="0" workbookViewId="0"/></sheetViews>
  <sheetFormatPr defaultRowHeight="18"/>
  $cols
  <sheetData>${rows.join()}</sheetData>
  $mergeXml
  <pageMargins left="0.35" right="0.35" top="0.5" bottom="0.5" header="0.2" footer="0.2"/>
  $drawingXml
</worksheet>''';
    }

    List<String> titleRows(String title, String subtitle) {
      return [
        rowXml(1, [textCell(1, 0, 'MUEBLES DE LOS ALPES', style: 1)], height: 28),
        rowXml(2, [textCell(2, 0, title, style: 2)], height: 22),
        rowXml(3, [textCell(3, 0, subtitle, style: 3)], height: 20),
        rowXml(5, [
          textCell(5, 0, 'Periodo', style: 4),
          textCell(5, 1, data.range.label, style: 8),
          textCell(5, 3, 'Generado', style: 4),
          textCell(5, 4, generatedDate, style: 8),
        ]),
      ];
    }

    String sectionRow(int row, String title) => rowXml(row, [textCell(row, 0, title, style: 11)], height: 23);

    List<String> headerCells(int row, List<String> headers) => [
          for (int c = 0; c < headers.length; c++) textCell(row, c, headers[c], style: 6),
        ];

    final dashRows = <String>[];
    final dashMerges = <String>['A1:H1', 'A2:H2', 'A3:H3', 'A7:H7'];
    dashRows.addAll(titleRows('REPORTE EJECUTIVO', 'Dashboard profesional con datos reales, KPIs y lectura comercial'));
    dashRows.add(sectionRow(7, 'PANEL EJECUTIVO DEL PERIODO'));

    final kpis = [
      ['Ventas totales', money(data.totalSales), 'Ingreso comercial'],
      ['Órdenes', '${data.totalOrders}', 'Operaciones registradas'],
      ['Ticket promedio', money(data.averageTicket), 'Promedio por orden'],
      ['Clientes únicos', '${data.totalClients}', 'Clientes atendidos'],
      ['Items vendidos', '${data.itemsSold}', 'Unidades vendidas'],
      ['Entregadas', '${data.deliveredOrders}', 'Órdenes cerradas'],
      ['Canceladas', '${data.cancelledOrders}', 'No concretadas'],
      ['Productos vendidos', '${rankingProductos.length}', 'Referencias con venta'],
    ];

    for (int i = 0; i < kpis.length; i++) {
      final baseRow = 9 + (i ~/ 4) * 4;
      final col = (i % 4) * 2;
      dashMerges.addAll([
        '${cellRef(baseRow, col)}:${cellRef(baseRow, col + 1)}',
        '${cellRef(baseRow + 1, col)}:${cellRef(baseRow + 1, col + 1)}',
        '${cellRef(baseRow + 2, col)}:${cellRef(baseRow + 2, col + 1)}',
      ]);
    }

    for (int r = 9; r <= 15; r++) {
      final cells = <String>[];
      for (int i = 0; i < 4; i++) {
        final idx = (r < 13 ? 0 : 4) + i;
        final col = i * 2;
        if (r == 9 || r == 13) {
          cells.add(textCell(r, col, kpis[idx][0], style: 12));
        } else if (r == 10 || r == 14) {
          cells.add(textCell(r, col, kpis[idx][1], style: 13));
        } else if (r == 11 || r == 15) {
          cells.add(textCell(r, col, kpis[idx][2], style: 14));
        }
      }
      dashRows.add(rowXml(r, cells, height: (r == 10 || r == 14) ? 25 : 20));
    }

    dashMerges.add('A18:H18');
    dashRows.add(sectionRow(18, 'TENDENCIA MENSUAL DE VENTAS'));
    dashRows.add(rowXml(19, headerCells(19, ['Mes', 'Ventas', 'Órdenes', 'Items', 'Ticket', '% total', 'Lectura', '']), height: 21));
    int dashRow = 20;
    for (final month in months) {
      final sales = ventasPorMes[month] ?? 0;
      final orders = ordenesPorMes[month] ?? 0;
      final items = itemsPorMes[month] ?? 0;
      dashRows.add(rowXml(dashRow, [
        textCell(dashRow, 0, _getMonthName(month - 1), style: 8),
        numCell(dashRow, 1, sales, style: 5),
        numCell(dashRow, 2, orders, style: 9),
        numCell(dashRow, 3, items, style: 9),
        numCell(dashRow, 4, orders == 0 ? 0 : sales / orders, style: 5),
        numCell(dashRow, 5, data.totalSales <= 0 ? 0 : sales / data.totalSales, style: 10),
        textCell(dashRow, 6, sales > 0 ? 'Mes con movimiento' : 'Sin ventas registradas', style: 8),
      ], height: 22));
      dashRow++;
    }

    dashMerges.add('A${dashRow + 2}:H${dashRow + 2}');
    dashRows.add(sectionRow(dashRow + 2, 'ÓRDENES RECIENTES DEL PERIODO'));
    dashRows.add(rowXml(dashRow + 3, headerCells(dashRow + 3, ['Orden', 'Fecha', 'Cliente', 'Items', 'Total', 'Estado', '', '']), height: 21));
    for (int i = 0; i < math.min(8, sortedOrders.length); i++) {
      final orden = sortedOrders[i];
      final r = dashRow + 4 + i;
      dashRows.add(rowXml(r, [
        textCell(r, 0, _orderNumber(orden), style: 8),
        textCell(r, 1, _formatDate(_parseDate(_readValue(orden, const ['FECHA_ORDEN', 'fecha_orden']))), style: 9),
        textCell(r, 2, _orderClientName(orden), style: 8),
        numCell(r, 3, _itemsPorOrden(orden), style: 9),
        numCell(r, 4, _orderTotal(orden), style: 5),
        textCell(r, 5, _prettyEstado(_resolverEstado(orden)), style: 9),
      ], height: 23));
    }

    final dashboardXml = worksheetXml(
      rows: dashRows,
      maxRow: dashRow + 13,
      maxCol: 8,
      merges: dashMerges,
      colWidths: [18, 18, 28, 13, 18, 12, 26, 14],
    );

    final chartRows = <String>[];
    final chartMerges = <String>['A1:K1', 'A2:K2', 'A3:K3', 'A7:K7', 'A10:E10', 'G10:K10'];
    chartRows.addAll(titleRows('GRÁFICOS REALES DE EXCEL', 'Gráficos nativos vinculados a datos reales del periodo'));
    chartRows.add(sectionRow(7, 'VISUALIZACIÓN COMERCIAL DEL PERIODO'));
    chartRows.add(rowXml(10, [
      textCell(10, 0, 'Gráfico 1: ventas mensuales', style: 12),
      textCell(10, 6, 'Gráfico 2: ranking de productos por ventas', style: 12),
    ], height: 22));

    final monthlyStart = 25;
    final rankStart = 25;
    final maxChartRows = math.max(months.length, math.min(8, rankingProductos.length));

    chartRows.add(rowXml(monthlyStart, [
      textCell(monthlyStart, 0, 'Mes', style: 6),
      textCell(monthlyStart, 1, 'Ventas', style: 6),
      textCell(monthlyStart, 2, 'Órdenes', style: 6),
      textCell(monthlyStart, 3, 'Items', style: 6),
      textCell(monthlyStart, 4, 'Ticket', style: 6),
      textCell(monthlyStart, 5, '% total', style: 6),
      textCell(monthlyStart, 7, 'Producto', style: 6),
      textCell(monthlyStart, 8, 'Ventas', style: 6),
      textCell(monthlyStart, 9, 'Cantidad', style: 6),
      textCell(monthlyStart, 10, '% total', style: 6),
    ], height: 21));

    for (int i = 0; i < maxChartRows; i++) {
      final r = monthlyStart + 1 + i;
      final cells = <String>[];

      if (i < months.length) {
        final month = months[i];
        final sales = ventasPorMes[month] ?? 0;
        final orders = ordenesPorMes[month] ?? 0;
        cells.addAll([
          textCell(r, 0, _getMonthName(month - 1), style: 8),
          numCell(r, 1, sales, style: 5),
          numCell(r, 2, orders, style: 9),
          numCell(r, 3, itemsPorMes[month] ?? 0, style: 9),
          numCell(r, 4, orders == 0 ? 0 : sales / orders, style: 5),
          numCell(r, 5, data.totalSales <= 0 ? 0 : sales / data.totalSales, style: 10),
        ]);
      }

      if (i < math.min(8, rankingProductos.length)) {
        final item = rankingProductos[i];
        cells.addAll([
          textCell(r, 7, item.product, style: 8),
          numCell(r, 8, item.total, style: 5),
          numCell(r, 9, item.quantity, style: 9),
          numCell(r, 10, data.totalSales <= 0 ? 0 : item.total / data.totalSales, style: 10),
        ]);
      }

      chartRows.add(rowXml(r, cells, height: 24));
    }

    final graficosXml = worksheetXml(
      rows: chartRows,
      maxRow: monthlyStart + maxChartRows + 4,
      maxCol: 11,
      merges: chartMerges,
      colWidths: [16, 16, 12, 12, 16, 12, 4, 42, 16, 12, 12],
    );

    final detailRows = <String>[];
    final detailMerges = <String>['A1:I1', 'A2:I2', 'A3:I3'];
    detailRows.addAll(titleRows('DETALLE MENSUAL POR PRODUCTO', 'Ventas distribuidas desde el total real de cada orden'));
    detailRows.add(rowXml(7, headerCells(7, ['Año', 'Mes #', 'Mes', 'ID producto', 'Producto', 'Cantidad', 'Ventas', '% total', 'Ticket estimado']), height: 21));
    for (int i = 0; i < data.monthlyProducts.length; i++) {
      final item = data.monthlyProducts[i];
      final r = 8 + i;
      detailRows.add(rowXml(r, [
        numCell(r, 0, data.range.year, style: 9),
        numCell(r, 1, item.month, style: 9),
        textCell(r, 2, _getMonthName(item.month - 1), style: 8),
        textCell(r, 3, item.productId, style: 8),
        textCell(r, 4, item.product, style: 8),
        numCell(r, 5, item.quantity, style: 9),
        numCell(r, 6, item.total, style: 5),
        numCell(r, 7, data.totalSales <= 0 ? 0 : item.total / data.totalSales, style: 10),
        numCell(r, 8, item.quantity == 0 ? 0 : item.total / item.quantity, style: 5),
      ], height: 23));
    }
    final detalleXml = worksheetXml(
      rows: detailRows,
      maxRow: math.max(10, data.monthlyProducts.length + 9),
      maxCol: 9,
      merges: detailMerges,
      colWidths: [12, 10, 16, 18, 52, 12, 16, 12, 16],
    );

    final rankingRows = <String>[];
    final rankingMerges = <String>['A1:G1', 'A2:G2', 'A3:G3'];
    rankingRows.addAll(titleRows('RANKING DE PRODUCTOS', 'Productos ordenados por mayor contribución comercial'));
    rankingRows.add(rowXml(7, headerCells(7, ['#', 'ID producto', 'Producto', 'Cantidad', 'Ventas', '% total', 'Ticket estimado']), height: 21));
    for (int i = 0; i < rankingProductos.length; i++) {
      final item = rankingProductos[i];
      final r = 8 + i;
      rankingRows.add(rowXml(r, [
        numCell(r, 0, i + 1, style: 9),
        textCell(r, 1, item.productId, style: 8),
        textCell(r, 2, item.product, style: 8),
        numCell(r, 3, item.quantity, style: 9),
        numCell(r, 4, item.total, style: 5),
        numCell(r, 5, data.totalSales <= 0 ? 0 : item.total / data.totalSales, style: 10),
        numCell(r, 6, item.quantity == 0 ? 0 : item.total / item.quantity, style: 5),
      ], height: 23));
    }
    final rankingXml = worksheetXml(
      rows: rankingRows,
      maxRow: math.max(10, rankingProductos.length + 9),
      maxCol: 7,
      merges: rankingMerges,
      colWidths: [8, 18, 54, 12, 16, 12, 16],
    );

    final orderRows = <String>[];
    final orderMerges = <String>['A1:G1', 'A2:G2', 'A3:G3'];
    orderRows.addAll(titleRows('ÓRDENES DEL PERIODO', 'Listado completo de órdenes incluidas en el reporte'));
    orderRows.add(rowXml(7, headerCells(7, ['Orden', 'Fecha', 'Cliente', 'Items', 'Total', 'Estado', 'Lectura']), height: 21));
    for (int i = 0; i < sortedOrders.length; i++) {
      final orden = sortedOrders[i];
      final r = 8 + i;
      final estado = _prettyEstado(_resolverEstado(orden));
      orderRows.add(rowXml(r, [
        textCell(r, 0, _orderNumber(orden), style: 8),
        textCell(r, 1, _formatDate(_parseDate(_readValue(orden, const ['FECHA_ORDEN', 'fecha_orden']))), style: 9),
        textCell(r, 2, _orderClientName(orden), style: 8),
        numCell(r, 3, _itemsPorOrden(orden), style: 9),
        numCell(r, 4, _orderTotal(orden), style: 5),
        textCell(r, 5, estado, style: estado == 'Cancelado' ? 16 : 15),
        textCell(r, 6, estado == 'Cancelado' ? 'Revisar' : 'Operación registrada', style: 8),
      ], height: 23));
    }
    final ordenesXml = worksheetXml(
      rows: orderRows,
      maxRow: math.max(10, sortedOrders.length + 9),
      maxCol: 7,
      merges: orderMerges,
      colWidths: [18, 15, 42, 10, 16, 18, 24],
    );

    final archive = Archive();
    void add(String path, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    add('[Content_Types].xml', _excelContentTypesXml());
    add('_rels/.rels', _excelRootRelsXml());
    add('docProps/core.xml', _excelCoreXml(data.generatedAt));
    add('docProps/app.xml', _excelAppXml());
    add('xl/workbook.xml', _excelWorkbookXml());
    add('xl/_rels/workbook.xml.rels', _excelWorkbookRelsXml());
    add('xl/styles.xml', _excelStylesXml());
    add('xl/worksheets/sheet1.xml', dashboardXml);
    add('xl/worksheets/sheet2.xml', graficosXml);
    add('xl/worksheets/sheet3.xml', detalleXml);
    add('xl/worksheets/sheet4.xml', rankingXml);
    add('xl/worksheets/sheet5.xml', ordenesXml);

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) throw Exception('No se pudo codificar el archivo Excel.');
    return Uint8List.fromList(encoded);
  }

  String _excelContentTypesXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet3.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet4.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet5.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>''';

  String _excelRootRelsXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>''';

  String _excelCoreXml(DateTime generatedAt) => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:creator>Muebles de los Alpes</dc:creator><cp:lastModifiedBy>Muebles de los Alpes</cp:lastModifiedBy><dcterms:created xsi:type="dcterms:W3CDTF">${generatedAt.toUtc().toIso8601String()}</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">${generatedAt.toUtc().toIso8601String()}</dcterms:modified></cp:coreProperties>''';

  String _excelAppXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><Application>Muebles de los Alpes</Application><DocSecurity>0</DocSecurity><ScaleCrop>false</ScaleCrop><HeadingPairs><vt:vector size="2" baseType="variant"><vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant><vt:variant><vt:i4>5</vt:i4></vt:variant></vt:vector></HeadingPairs><TitlesOfParts><vt:vector size="5" baseType="lpstr"><vt:lpstr>01 Dashboard</vt:lpstr><vt:lpstr>02 Graficos</vt:lpstr><vt:lpstr>03 Detalle productos</vt:lpstr><vt:lpstr>04 Ranking productos</vt:lpstr><vt:lpstr>05 Ordenes</vt:lpstr></vt:vector></TitlesOfParts><Company>Muebles de los Alpes</Company></Properties>''';

  String _excelWorkbookXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><bookViews><workbookView xWindow="0" yWindow="0" windowWidth="28800" windowHeight="17600"/></bookViews><sheets><sheet name="01 Dashboard" sheetId="1" r:id="rId1"/><sheet name="02 Graficos" sheetId="2" r:id="rId2"/><sheet name="03 Detalle productos" sheetId="3" r:id="rId3"/><sheet name="04 Ranking productos" sheetId="4" r:id="rId4"/><sheet name="05 Ordenes" sheetId="5" r:id="rId5"/></sheets></workbook>''';

  String _excelWorkbookRelsXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet3.xml"/><Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet4.xml"/><Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet5.xml"/><Relationship Id="rId6" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>''';

  String _excelStylesXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><numFmts count="2"><numFmt numFmtId="164" formatCode="&quot;Q &quot;#,##0.00"/><numFmt numFmtId="165" formatCode="0.0%"/></numFmts><fonts count="7"><font><sz val="10"/><color rgb="FF2D1B12"/><name val="Arial"/></font><font><b/><sz val="18"/><color rgb="FF2D1B12"/><name val="Arial"/></font><font><b/><sz val="13"/><color rgb="FF6F4E37"/><name val="Arial"/></font><font><b/><sz val="10"/><color rgb="FFFFFFFF"/><name val="Arial"/></font><font><b/><sz val="11"/><color rgb="FF2D1B12"/><name val="Arial"/></font><font><b/><sz val="16"/><color rgb="FF0F4C35"/><name val="Arial"/></font><font><sz val="9"/><color rgb="FF6F4E37"/><name val="Arial"/></font></fonts><fills count="10"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFFFCF8"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FF2D1B12"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFF4E7D4"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFD8C1A2"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FF0F7B5F"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFC28A20"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFDF8EF"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFFEFEF"/><bgColor indexed="64"/></patternFill></fill></fills><borders count="3"><border><left/><right/><top/><bottom/><diagonal/></border><border><left style="thin"><color rgb="FFD8C1A2"/></left><right style="thin"><color rgb="FFD8C1A2"/></right><top style="thin"><color rgb="FFD8C1A2"/></top><bottom style="thin"><color rgb="FFD8C1A2"/></bottom><diagonal/></border><border><left style="medium"><color rgb="FFC28A20"/></left><right style="thin"><color rgb="FFD8C1A2"/></right><top style="thin"><color rgb="FFD8C1A2"/></top><bottom style="thin"><color rgb="FFD8C1A2"/></bottom><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="17"><xf numFmtId="0" fontId="0" fillId="2" borderId="0" xfId="0" applyFill="1"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"><alignment horizontal="center" vertical="center"/></xf><xf numFmtId="0" fontId="2" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"><alignment horizontal="center" vertical="center"/></xf><xf numFmtId="0" fontId="6" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"><alignment horizontal="center" vertical="center"/></xf><xf numFmtId="0" fontId="4" fillId="2" borderId="1" xfId="0" applyFont="1" applyBorder="1"><alignment vertical="center"/></xf><xf numFmtId="164" fontId="4" fillId="8" borderId="1" xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyBorder="1"><alignment horizontal="right" vertical="center"/></xf><xf numFmtId="0" fontId="3" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf><xf numFmtId="0" fontId="0" fillId="8" borderId="1" xfId="0" applyFill="1" applyBorder="1"><alignment vertical="center" wrapText="1"/></xf><xf numFmtId="0" fontId="0" fillId="8" borderId="1" xfId="0" applyFill="1" applyBorder="1"><alignment vertical="center" wrapText="1"/></xf><xf numFmtId="0" fontId="0" fillId="8" borderId="1" xfId="0" applyFill="1" applyBorder="1"><alignment horizontal="center" vertical="center"/></xf><xf numFmtId="165" fontId="0" fillId="8" borderId="1" xfId="0" applyNumberFormat="1" applyFill="1" applyBorder="1"><alignment horizontal="center" vertical="center"/></xf><xf numFmtId="0" fontId="3" fillId="3" borderId="2" xfId="0" applyFont="1" applyFill="1" applyBorder="1"><alignment vertical="center"/></xf><xf numFmtId="0" fontId="4" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"><alignment horizontal="center" vertical="center"/></xf><xf numFmtId="0" fontId="5" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"><alignment horizontal="center" vertical="center"/></xf><xf numFmtId="0" fontId="6" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"><alignment horizontal="center" vertical="center"/></xf><xf numFmtId="0" fontId="4" fillId="8" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"><alignment horizontal="center" vertical="center"/></xf><xf numFmtId="0" fontId="4" fillId="9" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"><alignment horizontal="center" vertical="center"/></xf></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>''';

  String _excelSheetDrawingRelsXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing" Target="../drawings/drawing1.xml"/></Relationships>''';

  String _excelDrawingRelsXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/chart" Target="../charts/chart1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/chart" Target="../charts/chart2.xml"/></Relationships>''';

  String _excelDrawingXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><xdr:twoCellAnchor><xdr:from><xdr:col>0</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>10</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:from><xdr:to><xdr:col>5</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>23</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:to><xdr:graphicFrame macro=""><xdr:nvGraphicFramePr><xdr:cNvPr id="2" name="Ventas mensuales"/><xdr:cNvGraphicFramePr/></xdr:nvGraphicFramePr><xdr:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/></xdr:xfrm><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/chart"><c:chart r:id="rId1"/></a:graphicData></a:graphic></xdr:graphicFrame><xdr:clientData/></xdr:twoCellAnchor><xdr:twoCellAnchor><xdr:from><xdr:col>6</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>10</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:from><xdr:to><xdr:col>11</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>23</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:to><xdr:graphicFrame macro=""><xdr:nvGraphicFramePr><xdr:cNvPr id="3" name="Ranking de productos"/><xdr:cNvGraphicFramePr/></xdr:nvGraphicFramePr><xdr:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/></xdr:xfrm><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/chart"><c:chart r:id="rId2"/></a:graphicData></a:graphic></xdr:graphicFrame><xdr:clientData/></xdr:twoCellAnchor></xdr:wsDr>''';

  String _excelBarChartXml({
    required String title,
    required String sheetName,
    required String categoryRef,
    required String valueRef,
    required String seriesName,
    required String colorHex,
    required int axisBase,
  }) {
    final safeSheet = "'$sheetName'";
    final cat = '$safeSheet!$categoryRef';
    final val = '$safeSheet!$valueRef';
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<c:chartSpace xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><c:lang val="es-GT"/><c:roundedCorners val="1"/><c:chart><c:title><c:tx><c:rich><a:bodyPr/><a:lstStyle/><a:p><a:r><a:rPr lang="es-GT" sz="1300" b="1"><a:solidFill><a:srgbClr val="2D1B12"/></a:solidFill></a:rPr><a:t>$title</a:t></a:r></a:p></c:rich></c:tx><c:overlay val="0"/></c:title><c:plotArea><c:layout/><c:barChart><c:barDir val="col"/><c:grouping val="clustered"/><c:ser><c:idx val="0"/><c:order val="0"/><c:tx><c:v>$seriesName</c:v></c:tx><c:spPr><a:solidFill><a:srgbClr val="$colorHex"/></a:solidFill><a:ln><a:solidFill><a:srgbClr val="$colorHex"/></a:solidFill></a:ln></c:spPr><c:cat><c:strRef><c:f>$cat</c:f></c:strRef></c:cat><c:val><c:numRef><c:f>$val</c:f></c:numRef></c:val></c:ser><c:gapWidth val="70"/><c:axId val="$axisBase"/><c:axId val="${axisBase + 1}"/></c:barChart><c:catAx><c:axId val="$axisBase"/><c:scaling><c:orientation val="minMax"/></c:scaling><c:delete val="0"/><c:axPos val="b"/><c:majorTickMark val="none"/><c:minorTickMark val="none"/><c:tickLblPos val="nextTo"/><c:crossAx val="${axisBase + 1}"/><c:crosses val="autoZero"/><c:auto val="1"/><c:lblAlgn val="ctr"/><c:lblOffset val="100"/></c:catAx><c:valAx><c:axId val="${axisBase + 1}"/><c:scaling><c:orientation val="minMax"/></c:scaling><c:delete val="0"/><c:axPos val="l"/><c:majorGridlines><c:spPr><a:ln w="6350"><a:solidFill><a:srgbClr val="D8C1A2"/></a:solidFill></a:ln></c:spPr></c:majorGridlines><c:numFmt formatCode="&quot;Q &quot;#,##0" sourceLinked="0"/><c:majorTickMark val="none"/><c:minorTickMark val="none"/><c:tickLblPos val="nextTo"/><c:crossAx val="$axisBase"/><c:crosses val="autoZero"/><c:crossBetween val="between"/></c:valAx></c:plotArea><c:legend><c:legendPos val="b"/><c:overlay val="0"/></c:legend><c:plotVisOnly val="1"/><c:dispBlanksAs val="gap"/></c:chart><c:spPr><a:solidFill><a:srgbClr val="FFFCF8"/></a:solidFill><a:ln><a:solidFill><a:srgbClr val="D8C1A2"/></a:solidFill></a:ln></c:spPr></c:chartSpace>''';
  }

  Future<Uint8List> _crearPdfReporte(_ReportData data) async {
    final pdf = pw.Document();

    final dark = PdfColor.fromInt(0xFF2D1B12);
    final espresso = PdfColor.fromInt(0xFF3A2216);
    final brown = PdfColor.fromInt(0xFF6F4E37);
    final lightBrown = PdfColor.fromInt(0xFFD8C1A2);
    final cream = PdfColor.fromInt(0xFFFFFCF8);
    final parchment = PdfColor.fromInt(0xFFF4E7D4);
    final green = PdfColor.fromInt(0xFF0F7B5F);
    final blue = PdfColor.fromInt(0xFF2F6FB2);
    final gold = PdfColor.fromInt(0xFFC28A20);
    final red = PdfColor.fromInt(0xFF9B3030);
    final purple = PdfColor.fromInt(0xFF6B2EA8);

    final ventasPorMes = <int, double>{};
    final ordenesPorMes = <int, int>{};
    for (int month = data.range.startMonth; month <= data.range.endMonth; month++) {
      ventasPorMes[month] = 0;
      ordenesPorMes[month] = 0;
    }
    for (final orden in data.orders) {
      final fecha = _parseDate(_readValue(orden, const ['FECHA_ORDEN', 'fecha_orden']));
      if (fecha == null) continue;
      ventasPorMes[fecha.month] = (ventasPorMes[fecha.month] ?? 0) + _orderTotal(orden);
      ordenesPorMes[fecha.month] = (ordenesPorMes[fecha.month] ?? 0) + 1;
    }

    final productoTotales = <String, _ProductMonthlyReportRow>{};
    for (final row in data.monthlyProducts) {
      final item = productoTotales.putIfAbsent(
        row.productId,
        () => _ProductMonthlyReportRow(month: 0, product: row.product, productId: row.productId),
      );
      item.quantity += row.quantity;
      item.total += row.total;
    }
    final topProducts = productoTotales.values.toList()..sort((a, b) => b.total.compareTo(a.total));

    final sortedOrders = [...data.orders]..sort((a, b) {
      final fechaA = _parseDate(_readValue(a, const ['FECHA_ORDEN', 'fecha_orden'])) ?? DateTime(1900);
      final fechaB = _parseDate(_readValue(b, const ['FECHA_ORDEN', 'fecha_orden'])) ?? DateTime(1900);
      return fechaB.compareTo(fechaA);
    });

    final uniqueClients = sortedOrders.map(_orderClientName).where((e) => e.trim().isNotEmpty).toSet().toList()..sort();
    final bestMonth = ventasPorMes.entries.isEmpty
        ? MapEntry(data.range.startMonth, 0.0)
        : ventasPorMes.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final cancellationRate = data.totalOrders == 0 ? 0.0 : data.cancelledOrders / data.totalOrders;
    final deliveryRate = data.totalOrders == 0 ? 0.0 : data.deliveredOrders / data.totalOrders;

    pw.Widget brandHeader() {
      return pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: pw.BoxDecoration(
          color: espresso,
          borderRadius: pw.BorderRadius.circular(16),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 46,
              height: 46,
              decoration: pw.BoxDecoration(
                color: gold,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Center(
                child: pw.Text('MA', style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('MUEBLES DE LOS ALPES', style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
                  pw.SizedBox(height: 4),
                  pw.Text('Reporte administrativo ejecutivo · ${data.range.label}', style: pw.TextStyle(color: PdfColor.fromInt(0xFFE9DDD1), fontSize: 10.5)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Generado', style: pw.TextStyle(color: PdfColor.fromInt(0xFFE9DDD1), fontSize: 8)),
                pw.Text(_formatDate(data.generatedAt), style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      );
    }

    pw.Widget sectionTitle(String title, String subtitle) {
      return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: gold, width: 1.2))),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(color: dark, fontSize: 14.5, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: pw.TextStyle(color: brown, fontSize: 8.8)),
          ],
        ),
      );
    }

    pw.Widget kpi(String title, String value, String subtitle, PdfColor color) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(11),
          border: pw.Border.all(color: lightBrown, width: .65),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(width: 24, height: 3, color: color),
            pw.SizedBox(height: 6),
            pw.Text(title, style: pw.TextStyle(color: brown, fontSize: 7.8, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 3),
            pw.Text(value, maxLines: 1, style: pw.TextStyle(color: dark, fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 3),
            pw.Text(subtitle, style: pw.TextStyle(color: brown, fontSize: 6.8)),
          ],
        ),
      );
    }

    pw.Widget barChart() {
      final values = ventasPorMes.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      final maxValue = values.isEmpty ? 0.0 : values.map((e) => e.value).reduce(math.max);
      final safeMax = maxValue <= 0 ? 1.0 : maxValue;

      String shortMonth(int month) {
        final name = _getMonthName(month - 1);
        if (name.length <= 3) return name;
        return name.substring(0, 3);
      }

      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: lightBrown, width: .7),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tendencia mensual de ventas', style: pw.TextStyle(color: dark, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('Total: ${_formatCurrency(data.totalSales)}', style: pw.TextStyle(color: green, fontSize: 7.6, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              height: 142,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: values.map((entry) {
                  final barHeight = entry.value <= 0 ? 14.0 : 22.0 + ((entry.value / safeMax) * 66.0);
                  final isBest = entry.value == maxValue && maxValue > 0;
                  return pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            _formatCurrency(entry.value),
                            textAlign: pw.TextAlign.center,
                            maxLines: 2,
                            style: pw.TextStyle(color: isBest ? green : brown, fontSize: 5.5, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Container(
                            width: 22,
                            height: barHeight,
                            decoration: pw.BoxDecoration(
                              color: isBest ? green : gold,
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(shortMonth(entry.key), style: pw.TextStyle(color: dark, fontSize: 7.2, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 2),
                          pw.Text('${ordenesPorMes[entry.key] ?? 0} ord.', style: pw.TextStyle(color: brown, fontSize: 5.8)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget compactListCard(String title, List<String> rows, PdfColor accent) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(11),
          border: pw.Border.all(color: lightBrown, width: .6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(children: [
              pw.Container(width: 4, height: 18, color: accent),
              pw.SizedBox(width: 7),
              pw.Text(title, style: pw.TextStyle(color: dark, fontSize: 10.2, fontWeight: pw.FontWeight.bold)),
            ]),
            pw.SizedBox(height: 7),
            if (rows.isEmpty)
              pw.Text('Sin datos disponibles en el periodo.', style: pw.TextStyle(color: brown, fontSize: 8.2))
            else
              ...rows.map((text) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text('- $text', maxLines: 2, style: pw.TextStyle(color: brown, fontSize: 7.7, lineSpacing: 2)),
                  )),
          ],
        ),
      );
    }

    pw.Widget ordersTable({int limit = 8}) {
      final rows = sortedOrders.take(limit).map((orden) {
        return [
          _orderNumber(orden),
          _formatDate(_parseDate(_readValue(orden, const ['FECHA_ORDEN', 'fecha_orden']))),
          _orderClientName(orden),
          '${_itemsPorOrden(orden)}',
          _formatCurrency(_orderTotal(orden)),
          _prettyEstado(_resolverEstado(orden)),
        ];
      }).toList();
      if (rows.isEmpty) {
        return compactListCard('Órdenes del periodo', const [], blue);
      }
      return pw.Table.fromTextArray(
        border: pw.TableBorder.all(color: lightBrown, width: .4),
        headerDecoration: pw.BoxDecoration(color: espresso),
        headerStyle: pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
        cellStyle: pw.TextStyle(color: dark, fontSize: 6.8),
        oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFFBF8F4)),
        cellAlignment: pw.Alignment.centerLeft,
        columnWidths: {
          0: const pw.FixedColumnWidth(46),
          1: const pw.FixedColumnWidth(48),
          2: const pw.FlexColumnWidth(2.1),
          3: const pw.FixedColumnWidth(32),
          4: const pw.FixedColumnWidth(58),
          5: const pw.FixedColumnWidth(56),
        },
        headers: ['Orden', 'Fecha', 'Cliente', 'Items', 'Total', 'Estado'],
        data: rows,
      );
    }

    List<pw.Widget> firstPageWidgets() {
      final productNames = topProducts.take(8).map((p) => '${p.product} (${p.quantity})').toList();
      return [
        brandHeader(),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            pw.SizedBox(width: 165, child: kpi('Ventas totales', _formatCurrency(data.totalSales), 'Ingreso comercial', green)),
            pw.SizedBox(width: 165, child: kpi('Órdenes', '${data.totalOrders}', 'Operaciones registradas', blue)),
            pw.SizedBox(width: 165, child: kpi('Ticket promedio', _formatCurrency(data.averageTicket), 'Promedio por orden', gold)),
            pw.SizedBox(width: 165, child: kpi('Clientes únicos', '${data.totalClients}', 'Clientes atendidos', purple)),
            pw.SizedBox(width: 165, child: kpi('Items vendidos', '${data.itemsSold}', 'Unidades registradas', green)),
            pw.SizedBox(width: 165, child: kpi('Canceladas', '${data.cancelledOrders}', 'No concretadas', red)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(flex: 3, child: barChart()),
            pw.SizedBox(width: 10),
            pw.Expanded(
              flex: 2,
              child: compactListCard('Clientes únicos', uniqueClients.take(8).toList(), purple),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        sectionTitle('Órdenes recientes del periodo', 'Información extraída directamente de las órdenes incluidas en el rango'),
        pw.SizedBox(height: 7),
        ordersTable(limit: 7),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: compactListCard('Items vendidos principales', productNames, green)),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: compactListCard('Lectura rápida', [
                'Mejor mes: ${_getMonthName(bestMonth.key - 1)} con ${_formatCurrency(bestMonth.value)}.',
                'Tasa de entrega: ${(deliveryRate * 100).toStringAsFixed(1)}%.',
                'Tasa de cancelación: ${(cancellationRate * 100).toStringAsFixed(1)}%.',
              ], gold),
            ),
          ],
        ),
      ];
    }

    List<pw.Widget> secondPageWidgets() {
      return [
        sectionTitle('Ranking de productos', 'Productos con mayor contribución dentro del periodo'),
        pw.SizedBox(height: 8),
        if (topProducts.isEmpty)
          compactListCard('Ranking de productos', const [], green)
        else
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: lightBrown, width: .42),
            headerDecoration: pw.BoxDecoration(color: espresso),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(color: dark, fontSize: 7.2),
            oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFFBF8F4)),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FixedColumnWidth(28),
              1: const pw.FlexColumnWidth(2.8),
              2: const pw.FixedColumnWidth(52),
              3: const pw.FixedColumnWidth(62),
              4: const pw.FixedColumnWidth(58),
            },
            headers: ['#', 'Producto', 'Cantidad', 'Ventas', '% total'],
            data: topProducts.take(12).toList().asMap().entries.map((entry) {
              final row = entry.value;
              final share = data.totalSales <= 0 ? 0 : row.total / data.totalSales * 100;
              return ['${entry.key + 1}', row.product, '${row.quantity}', _formatCurrency(row.total), '${share.toStringAsFixed(1)}%'];
            }).toList(),
          ),
        pw.SizedBox(height: 14),
        sectionTitle('Detalle mensual por producto', 'Ventas calculadas contra el total real de las órdenes del periodo'),
        pw.SizedBox(height: 8),
        if (data.monthlyProducts.isEmpty)
          compactListCard('Detalle mensual', const [], blue)
        else
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: lightBrown, width: .36),
            headerDecoration: pw.BoxDecoration(color: espresso),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontSize: 7.8, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(color: dark, fontSize: 6.8),
            oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFFBF8F4)),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FixedColumnWidth(46),
              1: const pw.FlexColumnWidth(2.6),
              2: const pw.FixedColumnWidth(44),
              3: const pw.FixedColumnWidth(62),
              4: const pw.FixedColumnWidth(50),
            },
            headers: ['Mes', 'Producto', 'Cant.', 'Ventas', '% total'],
            data: data.monthlyProducts.take(32).map((row) {
              final share = data.totalSales <= 0 ? 0 : row.total / data.totalSales * 100;
              return [_getMonthName(row.month - 1), row.product, '${row.quantity}', _formatCurrency(row.total), '${share.toStringAsFixed(1)}%'];
            }).toList(),
          ),
        if (data.monthlyProducts.length > 32) ...[
          pw.SizedBox(height: 7),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(color: parchment, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Text('El PDF muestra los primeros 32 registros para mantener lectura ejecutiva. El Excel incluye el detalle completo.', style: pw.TextStyle(color: brown, fontSize: 7.2)),
          ),
        ],
      ];
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(),
          buildBackground: (_) => pw.Container(color: cream),
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Muebles de los Alpes · Reporte administrativo', style: pw.TextStyle(color: brown, fontSize: 7.5)),
            pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: pw.TextStyle(color: brown, fontSize: 7.5)),
          ],
        ),
        build: (_) => [
          ...firstPageWidgets(),
          pw.NewPage(),
          ...secondPageWidgets(),
        ],
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1EA),
      body: RefreshIndicator(
        color: AlpesColors.oroGuatemalteco,
        onRefresh: _cargarDatos,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              expandedHeight: 168,
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
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilledButton.icon(
                    onPressed: (_loading || _generandoReporte) ? null : _mostrarDialogoReporte,
                    style: FilledButton.styleFrom(
                      backgroundColor: AlpesColors.oroGuatemalteco,
                      foregroundColor: AlpesColors.cafeOscuro,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _generandoReporte
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AlpesColors.cafeOscuro),
                          )
                        : const Icon(Icons.file_download_rounded, size: 18),
                    label: Text(
                      _generandoReporte ? 'Generando...' : 'Generar reporte',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 18,
                  bottom: 18,
                ),
                title: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reportes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .3,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Dashboard administrativo de órdenes y rendimiento',
                      style: TextStyle(
                        color: Color(0xFFE9DDD1),
                        fontWeight: FontWeight.w500,
                        fontSize: 10.8,
                      ),
                    ),
                  ],
                ),
                background: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF2D1B12),
                            Color(0xFF4F3427),
                            Color(0xFF7B5A45),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -30,
                      right: -20,
                      child: _decorativeCircle(
                        150,
                        AlpesColors.oroGuatemalteco.withOpacity(.14),
                      ),
                    ),
                    Positioned(
                      bottom: -42,
                      left: -16,
                      child: _decorativeCircle(
                        110,
                        const Color(0xFFFBF4E6).withOpacity(.12),
                      ),
                    ),
                    Positioned(
                      top: 58,
                      right: 96,
                      child: _decorativeCircle(
                        28,
                        AlpesColors.oroGuatemalteco.withOpacity(.22),
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
                            const SizedBox(height: 14),
                            _buildSectionTitle('Tendencia de ventas'),
                            const SizedBox(height: 12),
                            _buildTrendCard(),
                            const SizedBox(height: 14),
                            _buildSectionTitle('Comparación por trimestre'),
                            const SizedBox(height: 12),
                            _buildQuarterComparisonCard(),
                            const SizedBox(height: 14),
                            _buildSectionTitle('Estados de órdenes'),
                            const SizedBox(height: 12),
                            _buildEstadoCharts(),
                            const SizedBox(height: 14),
                            _buildSectionTitle('Inventario en vigilancia'),
                            const SizedBox(height: 12),
                            _buildInventarioCard(),
                            const SizedBox(height: 14),
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
    final bg = isError ? const Color(0xFFFFF1EC) : const Color(0xFFFFFAF0);
    final fg = isError ? AlpesColors.rojoColonial : const Color(0xFF8A6515);
    final text = isError
        ? (_error ?? 'No se pudo establecer conexión con la API.')
        : 'Conexión activa con la API. Los indicadores se muestran con la información disponible en este momento.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(.18)),
        boxShadow: [
          BoxShadow(
            color: AlpesColors.cafeOscuro.withOpacity(.05),
            blurRadius: 16,
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
              color: fg.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError ? Icons.wifi_off_rounded : Icons.sync_rounded,
              color: fg,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isError
                      ? 'Sincronización con inconvenientes'
                      : 'Sincronización lista',
                  style: TextStyle(
                    color: fg,
                    fontSize: 13.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: fg.withOpacity(.88),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF5EBDD), const Color(0xFFE8D6BD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC6A57D).withOpacity(.42),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B5A45).withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE6D5BC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              size: 18,
              color: AlpesColors.cafeOscuro,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: AlpesColors.cafeOscuro,
              fontSize: 15.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    final cards = [
      _KpiData(
        'Ventas totales',
        _formatCompactMoney(_ventasTotales),
        Icons.trending_up_rounded,
        const [Color(0xFF0F4C35), Color(0xFF1A7A56)],
      ),
      _KpiData(
        'Órdenes',
        '$_totalOrdenes',
        Icons.receipt_long_rounded,
        const [Color(0xFF1A3A5C), Color(0xFF2D6EA8)],
      ),
      _KpiData(
        'Ticket promedio',
        _formatCurrency(_ticketPromedio),
        Icons.payments_rounded,
        const [Color(0xFF5C3A00), Color(0xFF9B6B00)],
      ),
      _KpiData(
        'Clientes',
        '$_totalClientes',
        Icons.groups_2_rounded,
        const [Color(0xFF3A1A5C), Color(0xFF6B2EA8)],
      ),
      _KpiData(
        'Stock bajo ≤5',
        '$_stockBajo',
        Icons.inventory_2_rounded,
        const [Color(0xFF1A3A1A), Color(0xFF2E7D32)],
      ),
      _KpiData(
        'Canceladas',
        '$_canceladas',
        Icons.cancel_outlined,
        const [Color(0xFF5E2020), Color(0xFF9B3030)],
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
            childAspectRatio: isNarrow ? 2.2 : 5.5,
          ),
          itemBuilder: (_, index) => _buildKpiCard(cards[index]),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiData data) {
    return ScaleTransition(
      scale: Tween<double>(begin: .96, end: 1).animate(_fadeAnimation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              data.gradient.first.withOpacity(.98),
              data.gradient.last.withOpacity(.98),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AlpesColors.oroGuatemalteco.withOpacity(.24),
          ),
          boxShadow: [
            BoxShadow(
              color: data.gradient.last.withOpacity(.20),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(.18)),
              ),
              child: Icon(data.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.86),
                      fontSize: 12.6,
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
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .2,
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
            height: 240,
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
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
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
        borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(10),
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
                        borderRadius: BorderRadius.circular(10),
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
    final rows = _ultimasOrdenesCache;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Últimas 10 órdenes',
                      style: TextStyle(
                        color: AlpesColors.cafeOscuro,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Monitorea el estado real de las órdenes más recientes y actualiza solo esta tabla cuando cambie.',
                      style: TextStyle(
                        color: AlpesColors.nogalMedio,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _recargandoUltimasOrdenes ? null : _recargarUltimasOrdenes,
                style: FilledButton.styleFrom(
                  backgroundColor: AlpesColors.cafeOscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _recargandoUltimasOrdenes
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  _recargandoUltimasOrdenes
                      ? 'Actualizando...'
                      : 'Recargar estados',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            _buildEmptyState('No hay órdenes disponibles para mostrar.')
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.94),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AlpesColors.oroGuatemalteco.withOpacity(.16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AlpesColors.cafeOscuro.withOpacity(.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minTableWidth = math.max(constraints.maxWidth, 1040.0);

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: minTableWidth),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: DataTable(
                          headingRowHeight: 56,
                          headingRowColor: MaterialStateProperty.all(
                            const Color(0xFFF2E9DA),
                          ),
                          dataRowMinHeight: 62,
                          dataRowMaxHeight: 70,
                          horizontalMargin: 18,
                          columnSpacing: 64,
                          dividerThickness: .6,
                          headingTextStyle: const TextStyle(
                            color: AlpesColors.cafeOscuro,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                          ),
                          columns: const [
                            DataColumn(label: Text('Orden')),
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Items')),
                            DataColumn(label: Text('Total')),
                            DataColumn(label: Text('Estado actual')),
                          ],
                          rows: rows.asMap().entries.map((entry) {
                            final index = entry.key;
                            final orden = entry.value;
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

                            return DataRow.byIndex(
                              index: index,
                              color: MaterialStateProperty.all(
                                index.isEven
                                    ? Colors.white
                                    : const Color(0xFFFCF8F2),
                              ),
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        numero,
                                        style: const TextStyle(
                                          color: AlpesColors.cafeOscuro,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.2,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Orden registrada',
                                        style: TextStyle(
                                          color: AlpesColors.nogalMedio
                                              .withOpacity(.85),
                                          fontSize: 11.4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _formatDate(fecha),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5EEE3),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '$items items',
                                      style: const TextStyle(
                                        color: AlpesColors.cafeOscuro,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _formatCurrency(total),
                                    style: const TextStyle(
                                      color: AlpesColors.cafeOscuro,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(.12),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: color.withOpacity(.16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          estado,
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 12.2,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFCF8), Color(0xFFF5EEE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD8C1A2).withOpacity(.55),
        ),
        boxShadow: [
          BoxShadow(
            color: AlpesColors.cafeOscuro.withOpacity(.05),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(.75),
            blurRadius: 10,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: child,
    );
  }
}


class _ReportRange {
  final int year;
  final int startMonth;
  final int endMonth;
  final String label;
  final String fileSuffix;

  const _ReportRange({
    required this.year,
    required this.startMonth,
    required this.endMonth,
    required this.label,
    required this.fileSuffix,
  });

  factory _ReportRange.fromSelection({
    required _ReportPeriodType periodType,
    required int year,
    required int startMonth,
    required int endMonth,
    required int quarter,
    required String Function(int monthIndex) getMonthName,
    required String Function(int quarter) getQuarterName,
  }) {
    switch (periodType) {
      case _ReportPeriodType.anual:
        return _ReportRange(
          year: year,
          startMonth: 1,
          endMonth: 12,
          label: 'Anual $year',
          fileSuffix: 'anual_$year',
        );
      case _ReportPeriodType.trimestre:
        final start = ((quarter - 1) * 3) + 1;
        final end = start + 2;
        return _ReportRange(
          year: year,
          startMonth: start,
          endMonth: end,
          label: '${getQuarterName(quarter)} · $year',
          fileSuffix: 'q${quarter}_$year',
        );
      case _ReportPeriodType.rangoMeses:
        final safeStart = math.min(startMonth, endMonth);
        final safeEnd = math.max(startMonth, endMonth);
        return _ReportRange(
          year: year,
          startMonth: safeStart,
          endMonth: safeEnd,
          label: '${getMonthName(safeStart - 1)} a ${getMonthName(safeEnd - 1)} · $year',
          fileSuffix: '${safeStart}_${safeEnd}_$year',
        );
    }
  }
}

class _ProductMonthlyReportRow {
  final int month;
  final String product;
  final String productId;
  int quantity;
  double total;

  _ProductMonthlyReportRow({
    required this.month,
    required this.product,
    required this.productId,
    this.quantity = 0,
    this.total = 0,
  });
}

class _ReportData {
  final _ReportRange range;
  final DateTime generatedAt;
  final double totalSales;
  final int totalOrders;
  final int totalClients;
  final int cancelledOrders;
  final int deliveredOrders;
  final int itemsSold;
  final double averageTicket;
  final List<_ProductMonthlyReportRow> monthlyProducts;
  final List<Map<String, dynamic>> orders;

  const _ReportData({
    required this.range,
    required this.generatedAt,
    required this.totalSales,
    required this.totalOrders,
    required this.totalClients,
    required this.cancelledOrders,
    required this.deliveredOrders,
    required this.itemsSold,
    required this.averageTicket,
    required this.monthlyProducts,
    required this.orders,
  });
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

    final points = <Offset>[];
    for (int i = 0; i < currentData.length; i++) {
      final x = chart.left + spacing * i + spacing / 2;
      final y = allZero
          ? chart.bottom - 2
          : chart.bottom - ((currentData[i] / maxValue) * chart.height * progress);
      points.add(Offset(x, y));
    }

    // Bezier suave
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 0; i < points.length - 1; i++) {
        final cp1x = points[i].dx + (points[i+1].dx - points[i].dx) / 2;
        final cp1y = points[i].dy;
        final cp2x = points[i].dx + (points[i+1].dx - points[i].dx) / 2;
        final cp2y = points[i+1].dy;
        path.cubicTo(cp1x, cp1y, cp2x, cp2y, points[i+1].dx, points[i+1].dy);
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

    final areaPoints = <Offset>[];
    for (int i = 0; i < currentData.length; i++) {
      final x = chart.left + spacing * i + spacing / 2;
      final y = chart.bottom - ((currentData[i] / maxValue) * chart.height * progress);
      areaPoints.add(Offset(x, y));
    }

    final path = Path();
    final fillPath = Path();
    if (areaPoints.isNotEmpty) {
      path.moveTo(areaPoints[0].dx, areaPoints[0].dy);
      fillPath.moveTo(areaPoints[0].dx, chart.bottom);
      fillPath.lineTo(areaPoints[0].dx, areaPoints[0].dy);
      for (int i = 0; i < areaPoints.length - 1; i++) {
        final cp1x = areaPoints[i].dx + (areaPoints[i+1].dx - areaPoints[i].dx) / 2;
        final cp1y = areaPoints[i].dy;
        final cp2x = areaPoints[i].dx + (areaPoints[i+1].dx - areaPoints[i].dx) / 2;
        final cp2y = areaPoints[i+1].dy;
        path.cubicTo(cp1x, cp1y, cp2x, cp2y, areaPoints[i+1].dx, areaPoints[i+1].dy);
        fillPath.cubicTo(cp1x, cp1y, cp2x, cp2y, areaPoints[i+1].dx, areaPoints[i+1].dy);
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