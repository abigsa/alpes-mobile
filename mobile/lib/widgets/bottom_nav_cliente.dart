import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/carrito_provider.dart';

class BottomNavCliente extends StatelessWidget {
  final int currentIndex;
  const BottomNavCliente({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08),
              blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined,      activeIcon: Icons.home_rounded,
                  label: 'Inicio',    index: 0, current: currentIndex,
                  onTap: () => context.go('/home')),
              _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded,
                  label: 'Catálogo',  index: 1, current: currentIndex,
                  onTap: () => context.go('/catalogo')),
              _NavItem(icon: Icons.favorite_border,    activeIcon: Icons.favorite_rounded,
                  label: 'Favoritos', index: 2, current: currentIndex,
                  onTap: () => context.go('/favoritos')),
              _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded,
                  label: 'Órdenes',  index: 3, current: currentIndex,
                  onTap: () => context.go('/mis-ordenes')),
              _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,
                  label: 'Perfil',   index: 4, current: currentIndex,
                  badge: 0,
                  onTap: () => context.go('/perfil')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AlpesColors.cafeOscuro.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(alignment: Alignment.topRight, children: [
            Icon(active ? activeIcon : icon, size: 22,
                color: active ? AlpesColors.cafeOscuro : AlpesColors.arenaCalida),
            if (badge > 0)
              Container(
                width: 14, height: 14,
                decoration: const BoxDecoration(
                    color: AlpesColors.rojoColonial, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('$badge', style: const TextStyle(color: Colors.white,
                    fontSize: 8, fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: active ? AlpesColors.cafeOscuro : AlpesColors.arenaCalida)),
        ]),
      ),
    );
  }
}
