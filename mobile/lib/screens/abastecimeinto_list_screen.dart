import 'package:flutter/material.dart';
import '../services/abastecimiento_service.dart';

class AbastecimientoListScreen extends StatefulWidget {
  const AbastecimientoListScreen({super.key});

  @override
  State<AbastecimientoListScreen> createState() => _AbastecimientoListScreenState();
}

class _AbastecimientoListScreenState extends State<AbastecimientoListScreen> {
  final AbastecimientoService _service = AbastecimientoService();
  List<dynamic> abastecimientos = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final data = await _service.listar();
    setState(() {
      abastecimientos = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Abastecimientos")),
      body: ListView.builder(
        itemCount: abastecimientos.length,
        itemBuilder: (context, index) {
          final item = abastecimientos[index];
          return ListTile(
            title: Text("ID: ${item['ABASTECIMIENTO_ID']}"),
            subtitle: Text("Motivo: ${item['MOTIVO']}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await _service.eliminar(item['ABASTECIMIENTO_ID']);
                _loadData();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Aquí navegas a la pantalla de creación
        },
      ),
    );
  }
}


