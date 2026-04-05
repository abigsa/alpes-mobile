import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import '../../../providers/auth_provider.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});
  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  List<Map<String, dynamic>> _usuarios = [];
  bool _loading = true;
  bool _notifVentas   = true;
  bool _notifStock    = true;
  bool _notifPedidos  = false;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.usuarios));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        setState(() => _usuarios = List<Map<String, dynamic>>.from(data['data']));
      }
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  Future<void> _eliminarUsuario(dynamic id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Eliminar usuario'),
        content: const Text('¿Estás seguro de eliminar este usuario?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AlpesColors.rojoColonial),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await http.delete(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarios}/$id'));
    _cargar();
  }

  void _abrirFormUsuario([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _UsuarioForm(item: item, onGuardado: _cargar),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final username = auth.usuario?['USERNAME'] ?? auth.usuario?['username'] ?? 'Admin';
    final email    = auth.usuario?['EMAIL']    ?? auth.usuario?['email']    ?? '';

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('CONFIGURACIÓN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : RefreshIndicator(
              color: AlpesColors.cafeOscuro,
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  // ── Perfil actual ──
                  _sectionLabel('Mi perfil'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDeco(),
                    child: Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                            color: AlpesColors.oroGuatemalteco,
                            borderRadius: BorderRadius.circular(14)),
                        alignment: Alignment.center,
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'A',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                              color: AlpesColors.cafeOscuro),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(username,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                  color: AlpesColors.cafeOscuro)),
                          if (email.isNotEmpty)
                            Text(email,
                                style: const TextStyle(fontSize: 12, color: AlpesColors.nogalMedio)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: AlpesColors.oroGuatemalteco.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20)),
                            child: const Text('Administrador',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: AlpesColors.cafeOscuro)),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Notificaciones ──
                  _sectionLabel('Notificaciones'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: _cardDeco(),
                    child: Column(children: [
                      _switchTile('Alertas de ventas', 'Notificar al registrar una venta',
                          Icons.receipt_long_rounded, _notifVentas,
                          (v) => setState(() => _notifVentas = v)),
                      _divider(),
                      _switchTile('Stock bajo', 'Alertar cuando el inventario sea bajo',
                          Icons.inventory_2_rounded, _notifStock,
                          (v) => setState(() => _notifStock = v)),
                      _divider(),
                      _switchTile('Nuevos pedidos', 'Notificar al recibir un pedido',
                          Icons.shopping_bag_rounded, _notifPedidos,
                          (v) => setState(() => _notifPedidos = v)),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Módulos rápidos ──
                  _sectionLabel('Módulos del sistema'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: _cardDeco(),
                    child: Column(children: [
                      _navTile(Icons.people_alt_rounded,   'Gestión de roles',     '/admin/empleados'),
                      _divider(),
                      _navTile(Icons.local_shipping_rounded,'Zonas de envío',      '/admin/proveedores'),
                      _divider(),
                      _navTile(Icons.bar_chart_rounded,    'Ver reportes',         '/admin/reportes'),
                      _divider(),
                      _navTile(Icons.campaign_rounded,     'Campañas de marketing','/admin/marketing'),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Usuarios del sistema ──
                  Row(children: [
                    Expanded(child: _sectionLabel('Usuarios del sistema')),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Agregar', style: TextStyle(fontSize: 12)),
                      onPressed: () => _abrirFormUsuario(),
                      style: TextButton.styleFrom(foregroundColor: AlpesColors.cafeOscuro),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  if (_usuarios.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _cardDeco(),
                      child: const Center(
                        child: Text('Sin usuarios registrados',
                            style: TextStyle(color: AlpesColors.nogalMedio, fontSize: 13)),
                      ),
                    )
                  else
                    Container(
                      decoration: _cardDeco(),
                      child: Column(
                        children: List.generate(_usuarios.length * 2 - 1, (i) {
                          if (i.isOdd) return _divider();
                          final u = _usuarios[i ~/ 2];
                          final uid  = u['USU_ID'] ?? u['usu_id'] ?? u['ID'] ?? u['id'];
                          final uname= u['USERNAME'] ?? u['username'] ?? '';
                          final uemail= u['EMAIL'] ?? u['email'] ?? '';
                          final uinitial = uname.isNotEmpty ? uname[0].toUpperCase() : 'U';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                  color: AlpesColors.cafeOscuro.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(9)),
                              alignment: Alignment.center,
                              child: Text(uinitial,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                      color: AlpesColors.cafeOscuro)),
                            ),
                            title: Text(uname,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(uemail,
                                style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              _iconBtn(Icons.edit_outlined, AlpesColors.nogalMedio,
                                  () => _abrirFormUsuario(u)),
                              const SizedBox(width: 4),
                              _iconBtn(Icons.delete_outline, AlpesColors.rojoColonial,
                                  () => _eliminarUsuario(uid)),
                            ]),
                          );
                        }),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Cerrar sesión ──
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded, color: AlpesColors.rojoColonial),
                    label: const Text('Cerrar sesión',
                        style: TextStyle(color: AlpesColors.rojoColonial, fontWeight: FontWeight.w600)),
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) context.go('/login');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AlpesColors.rojoColonial),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String label) => Row(children: [
    Container(width: 3, height: 15,
        decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
        color: AlpesColors.cafeOscuro)),
  ]);

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AlpesColors.pergamino),
    boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
        blurRadius: 8, offset: const Offset(0, 2))],
  );

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16,
      color: AlpesColors.pergamino);

  Widget _switchTile(String title, String subtitle, IconData icon,
      bool value, ValueChanged<bool> onChanged) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.07),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 18, color: AlpesColors.cafeOscuro),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AlpesColors.cafeOscuro,
        ),
      );

  Widget _navTile(IconData icon, String label, String route) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.07),
          borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 18, color: AlpesColors.cafeOscuro),
    ),
    title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    trailing: const Icon(Icons.chevron_right_rounded, color: AlpesColors.arenaCalida),
    onTap: () => context.go(route),
  );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: color),
    ),
  );
}

