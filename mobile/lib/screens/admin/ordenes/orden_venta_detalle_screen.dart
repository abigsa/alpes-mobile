import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class OrdenVentaDetalleScreen extends StatefulWidget {
  final int ordenId;

  const OrdenVentaDetalleScreen({
    super.key,
    required this.ordenId,
  });

  @override
  State<OrdenVentaDetalleScreen> createState() => _OrdenVentaDetalleScreenState();
}

class _OrdenVentaDetalleScreenState extends State<OrdenVentaDetalleScreen> {
  Map<String, dynamic>? _orden;
  List<Map<String, dynamic>> _detalles = [];
  List<Map<String, dynamic>> _estadosOrden = [];
  bool _loading = true;
  bool _guardandoEstado = false;

  int? _estadoOrdenIdSeleccionado;
  int? _estadoOrdenIdOriginal;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}/${widget.ordenId}'),
        ),
        http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.ordenVentaDet}/buscar?criterio=orden_venta_id&valor=${widget.ordenId}',
          ),
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.estadoOrden}'),
        ),
      ]);

      final ordenData = jsonDecode(responses[0].body);
      final detalleData = jsonDecode(responses[1].body);
      final estadosData = jsonDecode(responses[2].body);

      if (!mounted) return;

      setState(() {
        if (ordenData['ok'] == true) {
          _orden = Map<String, dynamic>.from(ordenData['data']);
          _estadoOrdenIdSeleccionado = _toInt(
            _orden!['ESTADO_ORDEN_ID'] ?? _orden!['estado_orden_id'],
          );
          _estadoOrdenIdOriginal = _estadoOrdenIdSeleccionado;
        }

        if (detalleData['ok'] == true) {
          _detalles = List<Map<String, dynamic>>.from(detalleData['data']);
        }

        if (estadosData['ok'] == true) {
          _estadosOrden = List<Map<String, dynamic>>.from(estadosData['data']);
        }

        _estadoOrdenIdSeleccionado = _validIntDropdownValue(
          _estadoOrdenIdSeleccionado,
          _estadosActivos
              .map((e) => _toInt(e['ESTADO_ORDEN_ID']))
              .whereType<int>()
              .toList(),
        );
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _estadosActivos => _estadosOrden
      .where((e) => '${e['ESTADO'] ?? ''}'.toUpperCase() == 'ACTIVO')
      .toList();

  int? _toInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse('$value');
  }

  int? _validIntDropdownValue(int? value, List<int> items) {
    if (value == null) return null;
    return items.contains(value) ? value : null;
  }

  String _resolverEstadoOrden(dynamic estadoOrdenId) {
    for (final estado in _estadosOrden) {
      if ('${estado['ESTADO_ORDEN_ID']}' == '$estadoOrdenId') {
        return '${estado['CODIGO'] ?? ''}'.trim();
      }
    }
    return '';
  }

  String _capitalizar(String value) {
    if (value.trim().isEmpty) return value;
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  String _normalizarFecha(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '';
    final raw = value.toString().trim();
    if (raw.contains('T')) return raw.split('T').first;
    return raw;
  }

  Future<bool> _confirmarCambioEstado() async {
    if (_orden == null || _estadoOrdenIdSeleccionado == null) return false;

    final estadoActual = _capitalizar(
      _resolverEstadoOrden(
        _orden!['ESTADO_ORDEN_ID'] ?? _orden!['estado_orden_id'],
      ),
    );

    final nuevoEstado = _capitalizar(
      _resolverEstadoOrden(_estadoOrdenIdSeleccionado),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text('Actualizar estado'),
        content: Text(
          '¿Deseas cambiar el estado de "$estadoActual" a "$nuevoEstado"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AlpesColors.cafeOscuro,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return ok == true;
  }

  Future<void> _actualizarEstado() async {
    if (_orden == null || _estadoOrdenIdSeleccionado == null) return;
    if (_estadoOrdenIdSeleccionado == _estadoOrdenIdOriginal) return;

    final confirmado = await _confirmarCambioEstado();
    if (!confirmado) return;

    setState(() => _guardandoEstado = true);

    try {
      final body = {
        'orden_venta_id': _orden!['ORDEN_VENTA_ID'] ?? _orden!['orden_venta_id'],
        'num_orden': _orden!['NUM_ORDEN'] ?? _orden!['num_orden'],
        'cli_id': _orden!['CLI_ID'] ?? _orden!['cli_id'],
        'estado_orden_id': _estadoOrdenIdSeleccionado,
        'fecha_orden': _normalizarFecha(
          _orden!['FECHA_ORDEN'] ?? _orden!['fecha_orden'],
        ),
        'subtotal': _orden!['SUBTOTAL'] ?? _orden!['subtotal'],
        'descuento': _orden!['DESCUENTO'] ?? _orden!['descuento'],
        'impuesto': _orden!['IMPUESTO'] ?? _orden!['impuesto'],
        'total': _orden!['TOTAL'] ?? _orden!['total'],
        'moneda': _orden!['MONEDA'] ?? _orden!['moneda'],
        'direccion_envio_snapshot': _orden!['DIRECCION_ENVIO_SNAPSHOT'] ??
            _orden!['direccion_envio_snapshot'],
        'observaciones': _orden!['OBSERVACIONES'] ?? _orden!['observaciones'],
        'estado': _orden!['ESTADO'] ?? _orden!['estado'] ?? 'ACTIVO',
      };

      final id = _orden!['ORDEN_VENTA_ID'] ?? _orden!['orden_venta_id'];

      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenVenta}/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        _estadoOrdenIdOriginal = _estadoOrdenIdSeleccionado;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estado actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _cargar();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['mensaje'] ?? 'Error al actualizar estado'),
              backgroundColor: AlpesColors.rojoColonial,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AlpesColors.rojoColonial,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardandoEstado = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoReal = _orden == null
        ? ''
        : _resolverEstadoOrden(
            _orden!['ESTADO_ORDEN_ID'] ?? _orden!['estado_orden_id'],
          );
    final estadoTexto = estadoReal.isEmpty ? '-' : _capitalizar(estadoReal);

    final estadosDropdown = _estadosActivos
        .map<DropdownMenuItem<int>?>((e) {
          final estadoId = _toInt(e['ESTADO_ORDEN_ID']);
          if (estadoId == null) return null;

          final codigo = '${e['CODIGO'] ?? ''}'.trim();
          return DropdownMenuItem<int>(
            value: estadoId,
            child: Text(
              codigo.isEmpty ? 'Estado #$estadoId' : _capitalizar(codigo),
            ),
          );
        })
        .whereType<DropdownMenuItem<int>>()
        .toList();

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: Text('ORDEN #${widget.ordenId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AlpesColors.cafeOscuro),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_orden != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Divider(),
                            Text(
                              'Orden: ${_orden!['NUM_ORDEN'] ?? _orden!['num_orden'] ?? '-'}',
                            ),
                            Text('Estado actual: $estadoTexto'),
                            Text(
                              'Fecha: ${_normalizarFecha(_orden!['FECHA_ORDEN'] ?? _orden!['fecha_orden'])}',
                            ),
                            Text(
                              'Total: Q ${_orden!['TOTAL'] ?? _orden!['total'] ?? 0}',
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              value: _estadoOrdenIdSeleccionado,
                              decoration: const InputDecoration(
                                labelText: 'Cambiar estado',
                              ),
                              items: estadosDropdown,
                              onChanged: (value) {
                                setState(() => _estadoOrdenIdSeleccionado = value);
                              },
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: (_guardandoEstado ||
                                      _estadoOrdenIdSeleccionado == null ||
                                      _estadoOrdenIdSeleccionado ==
                                          _estadoOrdenIdOriginal)
                                  ? null
                                  : _actualizarEstado,
                              child: _guardandoEstado
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('ACTUALIZAR ESTADO'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Productos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ..._detalles.map(
                    (d) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.chair_alt,
                          color: AlpesColors.nogalMedio,
                        ),
                        title: Text(
                          'Producto #${d['PRODUCTO_ID'] ?? d['producto_id']}',
                        ),
                        subtitle: Text(
                          'Cantidad: ${d['CANTIDAD'] ?? d['cantidad']}',
                        ),
                        trailing: Text(
                          'Q ${d['SUBTOTAL_LINEA'] ?? d['subtotal_linea'] ?? 0}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}