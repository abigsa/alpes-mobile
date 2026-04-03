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
      final envioRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.envio}/buscar?criterio=orden_venta_id&valor=${widget.envioId}'),
      );
      final segRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.seguimiento}/buscar?criterio=envio_id&valor=${widget.envioId}'),
      );
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
    } catch (_) {} finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('SEGUIMIENTO'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_envio != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Información de envío', style: Theme.of(context).textTheme.titleLarge),
                            const Divider(),
                            Text('Código: ${_envio!['TRACKING_CODIGO'] ?? _envio!['tracking_codigo'] ?? '-'}'),
                            Text('Dirección: ${_envio!['DIRECCION_ENTREGA_SNAPSHOT'] ?? _envio!['direccion_entrega_snapshot'] ?? '-'}'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text('Historial de eventos', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (_eventos.isEmpty)
                    const Text('Sin eventos de seguimiento aún')
                  else
                    ..._eventos.asMap().entries.map((e) => _EventoTile(
                      evento: e.value,
                      esUltimo: e.key == _eventos.length - 1,
                    )),
                ],
              ),
            ),
    );
  }
}

class _EventoTile extends StatelessWidget {
  final Map<String, dynamic> evento;
  final bool esUltimo;
  const _EventoTile({required this.evento, required this.esUltimo});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: esUltimo ? AlpesColors.cafeOscuro : AlpesColors.arenaCalida,
                shape: BoxShape.circle,
              ),
            ),
            if (!esUltimo) Container(width: 2, height: 40, color: AlpesColors.pergamino),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${evento['UBICACION_TEXTO'] ?? evento['ubicacion_texto'] ?? 'Actualización'}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${evento['OBSERVACION'] ?? evento['observacion'] ?? ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
