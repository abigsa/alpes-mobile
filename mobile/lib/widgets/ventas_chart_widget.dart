import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/theme.dart';
import '../config/api_config.dart';

// ─────────────────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────────────────
class _MesData {
  final String mes;
  final double ventas;
  const _MesData(this.mes, this.ventas);
}

// ─────────────────────────────────────────────────────────
//  CHART WIDGET
// ─────────────────────────────────────────────────────────
class VentasMensualesChart extends StatefulWidget {
  const VentasMensualesChart({super.key});
  @override
  State<VentasMensualesChart> createState() => _VentasMensualesChartState();
}

class _VentasMensualesChartState extends State<VentasMensualesChart>
    with SingleTickerProviderStateMixin {
  List<_MesData> _datos = [];
  bool _loading = true;
  String _periodo = '6M';
  late AnimationController _animCtrl;
  late Animation<double> _anim;
  int? _hoveredIndex;

  static const _mesesNombres = [
    'Ene','Feb','Mar','Abr','May','Jun',
    'Jul','Ago','Sep','Oct','Nov','Dic'
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _cargar();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res  = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        final list  = data['data'] as List;
        final ahora = DateTime.now();

        // Agrupar por mes
        final mapa = <int, double>{};
        for (final o in list) {
          final total = double.tryParse('${o['TOTAL'] ?? o['total'] ?? 0}') ?? 0;
          final fechaStr = (o['FECHA_ORDEN'] ?? o['fecha_orden'] ?? '').toString();
          if (fechaStr.isEmpty) continue;
          try {
            final fecha = DateTime.parse(fechaStr);
            final diffMeses = (ahora.year - fecha.year) * 12 + (ahora.month - fecha.month);
            final mesesFiltro = _periodo == '6M' ? 6 : _periodo == '12M' ? 12 : ahora.month;
            if (diffMeses >= 0 && diffMeses < mesesFiltro) {
              mapa[fecha.month] = (mapa[fecha.month] ?? 0) + total;
            }
          } catch (_) {}
        }

        // Construir lista ordenada
        final mesesFiltro = _periodo == '6M' ? 6 : _periodo == '12M' ? 12 : ahora.month;
        final lista = <_MesData>[];
        for (int i = mesesFiltro - 1; i >= 0; i--) {
          int mes = ahora.month - i;
          if (mes <= 0) mes += 12;
          lista.add(_MesData(_mesesNombres[mes - 1], mapa[mes] ?? 0));
        }

        setState(() { _datos = lista; _loading = false; });
        _animCtrl.forward(from: 0);
      }
    } catch (_) {
      // Datos de ejemplo si falla
      setState(() {
        _datos = const [
          _MesData('Jul', 38200), _MesData('Ago', 42500),
          _MesData('Sep', 35800), _MesData('Oct', 51200),
          _MesData('Nov', 67800), _MesData('Dic', 49000),
        ];
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    }
  }

  double get _totalAcumulado => _datos.fold(0, (s, d) => s + d.ventas);
  double get _promedioMensual => _datos.isEmpty ? 0 : _totalAcumulado / _datos.length;
  double get _maxVenta => _datos.isEmpty ? 1 : _datos.map((d) => d.ventas).reduce(max);

  String _formatQ(double v) {
    if (v >= 1000000) return 'Q${(v/1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'Q${(v/1000).toStringAsFixed(1)}k';
    return 'Q${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AlpesColors.oroGuatemalteco.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AlpesColors.oroGuatemalteco.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.07),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Ventas mensuales',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: AlpesColors.cafeOscuro)),
                  const Text('Ingresos acumulados en quetzales',
                      style: TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
                ]),
              ),
              // Filtros de período
              Container(
                decoration: BoxDecoration(
                  color: AlpesColors.cremaFondo,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AlpesColors.pergamino),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['6M','12M','YTD'].map((p) {
                    final active = _periodo == p;
                    return GestureDetector(
                      onTap: () { setState(() => _periodo = p); _cargar(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: active ? AlpesColors.cafeOscuro : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(p,
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: active ? Colors.white : AlpesColors.arenaCalida)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── KPI mini row ──
            Row(children: [
              _miniKpi('Total acumulado', _formatQ(_totalAcumulado),
                  Icons.trending_up_rounded, AlpesColors.cafeOscuro),
              const SizedBox(width: 8),
              _miniKpi('Mejor mes', _formatQ(_maxVenta),
                  Icons.star_rounded, AlpesColors.oroGuatemalteco),
              const SizedBox(width: 8),
              _miniKpi('Promedio mensual', _formatQ(_promedioMensual),
                  Icons.calculate_rounded, AlpesColors.verdeSelva),
            ]),
            const SizedBox(height: 18),

            // ── Gráfica ──
            if (_loading)
              const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator(
                    color: AlpesColors.cafeOscuro, strokeWidth: 2)),
              )
            else
              SizedBox(
                height: 160,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => _datos.isEmpty
                      ? const Center(child: Text('Sin datos',
                          style: TextStyle(color: AlpesColors.arenaCalida)))
                      : _BarChart(
                          datos       : _datos,
                          animValue   : _anim.value,
                          hoveredIndex: _hoveredIndex,
                          onHover     : (i) => setState(() => _hoveredIndex = i),
                          formatQ     : _formatQ,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _miniKpi(String label, String value, IconData icon, Color accent) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withOpacity(0.15)),
          ),
          child: Row(children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: accent)),
                Text(label, style: const TextStyle(fontSize: 9,
                    color: AlpesColors.nogalMedio), overflow: TextOverflow.ellipsis),
              ],
            )),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────
