import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';

class BottomNavCliente extends StatelessWidget {
  final int currentIndex;
  const BottomNavCliente({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavData(Icons.home_outlined,      Icons.home_rounded,        'Inicio',    '/home'),
      _NavData(Icons.grid_view_outlined, Icons.grid_view_rounded,   'Catálogo',  '/catalogo'),
      _NavData(Icons.favorite_border,    Icons.favorite_rounded,    'Favoritos', '/favoritos'),
      _NavData(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Órdenes', '/mis-ordenes'),
      _NavData(Icons.person_outline_rounded, Icons.person_rounded,  'Perfil',    '/perfil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(
            color: AlpesColors.pergamino, width: 1)),
        boxShadow: [
          BoxShadow(color: AlpesColors.cafeOscuro.withOpacity(0.08),
              blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              final item   = items[i];
              final badge  = (i == 2) // carrito en favoritos no, pero en home sí
                  ? 0
                  : 0;

              return _NavItem(
                icon:        item.icon,
                activeIcon:  item.activeIcon,
                label:       item.label,
                active:      active,
                badge:       badge,
                onTap: () => context.go(item.route),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavData {
  final IconData icon, activeIcon;
  final String label, route;
  const _NavData(this.icon, this.activeIcon, this.label, this.route);
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Indicador top
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 3,
            width: active ? 24 : 0,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: AlpesColors.oroGuatemalteco,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(3)),
            ),
          ),

          // Ícono
          Stack(alignment: Alignment.topRight, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 36,
              decoration: BoxDecoration(
                color: active
                    ? AlpesColors.cafeOscuro.withOpacity(0.07)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                active ? activeIcon : icon,
                size: 22,
                color: active
                    ? AlpesColors.cafeOscuro
                    : AlpesColors.arenaCalida,
              ),
            ),
            if (badge > 0)
              Positioned(
                top: 2, right: 2,
                child: Container(
                  width: 14, height: 14,
                  decoration: const BoxDecoration(
                      color: AlpesColors.rojoColonial,
                      shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('$badge',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 8, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),

          const SizedBox(height: 2),

          // Label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AlpesColors.cafeOscuro : AlpesColors.arenaCalida,
            ),
            child: Text(label),
          ),
        ]),
      ),
    );
  }
}
