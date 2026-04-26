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
  bool _notifVentas  = true;
  bool _notifStock   = true;
  bool _notifPedidos = false;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final res  = await http.get(Uri.parse(ApiConfig.baseUrl + ApiConfig.usuarios));
      final data = jsonDecode(res.body);
      if (data['ok'] == true)
        setState(() => _usuarios = List<Map<String, dynamic>>.from(data['data']));
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  Future<void> _eliminarUsuario(dynamic id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Eliminar usuario', style: TextStyle(fontWeight: FontWeight.w700)),
      content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AlpesColors.rojoColonial,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Eliminar'),
        ),
      ],
    ));
    if (ok != true) return;
    await http.delete(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarios}/$id'));
    _cargar();
  }

  void _abrirFormUsuario([Map<String, dynamic>? item]) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _UsuarioForm(item: item, onGuardado: _cargar),
  );

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final username = auth.usuario?['USERNAME'] ?? auth.usuario?['username'] ?? 'Admin';
    final email    = auth.usuario?['EMAIL']    ?? auth.usuario?['email']    ?? '';
    final initial  = username.isNotEmpty ? username[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 150,
          pinned: true,
          backgroundColor: AlpesColors.cafeOscuro,
          leading: IconButton(
            icon: _iconBtn(Icons.arrow_back_ios_rounded),
            onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: const Text('Configuración', style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            background: Stack(children: [
              Container(decoration: const BoxDecoration(gradient: LinearGradient(
                colors: [Color(0xFF1A0E08), Color(0xFF2C1810), Color(0xFF3D2416)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ))),
              Positioned(top: -30, right: -30,
                child: Container(width: 140, height: 140,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: AlpesColors.oroGuatemalteco.withOpacity(0.08)))),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Perfil admin
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _card(),
              child: Row(children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE8B84B), Color(0xFFD4A853)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(initial, style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: AlpesColors.cafeOscuro)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(username, style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(email, style: const TextStyle(fontSize: 12, color: AlpesColors.nogalMedio)),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Administrador',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: AlpesColors.cafeOscuro)),
                  ),
                ])),
              ]),
            ),
            const SizedBox(height: 20),

            // Notificaciones
            _sectionTitle('Notificaciones', Icons.notifications_rounded),
            const SizedBox(height: 10),
            Container(
              decoration: _card(),
              child: Column(children: [
                _switchTile('Ventas nuevas', 'Alerta al recibir un pedido',
                    Icons.shopping_bag_rounded, _notifVentas, (v) => setState(() => _notifVentas = v)),
                const Divider(height: 1, indent: 66, endIndent: 16, color: AlpesColors.pergamino),
                _switchTile('Stock bajo', 'Producto bajo del mínimo',
                    Icons.inventory_2_rounded, _notifStock, (v) => setState(() => _notifStock = v)),
                const Divider(height: 1, indent: 66, endIndent: 16, color: AlpesColors.pergamino),
                _switchTile('Pedidos en proceso', 'Actualización de órdenes',
                    Icons.local_shipping_rounded, _notifPedidos, (v) => setState(() => _notifPedidos = v)),
              ]),
            ),
            const SizedBox(height: 20),

            // Usuarios
            Row(children: [
              Expanded(child: _sectionTitle('Usuarios del sistema', Icons.people_rounded)),
              GestureDetector(
                onTap: _abrirFormUsuario,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                      color: AlpesColors.cafeOscuro, borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Nuevo', style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 10),

            _loading
                ? const Center(child: Padding(padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AlpesColors.cafeOscuro)))
                : _usuarios.isEmpty
                    ? Container(padding: const EdgeInsets.all(24), decoration: _card(),
                        child: const Center(child: Text('No hay usuarios registrados',
                            style: TextStyle(color: AlpesColors.nogalMedio))))
                    : Container(
                        decoration: _card(),
                        child: Column(children: List.generate(_usuarios.length, (i) {
                          final u = _usuarios[i];
                          final un = '${u['USERNAME'] ?? u['username'] ?? ''}';
                          final ue = '${u['EMAIL']    ?? u['email']    ?? ''}';
                          final ur = '${u['ROL']      ?? u['rol']      ?? 'Usuario'}';
                          final uid = u['USUARIO_ID'] ?? u['usuario_id'];
                          final ini = un.isNotEmpty ? un[0].toUpperCase() : 'U';
                          return Column(children: [
                            ListTile(
                              leading: Container(width: 42, height: 42,
                                  decoration: BoxDecoration(
                                      color: AlpesColors.cafeOscuro.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(13)),
                                  alignment: Alignment.center,
                                  child: Text(ini, style: const TextStyle(fontSize: 16,
                                      fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro))),
                              title: Text(un.isNotEmpty ? un : 'Sin nombre',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                      color: AlpesColors.cafeOscuro)),
                              subtitle: ue.isNotEmpty
                                  ? Text(ue, style: const TextStyle(fontSize: 12,
                                      color: AlpesColors.nogalMedio)) : null,
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(20)),
                                    child: Text(ur, style: const TextStyle(fontSize: 10,
                                        fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro))),
                                const SizedBox(width: 8),
                                _actionBtn(Icons.edit_rounded, AlpesColors.cafeOscuro,
                                    () => _abrirFormUsuario(u)),
                                const SizedBox(width: 6),
                                _actionBtn(Icons.delete_outline_rounded, AlpesColors.rojoColonial,
                                    () => _eliminarUsuario(uid)),
                              ]),
                            ),
                            if (i < _usuarios.length - 1)
                              const Divider(height: 1, indent: 70, endIndent: 16,
                                  color: AlpesColors.pergamino),
                          ]);
                        })),
                      ),
            const SizedBox(height: 20),

            // Cerrar sesión
            GestureDetector(
              onTap: () async { await auth.logout(); if (context.mounted) context.go('/login'); },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: AlpesColors.rojoColonial.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AlpesColors.rojoColonial.withOpacity(0.15))),
                child: ListTile(
                  leading: Container(width: 38, height: 38,
                      decoration: BoxDecoration(color: AlpesColors.rojoColonial.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(11)),
                      child: const Icon(Icons.logout_rounded, color: AlpesColors.rojoColonial, size: 17)),
                  title: const Text('Cerrar sesión', style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600, color: AlpesColors.rojoColonial)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: AlpesColors.rojoColonial),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(child: Text('Muebles de los Alpes v1.0',
                style: TextStyle(fontSize: 11, color: AlpesColors.arenaCalida.withOpacity(0.6)))),
            const SizedBox(height: 16),
          ]),
        )),
      ]),
    );
  }

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AlpesColors.pergamino),
    boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
        blurRadius: 10, offset: const Offset(0, 3))],
  );

  Widget _iconBtn(IconData i) => Container(
    width: 34, height: 34,
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2))),
    child: Icon(i, color: Colors.white, size: 16));

  Widget _sectionTitle(String t, IconData i) => Row(children: [
    Icon(i, size: 16, color: AlpesColors.oroGuatemalteco),
    const SizedBox(width: 8),
    Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
        color: AlpesColors.cafeOscuro)),
  ]);

  Widget _switchTile(String title, String sub, IconData icon, bool value, ValueChanged<bool> onChanged) =>
    ListTile(
      leading: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: AlpesColors.cafeOscuro.withOpacity(0.06),
              borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 17, color: AlpesColors.cafeOscuro)),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
          color: AlpesColors.cafeOscuro)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: AlpesColors.nogalMedio)),
      trailing: Switch(value: value, onChanged: onChanged,
          activeColor: AlpesColors.cafeOscuro,
          activeTrackColor: AlpesColors.cafeOscuro.withOpacity(0.3)),
    );

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 32, height: 32,
        decoration: BoxDecoration(color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 14, color: color)));
}

