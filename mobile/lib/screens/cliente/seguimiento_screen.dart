import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';

class SeguimientoScreen extends StatefulWidget {
  final int envioId;
  const SeguimientoScreen({super.key, required this.envioId});
  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  List<Map<String, dynamic>> _ordenes = [];
  final Map<int, Map<String, dynamic>?> _envios = {};
  final Map<int, List<Map<String, dynamic>>> _eventos = {};
  final Map<int, bool> _expandido = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  String _estadoReal(Map<String, dynamic> o) {
    final obs = '${o['OBSERVACIONES'] ?? o['observaciones'] ?? ''}';
    final match = RegExp(r'^\[([A-Z_]+)\]').firstMatch(obs);
    if (match != null) {
      const mapa = {
        'INGRESADA': 'pendiente',
        'PENDIENTE': 'pendiente',
        'EN_PROCESO': 'en proceso',
        'ENTREGADA': 'entregado',
        'CANCELADA': 'cancelado',
      };
      return mapa[match.group(1)!] ?? 'pendiente';
    }
    return (o['ESTADO'] ?? o['estado'] ?? 'pendiente').toString().toLowerCase();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    if (auth.clienteId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await http.get(Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.ordenVenta}/buscar?criterio=cli_id&valor=${auth.clienteId}'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        _ordenes = List<Map<String, dynamic>>.from(data['data']);
      }

      for (final orden in _ordenes) {
        final ordenId = _idOrden(orden);
        if (ordenId == null) continue;
        try {
          final envRes = await http.get(Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.envio}/buscar?criterio=orden_venta_id&valor=$ordenId'));
          final envData = jsonDecode(envRes.body);
          if (envData['ok'] == true && (envData['data'] as List).isNotEmpty) {
            final envio =
                (envData['data'] as List).first as Map<String, dynamic>;
            _envios[ordenId] = envio;
            final envioIdReal =
                int.tryParse('${envio['ENVIO_ID'] ?? envio['envio_id'] ?? ''}');
            if (envioIdReal != null) {
              final segRes = await http.get(Uri.parse(
                  '${ApiConfig.baseUrl}${ApiConfig.seguimiento}/buscar?criterio=envio_id&valor=$envioIdReal'));
              final segData = jsonDecode(segRes.body);
              _eventos[ordenId] = segData['ok'] == true
                  ? List<Map<String, dynamic>>.from(segData['data'])
                  : [];
            } else {
              _eventos[ordenId] = [];
            }
          } else {
            _envios[ordenId] = null;
            _eventos[ordenId] = [];
          }
        } catch (_) {
          _envios[ordenId] = null;
          _eventos[ordenId] = [];
        }
      }
    } catch (_) {}

