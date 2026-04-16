import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class MisResenasScreen extends StatelessWidget {
  const MisResenasScreen({super.key});

  static const _resenas = [
    _ResenaItem(
        'Sofá 3 plazas Alpino',
        5,
        'Excelente calidad, muy cómodo y elegante. Llegó en perfecto estado.',
        '10 Abr 2026'),
    _ResenaItem(
        'Mesa de comedor 8p.',
        4,
        'Muy buena mesa, sólida y bonita. El ensamblaje fue sencillo.',
        '01 Abr 2026'),
    _ResenaItem('Silla ejecutiva Pro', 5,
        'Increíblemente cómoda para largas horas de trabajo.', '20 Mar 2026'),
  ];

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
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mis Reseñas',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3)),
          Text('${_resenas.length} reseña${_resenas.length != 1 ? 's' : ''}',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.65),
                  fontWeight: FontWeight.w400)),
        ]),
      ),
      body: _resenas.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _resenas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _buildCard(_resenas[i]),
            ),
    );
  }

  Widget _buildEmpty() => const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.star_border_rounded,
              size: 64, color: AlpesColors.arenaCalida),
          SizedBox(height: 16),
          Text('Aún no tienes reseñas',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AlpesColors.cafeOscuro)),
          SizedBox(height: 6),
          Text('Compra un producto y comparte tu opinión',
              style: TextStyle(color: AlpesColors.arenaCalida, fontSize: 13)),
        ]),
      );

  Widget _buildCard(_ResenaItem r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AlpesColors.pergamino),
        boxShadow: [
          BoxShadow(
              color: AlpesColors.cafeOscuro.withOpacity(0.04),
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
              color: AlpesColors.pergamino,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chair_alt_rounded,
                color: AlpesColors.nogalMedio, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(r.producto,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AlpesColors.cafeOscuro)),
                const SizedBox(height: 3),
                Row(children: [
                  ...List.generate(
                      5,
                      (j) => Icon(
                            j < r.estrellas
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 15,
                            color: AlpesColors.oroGuatemalteco,
                          )),
                  const SizedBox(width: 6),
                  Text('${r.estrellas}/5',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AlpesColors.nogalMedio,
                          fontWeight: FontWeight.w600)),
                ]),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AlpesColors.cremaFondo,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(r.fecha,
                style: const TextStyle(
                    fontSize: 10, color: AlpesColors.arenaCalida)),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(color: AlpesColors.pergamino, height: 1),
        const SizedBox(height: 12),
        Text(r.comentario,
            style: const TextStyle(
                fontSize: 13, color: AlpesColors.grafito, height: 1.5)),
      ]),
    );
  }
}

class _ResenaItem {
  final String producto;
  final int estrellas;
  final String comentario;
  final String fecha;
  const _ResenaItem(this.producto, this.estrellas, this.comentario, this.fecha);
}