// ─── FORM USUARIO ─────────────────────────────────────────

class _UsuarioForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;
  const _UsuarioForm({this.item, required this.onGuardado});
  @override
  State<_UsuarioForm> createState() => __UsuarioFormState();
}

class __UsuarioFormState extends State<_UsuarioForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _c = {
      'username': TextEditingController(),
      'email'   : TextEditingController(),
      'rol_id'  : TextEditingController(),
      'estado'  : TextEditingController(),
    };
    if (widget.item != null) {
      for (final k in _c.keys) {
        _c[k]!.text = '${widget.item![k.toUpperCase()] ?? widget.item![k] ?? ''}';
      }
    }
  }

  @override
  void dispose() { _c.values.forEach((c) => c.dispose()); super.dispose(); }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = _c.map((k, v) => MapEntry(k, v.text.trim()));
      final idKey = widget.item?.keys.firstWhere(
              (k) => k.toLowerCase().contains('id'), orElse: () => '') ?? '';
      final id = idKey.isNotEmpty ? widget.item![idKey] : null;
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarios}${id != null ? '/$id' : ''}');
      final res = id != null
          ? await http.put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          : await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        widget.onGuardado();
        if (context.mounted) Navigator.pop(context);
      } else {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['mensaje'] ?? 'Error'),
                backgroundColor: AlpesColors.rojoColonial));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AlpesColors.rojoColonial));
    } finally { setState(() => _guardando = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AlpesColors.pergamino,
                      borderRadius: BorderRadius.circular(2)))),
              Text(widget.item == null ? 'Nuevo usuario' : 'Editar usuario',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: AlpesColors.cafeOscuro)),
              const SizedBox(height: 16),
              TextFormField(controller: _c['username'],
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => v!.trim().isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _c['email'],
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextFormField(controller: _c['rol_id'],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rol ID')),
              const SizedBox(height: 12),
              TextFormField(controller: _c['estado'],
                  decoration: const InputDecoration(labelText: 'Estado',
                      hintText: 'ACTIVO / INACTIVO')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('GUARDAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
