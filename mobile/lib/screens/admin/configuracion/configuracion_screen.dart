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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar usuario', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AlpesColors.rojoColonial,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _UsuarioForm(item: item, onGuardado: _cargar),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final username = auth.usuario?['USERNAME'] ?? auth.usuario?['username'] ?? 'Admin';
    final email    = auth.usuario?['EMAIL']    ?? auth.usuario?['email']    ?? '';
    final initial  = username.isNotEmpty ? username[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AlpesColors.cafeOscuro,
            leading: IconButton(
              icon: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
              ),
              onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text('Configuración',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
              background: Stack(children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A0E08), Color(0xFF2C1810), Color(0xFF3D2416)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(top: -30, right: -30,
                  child: Container(width: 140, height: 140,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: AlpesColors.oroGuatemalteco.withOpacity(0.08)))),
                Positioned(bottom: 0, right: 60,
                  child: Container(width: 60, height: 60,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: AlpesColors.oroGuatemalteco.withOpacity(0.05)))),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Perfil admin ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AlpesColors.pergamino),
                    boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.06),
                      blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Row(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8B84B), Color(0xFFD4A853)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(initial, style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: AlpesColors.cafeOscuro)),
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
                        decoration: BoxDecoration(
                          color: AlpesColors.cafeOscuro.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Administrador', style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: AlpesColors.cafeOscuro)),
                      ),
                    ])),
                    IconButton(
                      icon: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: AlpesColors.cafeOscuro.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 16, color: AlpesColors.cafeOscuro),
                      ),
                      onPressed: () {},
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Notificaciones ──
                _sectionHeader('Notificaciones', Icons.notifications_rounded),
                const SizedBox(height: 10),
                _notifCard([
                  _NotifItem('Ventas nuevas', 'Recibe alertas al recibir un pedido',
                    Icons.shopping_bag_rounded, _notifVentas,
                    (v) => setState(() => _notifVentas = v)),
                  _NotifItem('Stock bajo', 'Alerta cuando un producto baja del mínimo',
                    Icons.inventory_2_rounded, _notifStock,
                    (v) => setState(() => _notifStock = v)),
                  _NotifItem('Pedidos en proceso', 'Actualización de estado de órdenes',
                    Icons.local_shipping_rounded, _notifPedidos,
                    (v) => setState(() => _notifPedidos = v)),
                ]),
                const SizedBox(height: 20),

                // ── Usuarios del sistema ──
                Row(children: [
                  Expanded(child: _sectionHeader('Usuarios del sistema', Icons.people_rounded)),
                  GestureDetector(
                    onTap: () => _abrirFormUsuario(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AlpesColors.cafeOscuro,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Nuevo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),

                _loading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AlpesColors.cafeOscuro)))
                  : _usuarios.isEmpty
                    ? _emptyState('No hay usuarios registrados')
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AlpesColors.pergamino),
                          boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
                            blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(children: List.generate(_usuarios.length, (i) {
                          final u = _usuarios[i];
                          final uname = '${u['USERNAME'] ?? u['username'] ?? ''}';
                          final uemail = '${u['EMAIL'] ?? u['email'] ?? ''}';
                          final rol = '${u['ROL'] ?? u['rol'] ?? 'Usuario'}';
                          final uid = u['USUARIO_ID'] ?? u['usuario_id'];
                          final ini = uname.isNotEmpty ? uname[0].toUpperCase() : 'U';
                          return Column(children: [
                            ListTile(
                              leading: Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: AlpesColors.cafeOscuro.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(ini, style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: AlpesColors.cafeOscuro)),
                              ),
                              title: Text(uname.isNotEmpty ? uname : 'Sin nombre',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: AlpesColors.cafeOscuro)),
                              subtitle: uemail.isNotEmpty
                                ? Text(uemail, style: const TextStyle(fontSize: 12,
                                    color: AlpesColors.nogalMedio))
                                : null,
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AlpesColors.cafeOscuro.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(rol, style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w600,
                                    color: AlpesColors.cafeOscuro)),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _abrirFormUsuario(u),
                                  child: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: AlpesColors.cafeOscuro.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.edit_rounded, size: 14,
                                      color: AlpesColors.cafeOscuro),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _eliminarUsuario(uid),
                                  child: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: AlpesColors.rojoColonial.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded, size: 14,
                                      color: AlpesColors.rojoColonial),
                                  ),
                                ),
                              ]),
                            ),
                            if (i < _usuarios.length - 1)
                              const Divider(height: 1, indent: 70, endIndent: 16,
                                color: AlpesColors.pergamino),
                          ]);
                        })),
                      ),
                const SizedBox(height: 20),

                // ── Cerrar sesión ──
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AlpesColors.rojoColonial.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AlpesColors.rojoColonial.withOpacity(0.15)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AlpesColors.rojoColonial.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout_rounded, color: AlpesColors.rojoColonial, size: 18),
                    ),
                    title: const Text('Cerrar sesión',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: AlpesColors.rojoColonial)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AlpesColors.rojoColonial),
                    onTap: () async {
                      await auth.logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Center(child: Text('Muebles de los Alpes v1.0',
                  style: TextStyle(fontSize: 11, color: AlpesColors.arenaCalida.withOpacity(0.6)))),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Row(children: [
    Icon(icon, size: 16, color: AlpesColors.oroGuatemalteco),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
      color: AlpesColors.cafeOscuro)),
  ]);

  Widget _notifCard(List<_NotifItem> items) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AlpesColors.pergamino),
      boxShadow: [BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.05),
        blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(children: List.generate(items.length, (i) {
      final item = items[i];
      return Column(children: [
        ListTile(
          leading: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AlpesColors.cafeOscuro.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 17, color: AlpesColors.cafeOscuro),
          ),
          title: Text(item.title, style: const TextStyle(fontSize: 14,
            fontWeight: FontWeight.w600, color: AlpesColors.cafeOscuro)),
          subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 11,
            color: AlpesColors.nogalMedio)),
          trailing: Switch(
            value: item.value,
            onChanged: item.onChanged,
            activeColor: AlpesColors.cafeOscuro,
            activeTrackColor: AlpesColors.cafeOscuro.withOpacity(0.3),
          ),
        ),
        if (i < items.length - 1)
          const Divider(height: 1, indent: 66, endIndent: 16, color: AlpesColors.pergamino),
      ]);
    })),
  );

  Widget _emptyState(String msg) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AlpesColors.pergamino)),
    child: Center(child: Text(msg,
      style: const TextStyle(color: AlpesColors.nogalMedio))),
  );
}