    if (_ordenes.isNotEmpty) {
      final primero = _idOrden(_ordenes.first);
      if (primero != null) _expandido[primero] = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  int? _idOrden(Map<String, dynamic> o) =>
      int.tryParse('${o['ORDEN_VENTA_ID'] ?? o['orden_venta_id'] ?? ''}');

  Color _colorEstado(String e) {
    switch (e) {
      case 'entregado':
        return const Color(0xFF3B6D11);
      case 'en proceso':
        return const Color(0xFF185FA5);
      case 'cancelado':
        return AlpesColors.rojoColonial;
      default:
        return const Color(0xFF854F0B);
    }
  }

  Color _bgEstado(String e) {
    switch (e) {
      case 'entregado':
        return const Color(0xFFEAF3DE);
      case 'en proceso':
        return const Color(0xFFE6F1FB);
      case 'cancelado':
        return const Color(0xFFFCEBEB);
      default:
        return const Color(0xFFFAEEDA);
    }
  }

  IconData _iconEstado(String e) {
    switch (e) {
      case 'entregado':
        return Icons.check_circle_rounded;
      case 'en proceso':
        return Icons.build_rounded;
      case 'cancelado':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  int _pasoActivo(String estado) {
    switch (estado) {
      case 'en proceso':
        return 1;
      case 'entregado':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        backgroundColor: AlpesColors.cafeOscuro,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 16),
          ),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Seguimiento de envíos',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _cargar,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  CircularProgressIndicator(color: AlpesColors.cafeOscuro),
                  SizedBox(height: 16),
                  Text('Cargando tus envíos...',
                      style: TextStyle(
                          color: AlpesColors.nogalMedio, fontSize: 13)),
                ]))
          : _ordenes.isEmpty
              ? _buildVacio()
              : RefreshIndicator(
                  color: AlpesColors.cafeOscuro,
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _buildResumen(),
                      const SizedBox(height: 16),
                      ..._ordenes.map(_buildOrdenCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildVacio() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: AlpesColors.pergamino,
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.local_shipping_outlined,
                size: 40, color: AlpesColors.arenaCalida),
          ),
          const SizedBox(height: 16),
          const Text('Sin pedidos aún',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AlpesColors.cafeOscuro)),
          const SizedBox(height: 8),
          const Text('Tus envíos aparecerán aquí',
              style: TextStyle(fontSize: 13, color: AlpesColors.arenaCalida)),
        ]),
      );

  Widget _buildResumen() {
    int enCamino = 0, entregados = 0, pendientes = 0;
    for (final o in _ordenes) {
      final e = _estadoReal(o);
      if (e == 'entregado')
        entregados++;
      else if (e == 'en proceso')
        enCamino++;
      else
        pendientes++;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1810), Color(0xFF1C0F08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2C1810).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_shipping_rounded,
              color: AlpesColors.oroGuatemalteco, size: 18),
          const SizedBox(width: 8),
          const Text('Resumen de envíos',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AlpesColors.oroGuatemalteco.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AlpesColors.oroGuatemalteco.withOpacity(0.4)),
            ),
            child: Text('${_ordenes.length} pedidos',
                style: const TextStyle(
                    color: AlpesColors.oroGuatemalteco,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _statChip(Icons.schedule_rounded, '$pendientes', 'Pendientes',
              const Color(0xFFFAEEDA), const Color(0xFF854F0B)),
          const SizedBox(width: 8),
          _statChip(Icons.build_rounded, '$enCamino', 'En proceso',
              const Color(0xFFE6F1FB), const Color(0xFF185FA5)),
          const SizedBox(width: 8),
          _statChip(Icons.check_circle_rounded, '$entregados', 'Entregados',
              const Color(0xFFEAF3DE), const Color(0xFF3B6D11)),
        ]),
      ]),
    );
  }

  Widget _statChip(
          IconData icon, String valor, String label, Color bg, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(valor,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ]),
        ),
      );

  Widget _buildOrdenCard(Map<String, dynamic> orden) {
    final ordenId = _idOrden(orden);
    if (ordenId == null) return const SizedBox.shrink();

    final estado = _estadoReal(orden);
    final numOrden = orden['NUM_ORDEN'] ?? orden['num_orden'] ?? '#$ordenId';
    final fecha = (orden['FECHA_ORDEN'] ?? orden['fecha_orden'] ?? '')
        .toString()
        .split('T')
        .first;
    final total =
        double.tryParse('${orden['TOTAL'] ?? orden['total'] ?? 0}') ?? 0;
    final envio = _envios[ordenId];
    final eventos = _eventos[ordenId] ?? [];
    final isOpen = _expandido[ordenId] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen
              ? _colorEstado(estado).withOpacity(0.3)
              : AlpesColors.pergamino,
          width: isOpen ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: AlpesColors.cafeOscuro.withOpacity(isOpen ? 0.08 : 0.04),
              blurRadius: isOpen ? 16 : 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        // ── Header ──
        GestureDetector(
          onTap: () => setState(() => _expandido[ordenId] = !isOpen),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _bgEstado(estado),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconEstado(estado),
                    color: _colorEstado(estado), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text('Pedido #$numOrden',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AlpesColors.cafeOscuro),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _bgEstado(estado),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(estado.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: _colorEstado(estado))),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 11, color: AlpesColors.arenaCalida),
                        const SizedBox(width: 4),
                        Text(fecha,
                            style: const TextStyle(
                                fontSize: 11, color: AlpesColors.nogalMedio)),
                        const SizedBox(width: 12),
                        Text('Q${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AlpesColors.cafeOscuro)),
                      ]),
                    ]),
              ),
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color:
                        isOpen ? _colorEstado(estado) : AlpesColors.arenaCalida,
                    size: 22),
              ),
            ]),
          ),
        ),

        // ── Contenido expandible ──
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 280),
          crossFadeState:
              isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: [
            Divider(
                color: _colorEstado(estado).withOpacity(0.15),
                height: 1,
                indent: 16,
                endIndent: 16),
            if (envio != null) _buildInfoEnvio(envio, estado),
            if (estado != 'cancelado')
              _buildTimeline(estado)
            else
              _buildCancelado(),
            const SizedBox(height: 12),
          ]),
        ),
      ]),
    );
  }

  Widget _buildInfoEnvio(Map<String, dynamic> envio, String estado) {
    final tracking =
        envio['TRACKING_CODIGO'] ?? envio['tracking_codigo'] ?? '-';
    final dir = envio['DIRECCION_ENTREGA_SNAPSHOT'] ??
        envio['direccion_entrega_snapshot'] ??
        '-';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bgEstado(estado).withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _colorEstado(estado).withOpacity(0.15)),
        ),
        child: Column(children: [
          _infoRow(Icons.qr_code_rounded, 'Código de tracking',
              tracking.toString(), _colorEstado(estado)),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on_rounded, 'Dirección de entrega',
              dir.toString(), _colorEstado(estado)),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 1),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: AlpesColors.cafeOscuro,
                  fontWeight: FontWeight.w500)),
        ])),
      ]);

  Widget _buildTimeline(String estado) {
    final pasos = [
      {'label': 'Confirmado', 'icon': Icons.receipt_long_rounded},
      {'label': 'En producción', 'icon': Icons.build_rounded},
      {'label': 'En camino', 'icon': Icons.local_shipping_rounded},
      {'label': 'Entregado', 'icon': Icons.home_rounded},
    ];
    final activo = _pasoActivo(estado);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: pasos.asMap().entries.map((entry) {
          final i = entry.key;
          final paso = entry.value;
          final completado = i < activo;
          final esActivo = i == activo;
          final color = (completado || esActivo)
              ? _colorEstado(estado)
              : AlpesColors.arenaCalida.withOpacity(0.5);
          final bgColor = (completado || esActivo)
              ? _bgEstado(estado)
              : AlpesColors.pergamino;

          return Expanded(
            child: Row(children: [
              Expanded(
                child: Column(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: color, width: esActivo ? 2.5 : 1.5),
                      boxShadow: esActivo
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1)
                            ]
                          : null,
                    ),
                    child: Icon(
                      completado
                          ? Icons.check_rounded
                          : paso['icon'] as IconData,
                      color: color,
                      size: completado ? 18 : 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(paso['label'] as String,
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight:
                              esActivo ? FontWeight.w800 : FontWeight.w500,
                          color: esActivo
                              ? _colorEstado(estado)
                              : AlpesColors.nogalMedio),
                      textAlign: TextAlign.center),
                ]),
              ),
              if (i < pasos.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: i < activo
                        ? _colorEstado(estado)
                        : AlpesColors.pergamino,
                  ),
                ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCancelado() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFCEBEB),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AlpesColors.rojoColonial.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.cancel_rounded,
                color: AlpesColors.rojoColonial, size: 18),
            SizedBox(width: 10),
            Expanded(
                child: Text('Este pedido fue cancelado',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AlpesColors.rojoColonial))),
          ]),
        ),
      );

  Widget _buildEventos(List<Map<String, dynamic>> eventos, String estado) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Título
        Row(children: [
          Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                  color: _colorEstado(estado),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          const Text('Historial de eventos',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AlpesColors.cafeOscuro)),
          const Spacer(),
          if (eventos.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: _bgEstado(estado),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                  '${eventos.length} evento${eventos.length != 1 ? 's' : ''}',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _colorEstado(estado))),
            ),
        ]),
        const SizedBox(height: 12),

        if (eventos.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AlpesColors.cremaFondo,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AlpesColors.pergamino),
            ),
            child: Column(children: [
              Icon(Icons.timeline_rounded,
                  size: 32, color: AlpesColors.arenaCalida.withOpacity(0.5)),
              const SizedBox(height: 8),
              const Text('Sin eventos de seguimiento aún',
                  style:
                      TextStyle(fontSize: 12, color: AlpesColors.arenaCalida)),
              const SizedBox(height: 4),
              const Text('Te notificaremos cuando haya actualizaciones',
                  style:
                      TextStyle(fontSize: 10, color: AlpesColors.arenaCalida),
                  textAlign: TextAlign.center),
            ]),
          )
        else
          Column(
            children: eventos.asMap().entries.map((e) {
              final i = e.key;
              final evento = e.value;
              final esUltimo = i == eventos.length - 1;
              final ubicacion = (evento['UBICACION_TEXTO'] ??
                      evento['ubicacion_texto'] ??
                      'Actualización')
                  .toString();
              final observacion =
                  (evento['OBSERVACION'] ?? evento['observacion'] ?? '')
                      .toString();
              final partesFecha =
                  (evento['FECHA_EVENTO'] ?? evento['fecha_evento'] ?? '')
                      .toString()
                      .split('T');
              final fechaStr = partesFecha.isNotEmpty ? partesFecha[0] : '';
              final horaStr = partesFecha.length > 1
                  ? partesFecha[1].substring(
                      0, partesFecha[1].length >= 5 ? 5 : partesFecha[1].length)
                  : '';

              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: esUltimo ? _colorEstado(estado) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: esUltimo
                                  ? _colorEstado(estado)
                                  : AlpesColors.arenaCalida,
                              width: 2),
                        ),
                        child: esUltimo
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 10)
                            : Center(
                                child: Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                    color: AlpesColors.arenaCalida,
                                    shape: BoxShape.circle),
                              )),
                      ),
                      if (!esUltimo)
                        Container(
                            width: 1.5,
                            height: observacion.isNotEmpty ? 64 : 48,
                            color: AlpesColors.pergamino),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: esUltimo ? 0 : 10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: esUltimo
                                ? _bgEstado(estado).withOpacity(0.5)
                                : AlpesColors.cremaFondo,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: esUltimo
                                    ? _colorEstado(estado).withOpacity(0.2)
                                    : AlpesColors.pergamino),
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(ubicacion,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: esUltimo
                                                ? _colorEstado(estado)
                                                : AlpesColors.cafeOscuro)),
                                  ),
                                  if (fechaStr.isNotEmpty)
                                    Text(
                                        horaStr.isNotEmpty
                                            ? '$fechaStr · $horaStr'
                                            : fechaStr,
                                        style: const TextStyle(
                                            fontSize: 9,
                                            color: AlpesColors.arenaCalida,
                                            fontWeight: FontWeight.w500)),
                                ]),
                                if (observacion.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(observacion,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AlpesColors.nogalMedio,
                                          height: 1.4)),
                                ],
                              ]),
                        ),
                      ),
                    ),
                  ]);
            }).toList(),
          ),
      ]),
    );
  }
}
