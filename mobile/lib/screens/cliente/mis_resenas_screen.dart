import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class MisResenasScreen extends StatelessWidget {
  const MisResenasScreen({super.key});

  static const _resenas = [
    _ResenaItem('Sofá 3 plazas Alpino', 5, 'Excelente calidad, muy cómodo y elegante. Llegó en perfecto estado.', '10 Abr 2026'),
    _ResenaItem('Mesa de comedor 8p.', 4, 'Muy buena mesa, sólida y bonita. El ensamblaje fue sencillo.', '01 Abr 2026'),
    _ResenaItem('Silla ejecutiva Pro', 5, 'Increíblemente cómoda para largas horas de trabajo.', '20 Mar 2026'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlpesColors.cremaFondo,
      appBar: AppBar(
        title: const Text('MIS RESEÑAS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: _resenas.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border_rounded, size: 56, color: AlpesColors.arenaCalida),
                  SizedBox(height: 12),
                  Text('Aún no tienes reseñas',
                      style: TextStyle(color: AlpesColors.nogalMedio, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Compra un producto y comparte tu opinión',
                      style: TextStyle(color: AlpesColors.arenaCalida, fontSize: 12)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _resenas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final r = _resenas[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AlpesColors.pergamino),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(r.producto,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AlpesColors.cafeOscuro)),
                          ),
                          Text(r.fecha,
                              style: const TextStyle(
                                  fontSize: 10, color: AlpesColors.arenaCalida)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (j) => Icon(
                          j < r.estrellas ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 16,
                          color: AlpesColors.oroGuatemalteco,
                        )),
                      ),
                      const SizedBox(height: 8),
                      Text(r.comentario,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AlpesColors.grafito,
                              height: 1.4)),
                    ],
                  ),
                );
              },
            ),
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
