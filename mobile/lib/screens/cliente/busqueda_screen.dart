import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/producto_provider.dart';
import '../../widgets/producto_card.dart';

class BusquedaScreen extends StatefulWidget {
  const BusquedaScreen({super.key});
  @override
  State<BusquedaScreen> createState() => _BusquedaScreenState();
}

class _BusquedaScreenState extends State<BusquedaScreen> {
  final _ctrl = TextEditingController();
  List<Producto> _resultados = [];
  bool _buscando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _buscar(String q) async {
    if (q.isEmpty) {
      setState(() => _resultados = []);
      return;
    }
    setState(() => _buscando = true);
    final res = await context.read<ProductoProvider>().buscar(q);
    setState(() { _resultados = res; _buscando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: AlpesColors.cremaFondo),
          decoration: const InputDecoration(
            hintText: 'Buscar muebles...',
            hintStyle: TextStyle(color: AlpesColors.arenaCalida),
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: _buscar,
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: _buscando
          ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
          : _resultados.isEmpty && _ctrl.text.isNotEmpty
              ? const Center(child: Text('Sin resultados'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _resultados.length,
                  itemBuilder: (_, i) => ProductoCard(producto: _resultados[i]),
                ),
    );
  }
}
