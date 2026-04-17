import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../config/theme.dart';
import '../../config/api_config.dart';

class SeguimientoScreen extends StatefulWidget {
  final int envioId;
  const SeguimientoScreen({super.key, required this.envioId});
  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  Map<String, dynamic>? _envio;
  List<Map<String, dynamic>> _eventos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final envioRes = await http.get(Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.envio}/buscar?criterio=orden_venta_id&valor=${widget.envioId}'));
      final segRes = await http.get(Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.seguimiento}/buscar?criterio=envio_id&valor=${widget.envioId}'));
      final envioData = jsonDecode(envioRes.body);
      final segData = jsonDecode(segRes.body);
      setState(() {
        if (envioData['ok'] == true && (envioData['data'] as List).isNotEmpty) {
          _envio = (envioData['data'] as List).first;
        }
        if (segData['ok'] == true) {
          _eventos = List<Map<String, dynamic>>.from(segData['data']);
        }
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
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
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/mis-ordenes'),
        ),
        title: const Text('Seguimiento de envío',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : RefreshIndicator(
              color: AlpesColors.cafeOscuro,
              onRefresh: _cargar,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info de envío
                      if (_envio != null) _buildInfoCard(),
                      const SizedBox(height: 16),
                      // Timeline
                      _buildTimelineCard(),
                    ]),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    final codigo =
        _envio!['TRACKING_CODIGO'] ?? _envio!['tracking_codigo'] ?? '-';
    final dir = _envio!['DIRECCION_ENTREGA_SNAPSHOT'] ??
        _envio!['direccion_entrega_snapshot'] ??
        '-';
    final estado = _envio!['ESTADO'] ?? _envio!['estado'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: [
          BoxShadow(
              color: AlpesColors.cafeOscuro.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AlpesColors.verdeSelva.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: AlpesColors.verdeSelva, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Información de envío',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AlpesColors.cafeOscuro)),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AlpesColors.verdeSelva.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(estado.toString(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AlpesColors.verdeSelva)),
                ),
              ])),
        ]),
        const SizedBox(height: 14),
        const Divider(color: AlpesColors.pergamino, height: 1),
        const SizedBox(height: 14),
        _infoRow(
            Icons.qr_code_rounded, 'Código de tracking', codigo.toString()),
        const SizedBox(height: 10),
        _infoRow(
            Icons.location_on_outlined, 'Dirección de entrega', dir.toString()),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AlpesColors.nogalMedio),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AlpesColors.arenaCalida,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AlpesColors.cafeOscuro,
                        fontWeight: FontWeight.w500)),
              ])),
        ],
      );

  Widget _buildTimelineCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AlpesColors.pergamino),
          boxShadow: [
            BoxShadow(
                color: AlpesColors.cafeOscuro.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                    color: AlpesColors.oroGuatemalteco,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Historial de eventos',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AlpesColors.cafeOscuro)),
          ]),
          const SizedBox(height: 16),
          if (_eventos.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Text('Sin eventos de seguimiento aún',
                  style:
                      TextStyle(fontSize: 13, color: AlpesColors.arenaCalida)),
            )
          else
            ..._eventos.asMap().entries.map((e) => _EventoTile(
                  evento: e.value,
                  esUltimo: e.key == _eventos.length - 1,
                )),
        ]),
      );
}

class _EventoTile extends StatelessWidget {
  final Map<String, dynamic> evento;
  final bool esUltimo;
  const _EventoTile({required this.evento, required this.esUltimo});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: esUltimo ? AlpesColors.cafeOscuro : AlpesColors.arenaCalida,
            shape: BoxShape.circle,
            border: esUltimo
                ? Border.all(color: AlpesColors.oroGuatemalteco, width: 2)
                : null,
          ),
          child: esUltimo
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 9)
              : null,
        ),
        if (!esUltimo)
          Container(width: 1.5, height: 44, color: AlpesColors.pergamino),
      ]),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                '${evento['UBICACION_TEXTO'] ?? evento['ubicacion_texto'] ?? 'Actualización'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      esUltimo ? AlpesColors.cafeOscuro : AlpesColors.grafito,
                )),
            if ((evento['OBSERVACION'] ?? evento['observacion'] ?? '')
                .toString()
                .isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                    '${evento['OBSERVACION'] ?? evento['observacion'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AlpesColors.nogalMedio)),
              ),
          ]),
        ),
      ),
    ]);
  }
}
