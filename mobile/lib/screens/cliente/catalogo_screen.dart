import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/producto_provider.dart';
import '../../widgets/producto_card.dart';
import '../../widgets/bottom_nav_cliente.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  String _filtroTipo = 'Todos';
  final _tipos = ['Todos', 'Sala', 'Comedor', 'Dormitorio', 'Oficina', 'Exterior'];

  @override
  Widget build(BuildContext context) {
    final productos = context.watch<ProductoProvider>();
    final lista = _filtroTipo == 'Todos'
        ? productos.productos
        : productos.productos.where((p) => p.tipo == _filtroTipo).toList();

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(title: const Text('CATÁLOGO')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _tipos.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_tipos[i]),
                  selected: _filtroTipo == _tipos[i],
                  onSelected: (_) => setState(() => _filtroTipo = _tipos[i]),
                  selectedColor: AlpesColors.cafeOscuro,
                  labelStyle: TextStyle(color: _filtroTipo == _tipos[i] ? AlpesColors.cremaFondo : AlpesColors.grafito),
                ),
              ),
            ),
          ),
          Expanded(
            child: productos.loading
                ? const Center(child: CircularProgressIndicator(color: AlpesColors.cafeOscuro))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.7,
                    ),
                    itemCount: lista.length,
                    itemBuilder: (_, i) => ProductoCard(producto: lista[i]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavCliente(currentIndex: 1),
    );
  }
}
