import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class SoporteScreen extends StatefulWidget {
  const SoporteScreen({super.key});
  @override
  State<SoporteScreen> createState() => _SoporteScreenState();
}

class _SoporteScreenState extends State<SoporteScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _agentTyping = false;

  final List<_Mensaje> _mensajes = [
    _Mensaje(
        '¡Hola! Bienvenido al soporte de Muebles de los Alpes. ¿En qué podemos ayudarte hoy?',
        false,
        hora: '09:00'),
  ];

  void _enviar() {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;
    final hora = _horaActual();
    setState(() {
      _mensajes.add(_Mensaje(texto, true, hora: hora));
      _ctrl.clear();
      _agentTyping = true;
    });
    _scrollAlFinal();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _agentTyping = false;
        _mensajes.add(_Mensaje(
            'Gracias por tu mensaje. Un agente te responderá en breve. Nuestro horario de atención es de lunes a viernes de 8:00 AM a 6:00 PM.',
            false,
            hora: _horaActual()));
      });
      _scrollAlFinal();
    });
  }

  void _scrollAlFinal() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String _horaActual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
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
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AlpesColors.oroGuatemalteco.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: AlpesColors.oroGuatemalteco, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Soporte al cliente',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Row(children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF4CAF50))),
              const SizedBox(width: 5),
              Text('Agente disponible',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withOpacity(0.7))),
            ]),
          ]),
        ]),
      ),
      body: Column(children: [
        Container(
          color: AlpesColors.oroGuatemalteco.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Icon(Icons.access_time_rounded,
                size: 14, color: AlpesColors.oroGuatemalteco),
            const SizedBox(width: 6),
            const Text('Atención: Lun-Vie 8:00 AM – 6:00 PM',
                style: TextStyle(
                    fontSize: 11,
                    color: AlpesColors.nogalMedio,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: _mensajes.length + (_agentTyping ? 1 : 0),
            itemBuilder: (context, i) {
              if (_agentTyping && i == _mensajes.length) return _buildTyping();
              return _buildBubble(_mensajes[i], context);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE8E0D5))),
          ),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviar(),
                  style: const TextStyle(
                      fontSize: 14, color: AlpesColors.cafeOscuro),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu mensaje...',
                    hintStyle: const TextStyle(
                        color: AlpesColors.arenaCalida, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: AlpesColors.cremaFondo,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _enviar,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AlpesColors.cafeOscuro,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AlpesColors.cafeOscuro.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: AlpesColors.oroGuatemalteco, size: 18),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildBubble(_Mensaje m, BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment:
              m.esCliente ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!m.esCliente) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AlpesColors.oroGuatemalteco,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: AlpesColors.cafeOscuro, size: 15),
              ),
              const SizedBox(width: 6),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68),
              child: Container(
                padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
                decoration: BoxDecoration(
                  color: m.esCliente ? AlpesColors.cafeOscuro : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(m.esCliente ? 14 : 2),
                    bottomRight: Radius.circular(m.esCliente ? 2 : 14),
                  ),
                  border: m.esCliente
                      ? null
                      : Border.all(color: AlpesColors.pergamino),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.texto,
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: m.esCliente
                                  ? AlpesColors.cremaFondo
                                  : AlpesColors.grafito)),
                      if (m.hora.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(m.hora,
                            style: TextStyle(
                                fontSize: 10,
                                color: m.esCliente
                                    ? Colors.white.withOpacity(0.5)
                                    : AlpesColors.arenaCalida)),
                      ],
                    ]),
              ),
            ),
          ],
        ),
      );

  Widget _buildTyping() => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: AlpesColors.oroGuatemalteco,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.support_agent_rounded,
                  color: AlpesColors.cafeOscuro, size: 15)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AlpesColors.pergamino)),
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                    3,
                    (i) => Padding(
                        padding: EdgeInsets.only(left: i > 0 ? 3 : 0),
                        child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                                color: AlpesColors.arenaCalida,
                                shape: BoxShape.circle))))),
          ),
        ]),
      );
}

class _Mensaje {
  final String texto;
  final bool esCliente;
  final String hora;
  const _Mensaje(this.texto, this.esCliente, {this.hora = ''});
}