class _NotifItem {
  final String title, subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifItem(this.title, this.subtitle, this.icon, this.value, this.onChanged);
}

// ── Formulario de usuario ────────────────────────────────
class _UsuarioForm extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onGuardado;
  const _UsuarioForm({this.item, required this.onGuardado});
  @override
  State<_UsuarioForm> createState() => _UsuarioFormState();
}

class _UsuarioFormState extends State<_UsuarioForm> {
  final _formKey  = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _guardando  = false;
  bool _verPass    = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _userCtrl.text  = '${widget.item!['USERNAME'] ?? widget.item!['username'] ?? ''}';
      _emailCtrl.text = '${widget.item!['EMAIL']    ?? widget.item!['email']    ?? ''}';
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = {
        'username': _userCtrl.text.trim(),
        'email':    _emailCtrl.text.trim(),
        if (_passCtrl.text.isNotEmpty) 'password': _passCtrl.text,
      };
      final id = widget.item?['USUARIO_ID'] ?? widget.item?['usuario_id'];
      if (id != null) {
        await http.put(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarios}/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } else {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarios}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      }
      if (mounted) { Navigator.pop(context); widget.onGuardado(); }
    } catch (_) {} finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AlpesColors.pergamino,
                borderRadius: BorderRadius.circular(2))),
            Text(widget.item != null ? 'Editar usuario' : 'Nuevo usuario',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                color: AlpesColors.cafeOscuro)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _userCtrl,
              decoration: const InputDecoration(labelText: 'Usuario',
                prefixIcon: Icon(Icons.person_rounded)),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Correo',
                prefixIcon: Icon(Icons.email_rounded)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtrl,
              obscureText: !_verPass,
              decoration: InputDecoration(
                labelText: widget.item != null ? 'Nueva contraseña (opcional)' : 'Contraseña',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_verPass ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  onPressed: () => setState(() => _verPass = !_verPass),
                ),
              ),
              validator: (v) {
                if (widget.item == null && (v == null || v.isEmpty)) return 'Requerido';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AlpesColors.cafeOscuro,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _guardando
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(widget.item != null ? 'Actualizar' : 'Crear usuario',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
