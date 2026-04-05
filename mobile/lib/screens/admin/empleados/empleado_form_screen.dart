import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme.dart';
import '../../../config/api_config.dart';

class EmpleadoFormScreen extends StatefulWidget {
  final int? empleadoId;
  const EmpleadoFormScreen({super.key, this.empleadoId});
  @override
  State<EmpleadoFormScreen> createState() => _EmpleadoFormScreenState();
}

class _EmpleadoFormScreenState extends State<EmpleadoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _salarioCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.empleadoId != null) _cargar();
  }

  Future<void> _cargar() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.empleados}/${widget.empleadoId}'));
    final data = jsonDecode(res.body);
    if (data['ok'] == true && data['data'] != null) {
      final emp = data['data'];
      _nombresCtrl.text = emp['NOMBRES'] ?? emp['nombres'] ?? '';
      _apellidosCtrl.text = emp['APELLIDOS'] ?? emp['apellidos'] ?? '';
      _emailCtrl.text = emp['EMAIL'] ?? emp['email'] ?? '';
      _telefonoCtrl.text = emp['TELEFONO'] ?? emp['telefono'] ?? '';
      _salarioCtrl.text = '${emp['SALARIO_BASE'] ?? emp['salario_base'] ?? ''}';
      setState(() {});
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = {
        'nombres': _nombresCtrl.text,
        'apellidos': _apellidosCtrl.text,
        'email': _emailCtrl.text,
        'telefono': _telefonoCtrl.text,
        'salario_base': double.tryParse(_salarioCtrl.text) ?? 0,
        'depto_id': 1,
        'cargo_id': 1,
        'rol_empleado_id': 1,
        'fecha_ingreso': DateTime.now().toIso8601String().split('T')[0],
        'estado': 'ACTIVO',
      };
      http.Response res;
      if (widget.empleadoId != null) {
        body['emp_id'] = widget.empleadoId!;
        res = await http.put(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.empleados}/${widget.empleadoId}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } else {
        res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.empleados}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      }
      final data = jsonDecode(res.body);
      if (data['ok'] == true && context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empleado guardado'), backgroundColor: AlpesColors.exito),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AlpesColors.rojoColonial),
      );
      }
    } finally { setState(() => _guardando = false); }
  }

  @override
  void dispose() {
    _nombresCtrl.dispose(); _apellidosCtrl.dispose();
    _emailCtrl.dispose(); _telefonoCtrl.dispose(); _salarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: Text(widget.empleadoId == null ? 'NUEVO EMPLEADO' : 'EDITAR EMPLEADO'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _nombresCtrl, decoration: const InputDecoration(labelText: 'Nombres'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _apellidosCtrl, decoration: const InputDecoration(labelText: 'Apellidos'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextFormField(controller: _telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
              const SizedBox(height: 12),
              TextFormField(controller: _salarioCtrl, decoration: const InputDecoration(labelText: 'Salario base', prefixText: 'Q '), keyboardType: TextInputType.number),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('GUARDAR EMPLEADO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