class _UsuarioForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;
  const _UsuarioForm({this.item, required this.onGuardado});
  @override
  State<_UsuarioForm> createState() => _UsuarioFormState();
}

class _UsuarioFormState extends State<_UsuarioForm> {
  final _fk = GlobalKey<FormState>();
  final _uc = TextEditingController();
  final _ec = TextEditingController();
  final _pc = TextEditingController();
  bool _loading = false;
  bool _verPass = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _uc.text = '${widget.item!['USERNAME'] ?? widget.item!['username'] ?? ''}';
      _ec.text = '${widget.item!['EMAIL']    ?? widget.item!['email']    ?? ''}';
    }
  }

  @override
  void dispose() { _uc.dispose(); _ec.dispose(); _pc.dispose(); super.dispose(); }

  Future<void> _guardar() async {
    if (!_fk.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final body = {'username': _uc.text.trim(), 'email': _ec.text.trim(),
        if (_pc.text.isNotEmpty) 'password': _pc.text};
      final id = widget.item?['USUARIO_ID'] ?? widget.item?['usuario_id'];
      if (id != null) {
        await http.put(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarios}/$id'),
            headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      } else {
        await http.post(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarios}'),
            headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      }
      if (mounted) { Navigator.pop(context); widget.onGuardado(); }
    } catch (_) {} finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Form(key: _fk, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: AlpesColors.pergamino, borderRadius: BorderRadius.circular(2))),
        Text(widget.item != null ? 'Editar usuario' : 'Nuevo usuario',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
        const SizedBox(height: 20),
        TextFormField(controller: _uc,
            decoration: const InputDecoration(labelText: 'Usuario',
                prefixIcon: Icon(Icons.person_rounded)),
            validator: (v) => v!.isEmpty ? 'Requerido' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _ec,
            decoration: const InputDecoration(labelText: 'Correo',
                prefixIcon: Icon(Icons.email_rounded)),
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        TextFormField(controller: _pc, obscureText: !_verPass,
            decoration: InputDecoration(
                labelText: widget.item != null ? 'Nueva contraseña (opcional)' : 'Contraseña',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                    icon: Icon(_verPass ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () => setState(() => _verPass = !_verPass))),
            validator: (v) => widget.item == null && (v == null || v.isEmpty) ? 'Requerido' : null),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _guardar,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.item != null ? 'Actualizar' : 'Crear usuario'),
          ),
        ),
      ])),
    ),
  );
}
