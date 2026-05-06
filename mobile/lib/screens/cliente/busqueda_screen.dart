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
  String _filtroTipo = 'Todos';
  List<Producto> _resultados = [];
  bool _buscando = false;
  bool _busquedaRealizada = false;

  static const _tipos = ['Todos', 'INTERIOR', 'EXTERIOR'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _buscar(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _resultados = [];
        _busquedaRealizada = false;
      });
      return;
    }
    setState(() => _buscando = true);
    final res = await context.read<ProductoProvider>().buscar(q.trim());
    setState(() {
      _resultados = res;
      _buscando = false;
      _busquedaRealizada = true;
    });
  }

  List<Producto> get _resultadosFiltrados {
    if (_filtroTipo == 'Todos') return _resultados;
    return _resultados
        .where((p) => (p.tipo ?? '').toUpperCase() == _filtroTipo)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _resultadosFiltrados;

    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        backgroundColor: AlpesColors.cafeOscuro,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AlpesColors.cremaFondo, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: AlpesColors.cremaFondo, fontSize: 16),
          cursorColor: AlpesColors.oroGuatemalteco,
          decoration: InputDecoration(
            hintText: 'Buscar muebles...',
            hintStyle: TextStyle(color: AlpesColors.arenaCalida.withOpacity(0.8), fontSize: 16),
            border: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: AlpesColors.arenaCalida, size: 20),
                    onPressed: () {
                      _ctrl.clear();
                      _buscar('');
                    },
                  )
                : const Icon(Icons.search_rounded, color: AlpesColors.arenaCalida, size: 22),
          ),
          onChanged: _buscar,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AlpesColors.nogalMedio.withOpacity(0.4)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Chips de filtro por tipo ──
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _tipos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final tipo = _tipos[i];
                final seleccionado = _filtroTipo == tipo;
                return GestureDetector(
                  onTap: () => setState(() => _filtroTipo = tipo),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: seleccionado ? AlpesColors.cafeOscuro : AlpesColors.pergamino,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: seleccionado ? AlpesColors.cafeOscuro : AlpesColors.arenaCalida,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      tipo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: seleccionado ? AlpesColors.cremaFondo : AlpesColors.nogalMedio,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Contador de resultados ──
          if (_busquedaRealizada && !_buscando)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                filtrados.isEmpty
                    ? 'Sin resultados para "${_ctrl.text}"'
                    : '${filtrados.length} resultado${filtrados.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AlpesColors.nogalMedio,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // ── Contenido ──
          Expanded(
            child: _buscando
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AlpesColors.cafeOscuro,
                      strokeWidth: 2.5,
                    ),
                  )
                : !_busquedaRealizada
                    ? _buildEstadoInicial()
                    : filtrados.isEmpty
                        ? _buildEstadoVacio()
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: filtrados.length,
                            itemBuilder: (_, i) => ProductoCard(producto: filtrados[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoInicial() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded,
              size: 72, color: AlpesColors.arenaCalida.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Escribe para buscar muebles',
            style: TextStyle(
              fontSize: 15,
              color: AlpesColors.nogalMedio,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Filtra por tipo: Interior o Exterior',
            style: TextStyle(
              fontSize: 13,
              color: AlpesColors.arenaCalida.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 72, color: AlpesColors.arenaCalida.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Sin resultados',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AlpesColors.cafeOscuro,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'No encontramos muebles que coincidan con tu búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AlpesColors.nogalMedio.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {
              _ctrl.clear();
              _buscar('');
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Limpiar búsqueda'),
            style: TextButton.styleFrom(foregroundColor: AlpesColors.nogalMedio),
          ),
        ],
      ),
    );
  }
}
