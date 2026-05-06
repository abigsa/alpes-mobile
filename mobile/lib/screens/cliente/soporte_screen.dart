import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class SoporteScreen extends StatefulWidget {
  const SoporteScreen({super.key});
  @override
  State<SoporteScreen> createState() => _SoporteScreenState();
}

class _SoporteScreenState extends State<SoporteScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _typing   = false;
  bool _chatOpen = false;
  late AnimationController _animCtrl;
  late Animation<double>   _scaleAnim;

  final List<_Msg> _msgs = [
    _Msg('¡Hola! 👋 Soy **AlpesBot**, el asistente virtual de Muebles de los Alpes.\n\n'
        'Puedo ayudarte con:\n'
        '• 🕐 Horarios de atención\n'
        '• 📍 Ubicación de nuestras tiendas\n'
        '• 🛋️ Información de productos\n'
        '• 📦 Estado de pedidos\n\n'
        '¿En qué te puedo ayudar hoy?', false),
  ];

  final _quickReplies = [
    '¿Cuál es su horario?',
    '¿Dónde están ubicados?',
    'Ver productos',
    '¿Cómo sigo mi pedido?',
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 280));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() => _chatOpen = !_chatOpen);
    _chatOpen ? _animCtrl.forward() : _animCtrl.reverse();
  }

  String _responder(String msg) {
    final m = msg.toLowerCase();

    if (m.contains('horario') || m.contains('hora') || m.contains('abierto') ||
        m.contains('cuando') || m.contains('abren')) {
      return '🕐 **Horarios de atención:**\n\n'
          '• Lunes a Viernes: 8:00 AM – 6:00 PM\n'
          '• Sábado: 9:00 AM – 5:00 PM\n'
          '• Domingo: 10:00 AM – 2:00 PM\n\n'
          'También puedes realizar pedidos en línea las 24 horas. 😊';
    }
    if (m.contains('ubicaci') || m.contains('donde') || m.contains('direcci') ||
        m.contains('tienda') || m.contains('local')) {
      return '📍 **Nuestras ubicaciones en Guatemala:**\n\n'
          '• **Sucursal Central:** Zona 10, Ciudad de Guatemala\n'
          '• **Sucursal Norte:** Zona 18, Ciudad de Guatemala\n'
          '• **Sucursal Antigua:** 5a Avenida Norte, Antigua Guatemala\n\n'
          '¿Necesitas indicaciones para llegar?';
    }
    if (m.contains('producto') || m.contains('mueble') || m.contains('cat') ||
        m.contains('sala') || m.contains('comedor') || m.contains('cama') ||
        m.contains('silla') || m.contains('mesa') || m.contains('ver') ||
        m.contains('comprar')) {
      return '🛋️ ¡Tenemos una gran variedad de muebles artesanales guatemaltecos!\n\n'
          '• Salas y sillones\n'
          '• Comedores\n'
          '• Dormitorios\n'
          '• Muebles de oficina\n'
          '• Exterior\n\n'
          'Te llevo al catálogo ahora mismo. 👇';
    }
    if (m.contains('pedido') || m.contains('orden') || m.contains('seguimiento') ||
        m.contains('entrega') || m.contains('estado')) {
      return '📦 Para ver el estado de tu pedido:\n\n'
          '1. Ve a **"Mis pedidos"** en el menú\n'
          '2. Selecciona tu orden\n'
          '3. O usa **"Tracking"** en la pantalla de inicio\n\n'
          '¿Hay algo más que necesites?';
    }
    if (m.contains('precio') || m.contains('costo') || m.contains('cuanto') ||
        m.contains('vale') || m.contains('valor')) {
      return '💰 Los precios varían según el producto.\n\n'
          'Puedes ver todos los precios actualizados en nuestro catálogo.\n\n'
          '¿Te llevo al catálogo?';
    }
    if (m.contains('si') || m.contains('sí') || m.contains('claro') ||
        m.contains('ok') || m.contains('dale')) {
      return '¡Perfecto! Te llevo al catálogo ahora. 🛋️';
    }
    if (m.contains('gracias') || m.contains('listo') || m.contains('perfecto') ||
        m.contains('excelente')) {
      return '😊 ¡Con mucho gusto! Estoy aquí cuando me necesites.\n\n'
          '¿Hay algo más en lo que pueda ayudarte?';
    }
    if (m.contains('hola') || m.contains('buenos') || m.contains('buenas')) {
      return '¡Hola! 👋 ¿En qué te puedo ayudar hoy?\n\n'
          'Puedo darte información sobre horarios, ubicaciones, productos o pedidos.';
    }
    return '🤖 Entiendo. Nuestro equipo está disponible de **Lunes a Viernes 8AM–6PM**.\n\n'
        'También puedo ayudarte con:\n'
        '• 🕐 Horarios y ubicaciones\n'
        '• 🛋️ Productos del catálogo\n'
        '• 📦 Estado de pedidos\n\n'
        '¿Qué necesitas?';
  }

  void _enviar([String? texto]) {
    final msg = (texto ?? _ctrl.text).trim();
    if (msg.isEmpty) return;
    final hora = _horaActual();
    setState(() {
      _msgs.add(_Msg(msg, true, hora: hora));
      _ctrl.clear();
      _typing = true;
    });
    _scrollFinal();

    final resp = _responder(msg);
    final irCatalogo = resp.contains('catálogo ahora') ||
        (resp.contains('catálogo') && msg.toLowerCase().contains(
            RegExp(r'\bsi\b|\bsí\b|claro|dale|ver|ir')));

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _msgs.add(_Msg(resp, false, hora: _horaActual()));
      });
      _scrollFinal();
      if (irCatalogo) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) context.go('/catalogo');
        });
      }
    });
  }

  void _scrollFinal() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String _horaActual() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      body: Stack(children: [
        // Fondo
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [AlpesColors.cremaFondo, Colors.white.withOpacity(0.8)],
            ),
          ),
        ),

        // Pantalla principal antes de abrir chat
        if (!_chatOpen)
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AlpesColors.cafeOscuro,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                      color: AlpesColors.cafeOscuro.withOpacity(0.3),
                      blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: AlpesColors.oroGuatemalteco, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('AlpesBot',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                      color: AlpesColors.cafeOscuro, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              const Text('Asistente virtual de\nMuebles de los Alpes',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AlpesColors.nogalMedio, height: 1.5)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_rounded),
                label: const Text('Iniciar conversación'),
                onPressed: _toggleChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AlpesColors.cafeOscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                child: const Text('← Volver',
                    style: TextStyle(color: AlpesColors.nogalMedio)),
              ),
            ]),
          ),

        // Chat flotante animado
        if (_chatOpen)
          Positioned(
            bottom: 90, right: 16, left: 16,
            top: 16,
            child: ScaleTransition(
              scale: _scaleAnim,
              alignment: Alignment.bottomRight,
              child: _buildChatPanel(),
            ),
          ),

        // Botón burbuja flotante
        Positioned(
          bottom: 24, right: 24,
          child: GestureDetector(
            onTap: _toggleChat,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58, height: 58,
              decoration: BoxDecoration(
                color: _chatOpen ? AlpesColors.rojoColonial : AlpesColors.cafeOscuro,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: AlpesColors.cafeOscuro.withOpacity(0.4),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Icon(
                _chatOpen ? Icons.close_rounded : Icons.chat_bubble_rounded,
                color: AlpesColors.oroGuatemalteco, size: 26,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildChatPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
            blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: const BoxDecoration(
            color: AlpesColors.cafeOscuro,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(width: 38, height: 38,
                decoration: BoxDecoration(color: AlpesColors.oroGuatemalteco,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.support_agent_rounded,
                    color: AlpesColors.cafeOscuro, size: 22)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AlpesBot',
                  style: TextStyle(color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Row(children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('En línea · Responde al instante',
                    style: TextStyle(color: AlpesColors.arenaCalida, fontSize: 10)),
              ]),
            ])),
          ]),
        ),

        // Mensajes
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _msgs.length + (_typing ? 1 : 0),
            itemBuilder: (_, i) {
              if (_typing && i == _msgs.length) return _buildTyping();
              return _buildMensaje(_msgs[i]);
            },
          ),
        ),

        // Quick replies
        Container(
          height: 38,
          color: AlpesColors.cremaFondo,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            itemCount: _quickReplies.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _enviar(_quickReplies[i]),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AlpesColors.cafeOscuro.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AlpesColors.cafeOscuro.withOpacity(0.15)),
                ),
                child: Text(_quickReplies[i], style: const TextStyle(fontSize: 11,
                    color: AlpesColors.cafeOscuro, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ),

        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AlpesColors.pergamino)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                onSubmitted: (_) => _enviar(),
                textInputAction: TextInputAction.send,
                style: const TextStyle(fontSize: 13, color: AlpesColors.cafeOscuro),
                decoration: InputDecoration(
                  hintText: 'Escribe tu pregunta…',
                  hintStyle: const TextStyle(color: AlpesColors.arenaCalida, fontSize: 13),
                  filled: true, fillColor: AlpesColors.cremaFondo,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _enviar,
              child: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: AlpesColors.cafeOscuro,
                    shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded,
                    color: AlpesColors.oroGuatemalteco, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMensaje(_Msg m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: m.esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!m.esUsuario) ...[
            Container(width: 26, height: 26,
                decoration: const BoxDecoration(color: AlpesColors.cafeOscuro, shape: BoxShape.circle),
                child: const Icon(Icons.support_agent_rounded,
                    color: AlpesColors.oroGuatemalteco, size: 14)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: m.esUsuario ? AlpesColors.cafeOscuro : AlpesColors.cremaFondo,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(m.esUsuario ? 14 : 4),
                  bottomRight: Radius.circular(m.esUsuario ? 4 : 14),
                ),
                border: !m.esUsuario ? Border.all(color: AlpesColors.pergamino) : null,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.texto, style: TextStyle(fontSize: 13, height: 1.5,
                    color: m.esUsuario ? Colors.white : AlpesColors.cafeOscuro)),
                if (m.hora != null) ...[
                  const SizedBox(height: 3),
                  Text(m.hora!, style: TextStyle(fontSize: 10,
                      color: m.esUsuario
                          ? Colors.white.withOpacity(0.6) : AlpesColors.arenaCalida)),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTyping() => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 26, height: 26,
          decoration: const BoxDecoration(color: AlpesColors.cafeOscuro, shape: BoxShape.circle),
          child: const Icon(Icons.support_agent_rounded,
              color: AlpesColors.oroGuatemalteco, size: 14)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AlpesColors.cremaFondo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AlpesColors.pergamino)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          _Dot(delay: 0), SizedBox(width: 4),
          _Dot(delay: 200), SizedBox(width: 4),
          _Dot(delay: 400),
        ]),
      ),
    ]),
  );
}

// Puntos animados del typing
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}
class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(width: 7, height: 7,
        decoration: const BoxDecoration(color: AlpesColors.arenaCalida, shape: BoxShape.circle)),
  );
}

class _Msg {
  final String texto;
  final bool esUsuario;
  final String? hora;
  const _Msg(this.texto, this.esUsuario, {this.hora});
}