//  BAR CHART con CustomPainter
// ─────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<_MesData> datos;
  final double animValue;
  final int? hoveredIndex;
  final Function(int?) onHover;
  final String Function(double) formatQ;

  const _BarChart({
    required this.datos,
    required this.animValue,
    required this.hoveredIndex,
    required this.onHover,
    required this.formatQ,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) => onHover(null),
      child: GestureDetector(
        onTapDown: (d) {
          final barWidth = context.size!.width / datos.length;
          final idx = (d.localPosition.dx / barWidth).floor().clamp(0, datos.length - 1);
          onHover(idx);
        },
        child: CustomPaint(
          size: const Size(double.infinity, 160),
          painter: _BarChartPainter(
            datos        : datos,
            animValue    : animValue,
            hoveredIndex : hoveredIndex,
            formatQ      : formatQ,
          ),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_MesData> datos;
  final double animValue;
  final int? hoveredIndex;
  final String Function(double) formatQ;

  const _BarChartPainter({
    required this.datos,
    required this.animValue,
    required this.hoveredIndex,
    required this.formatQ,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (datos.isEmpty) return;

    const paddingBottom = 24.0;
    const paddingTop    = 24.0;
    final chartH = size.height - paddingBottom - paddingTop;
    final maxVal = datos.map((d) => d.ventas).reduce(max);
    if (maxVal == 0) return;

    final barW    = size.width / datos.length;
    final barPad  = barW * 0.2;
    final actualW = barW - barPad * 2;

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFC4A882).withOpacity(0.2)
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 4; i++) {
      final y = paddingTop + chartH * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Barras
    for (int i = 0; i < datos.length; i++) {
      final d      = datos[i];
      final ratio  = (d.ventas / maxVal) * animValue;
      final barH   = chartH * ratio;
      final x      = barW * i + barPad;
      final y      = paddingTop + chartH - barH;
      final isHov  = hoveredIndex == i;

      // Sombra barra hover
      if (isHov) {
        final shadowPaint = Paint()
          ..color = const Color(0xFF2C1810).withOpacity(0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 2, y + 4, actualW, barH),
            const Radius.circular(5),
          ),
          shadowPaint,
        );
      }

      // Barra principal
      final barPaint = Paint()
        ..color = isHov
            ? const Color(0xFF2C1810)
            : const Color(0xFF2C1810).withOpacity(0.65);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, actualW, barH),
          const Radius.circular(5),
        ),
        barPaint,
      );

      // Línea dorada top en hover
      if (isHov && barH > 0) {
        final linePaint = Paint()
          ..color = const Color(0xFFD4A853)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(x + 2, y),
          Offset(x + actualW - 2, y),
          linePaint,
        );
      }

      // Valor encima de la barra (solo hover o valor más alto)
      final isMax = d.ventas == maxVal;
      if (isHov || isMax) {
        final tp = TextPainter(
          text: TextSpan(
            text: formatQ(d.ventas),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isHov
                  ? const Color(0xFFD4A853)
                  : const Color(0xFF2C1810).withOpacity(0.6),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + (actualW - tp.width) / 2, y - 14));
      }

      // Label mes
      final labelTp = TextPainter(
        text: TextSpan(
          text: d.mes,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isHov ? FontWeight.w700 : FontWeight.w400,
            color: isHov
                ? const Color(0xFF2C1810)
                : const Color(0xFFC4A882),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelTp.paint(canvas,
          Offset(x + (actualW - labelTp.width) / 2, size.height - paddingBottom + 6));
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.animValue != animValue || old.hoveredIndex != hoveredIndex;
}
