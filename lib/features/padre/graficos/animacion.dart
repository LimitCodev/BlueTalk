import 'package:flutter/material.dart';

/// Duración de la animación de entrada de los gráficos (plan 14C §2).
const duracionGrafico = Duration(milliseconds: 600);

/// Curva de la animación de entrada de los gráficos.
const curvaGrafico = Curves.easeOutCubic;

/// Anima un gráfico de 0 a 1 y entrega el avance al constructor.
///
/// Con el Modo calma o «Quitar animaciones» de Android —que la app refleja
/// en `MediaQuery.disableAnimations`— entrega 1 en el primer fotograma.
class AnimacionGrafico extends StatelessWidget {
  const AnimacionGrafico({super.key, required this.builder});

  final Widget Function(BuildContext, double) builder;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return builder(context, 1);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duracionGrafico,
      curve: curvaGrafico,
      builder: (context, avance, _) => builder(context, avance),
    );
  }
}
