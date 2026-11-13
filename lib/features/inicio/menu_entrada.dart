import 'package:flutter/material.dart';

/// Entrada escalonada de las tarjetas al abrir el menú (plan 14A §A2.2).
/// Con el modo calma o «Quitar animaciones», aparecen ya en su sitio.
class MenuEntrada extends StatelessWidget {
  const MenuEntrada({super.key, required this.orden, required this.child});

  final int orden;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + 60 * orden),
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - v)),
          child: child,
        ),
      ),
    );
  }
}
