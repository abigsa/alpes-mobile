import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import '../../../providers/cupon_provider.dart';

import '../../../providers/auth_provider.dart';

class CuponesScreen extends StatefulWidget {
  const CuponesScreen({super.key});

  @override
  State<CuponesScreen> createState() => _CuponesScreenState();
}

class _CuponesScreenState extends State<CuponesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CuponProvider>().cargarCupones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Cupones'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown,
        child: const Icon(Icons.add),
        onPressed: () => _mostrarDialogoCrear(context),
      ),
      body: Consumer<CuponProvider>(
        builder: (context, provider, _) {
          if (provider.cargando && provider.cupones.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.cupones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No hay cupones creados',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.cupones.length,
            itemBuilder: (context, index) {
              final cupon = provider.cupones[index];
              return _tarjetaCupon(context, cupon);
            },
          );
        },
      ),
    );
  }

  Widget _tarjetaCupon(BuildContext context, Map<String, dynamic> cupon) {
    final estaActivo = _esCuponActivo(cupon);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(
          Icons.local_offer,
          color: estaActivo ? Colors.brown : Colors.grey,
        ),
        title: Text(
          cupon['codigo'] ?? 'SIN CÓDIGO',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          cupon['descripcion'] ?? 'Sin descripción',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              estaActivo ? 'Activo' : 'Inactivo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: estaActivo ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fila('Descripción', cupon['descripcion'] ?? 'N/A'),
                const Divider(),
                _fila('Vigencia', _formatearVigencia(cupon)),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: _fila(
                          'Uso total', '${cupon['limite_uso_total']} usos'),
                    ),
                    Expanded(
                      child: _fila('Por cliente',
                          '${cupon['limite_uso_por_cliente']} usos'),
                    ),
                  ],
                ),
                const Divider(),
                _fila('Usos actuales', '${cupon['usos_actuales'] ?? 0}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoEditar(context, cupon),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _confirmarEliminar(context, cupon['cupon_id']),
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatearVigencia(Map<String, dynamic> cupon) {
    try {
      if (cupon['vigencia_inicio'] == null || cupon['vigencia_fin'] == null) {
        return 'Sin vigencia';
      }
      // Convertir de timestamp a DateTime si es necesario
      var inicio = cupon['vigencia_inicio'];
      var fin = cupon['vigencia_fin'];

      if (inicio is num) {
        inicio = DateTime.fromMillisecondsSinceEpoch(inicio.toInt());
      } else {
        inicio = DateTime.parse(inicio.toString());
      }

      if (fin is num) {
        fin = DateTime.fromMillisecondsSinceEpoch(fin.toInt());
      } else {
        fin = DateTime.parse(fin.toString());
      }

      return '${DateFormat('dd/MM/yyyy').format(inicio)} - ${DateFormat('dd/MM/yyyy').format(fin)}';
    } catch (e) {
      return 'Vigencia inválida';
    }
  }

  Widget _fila(String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(valor,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  bool _esCuponActivo(Map<String, dynamic> cupon) {
    try {
      final hoy = DateTime.now();
      final inicio = DateTime.parse(cupon['vigencia_inicio']?.toString() ?? '');
      final fin = DateTime.parse(cupon['vigencia_fin']?.toString() ?? '');
      final usosRestantes =
          (cupon['limite_uso_total'] ?? 0) - (cupon['usos_actuales'] ?? 0);
      return hoy.isAfter(inicio) && hoy.isBefore(fin) && usosRestantes > 0;
    } catch (_) {
      return false;
    }
  }

  void _mostrarDialogoCrear(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _DialogoFormularioCupon(
        titulo: 'Crear Cupón',
        onGuardar: (datos) async {
          final provider = context.read<CuponProvider>();
          final resultado = await provider.crearCupon(
            codigo: datos['codigo'],
            descripcion: datos['descripcion'],
            tipoDescuento: datos['tipoDescuento'],
            valorDescuento: datos['valorDescuento'],
            vigenciaInicio: datos['vigenciaInicio'],
            vigenciaFin: datos['vigenciaFin'],
            limiteUsoTotal: datos['limiteUsoTotal'],
            limiteUsoPorCliente: datos['limiteUsoPorCliente'],
          );

          if (mounted) {
            if (resultado) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Cupón creado exitosamente'),
                    backgroundColor: Colors.green),
              );
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(provider.mensajeCupon ?? 'Error'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  void _mostrarDialogoEditar(BuildContext context, Map<String, dynamic> cupon) {
    showDialog(
      context: context,
      builder: (context) => _DialogoFormularioCupon(
        titulo: 'Editar Cupón',
        cuponActual: cupon,
        onGuardar: (datos) async {
          final provider = context.read<CuponProvider>();
          final resultado = await provider.actualizarCupon(
            cuponId: cupon['cupon_id'],
            codigo: datos['codigo'],
            descripcion: datos['descripcion'],
            tipoDescuento: datos['tipoDescuento'],
            valorDescuento: datos['valorDescuento'],
            vigenciaInicio: datos['vigenciaInicio'],
            vigenciaFin: datos['vigenciaFin'],
            limiteUsoTotal: datos['limiteUsoTotal'],
            limiteUsoPorCliente: datos['limiteUsoPorCliente'],
          );

          if (mounted) {
            if (resultado) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Cupón actualizado'),
                    backgroundColor: Colors.green),
              );
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(provider.mensajeCupon ?? 'Error'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, int cuponId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cupón'),
        content: const Text('¿Estás seguro?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<CuponProvider>();
              final resultado = await provider.eliminarCupon(cuponId);
              if (mounted) {
                Navigator.pop(context);
                if (resultado) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Cupón eliminado'),
                        backgroundColor: Colors.green),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DialogoFormularioCupon extends StatefulWidget {
  final String titulo;
  final Map<String, dynamic>? cuponActual;
  final Function(Map<String, dynamic>) onGuardar;

  const _DialogoFormularioCupon({
    required this.titulo,
    this.cuponActual,
    required this.onGuardar,
  });

  @override
  State<_DialogoFormularioCupon> createState() =>
      _DialogoFormularioCuponState();
}

class _DialogoFormularioCuponState extends State<_DialogoFormularioCupon> {
  late TextEditingController _codigoCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _valorCtrl;
  late TextEditingController _limiteUsoCtrl;
  late TextEditingController _limiteClienteCtrl;
  String _tipoDescuento = 'porcentaje';
  late DateTime _vigenciaInicio;
  late DateTime _vigenciaFin;

  @override
  void initState() {
    super.initState();
    _codigoCtrl =
        TextEditingController(text: widget.cuponActual?['codigo'] ?? '');
    _descripcionCtrl =
        TextEditingController(text: widget.cuponActual?['descripcion'] ?? '');
    _valorCtrl = TextEditingController(
        text: widget.cuponActual?['valor_descuento']?.toString() ?? '');
    _limiteUsoCtrl = TextEditingController(
        text: widget.cuponActual?['limite_uso_total']?.toString() ?? '100');
    _limiteClienteCtrl = TextEditingController(
        text: widget.cuponActual?['limite_uso_por_cliente']?.toString() ?? '1');
    _tipoDescuento = widget.cuponActual?['tipo_descuento'] ?? 'porcentaje';

    try {
      if (widget.cuponActual != null) {
        final inicio = widget.cuponActual!['vigencia_inicio'];
        final fin = widget.cuponActual!['vigencia_fin'];

        _vigenciaInicio =
            inicio != null ? DateTime.parse(inicio.toString()) : DateTime.now();
        _vigenciaFin = fin != null
            ? DateTime.parse(fin.toString())
            : DateTime.now().add(const Duration(days: 30));
      } else {
        _vigenciaInicio = DateTime.now();
        _vigenciaFin = DateTime.now().add(const Duration(days: 30));
      }
    } catch (e) {
      _vigenciaInicio = DateTime.now();
      _vigenciaFin = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _descripcionCtrl.dispose();
    _valorCtrl.dispose();
    _limiteUsoCtrl.dispose();
    _limiteClienteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _codigoCtrl,
                decoration: const InputDecoration(
                    labelText: 'Código', hintText: 'DESCUENTO50')),
            const SizedBox(height: 12),
            TextField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(labelText: 'Descripción')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _tipoDescuento,
                    items: const [
                      DropdownMenuItem(
                          value: 'porcentaje', child: Text('Porcentaje (%)')),
                      DropdownMenuItem(
                          value: 'fijo', child: Text('Monto fijo')),
                    ],
                    onChanged: (val) =>
                        setState(() => _tipoDescuento = val ?? 'porcentaje'),
                    decoration: const InputDecoration(labelText: 'Tipo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                      controller: _valorCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: _tipoDescuento == 'porcentaje'
                              ? 'Valor (%)'
                              : 'Valor (\$)')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _limiteUsoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Límite uso total'))),
                const SizedBox(width: 12),
                Expanded(
                    child: TextField(
                        controller: _limiteClienteCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Por cliente'))),
              ],
            ),
            const SizedBox(height: 12),
            _selectorfecha('Inicio', _vigenciaInicio,
                (f) => setState(() => _vigenciaInicio = f)),
            const SizedBox(height: 8),
            _selectorfecha(
                'Fin', _vigenciaFin, (f) => setState(() => _vigenciaFin = f)),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }

  Widget _selectorfecha(
      String label, DateTime fecha, Function(DateTime) onChanged) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
            context: context,
            initialDate: fecha,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030));
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(DateFormat('dd/MM/yyyy').format(fecha),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _guardar() {
    if (_codigoCtrl.text.isEmpty ||
        _descripcionCtrl.text.isEmpty ||
        _valorCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Completa todos los campos'),
          backgroundColor: Colors.red));
      return;
    }
    widget.onGuardar({
      'codigo': _codigoCtrl.text,
      'descripcion': _descripcionCtrl.text,
      'tipoDescuento': _tipoDescuento,
      'valorDescuento': double.parse(_valorCtrl.text),
      'vigenciaInicio': _vigenciaInicio,
      'vigenciaFin': _vigenciaFin,
      'limiteUsoTotal': int.parse(_limiteUsoCtrl.text),
      'limiteUsoPorCliente': int.parse(_limiteClienteCtrl.text),
    });
  }
}
