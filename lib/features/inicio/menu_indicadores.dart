import 'package:flutter/material.dart';

import 'menu_opciones.dart';

/// Flechas ▲ ▼ y puntos del carrusel, cada uno con 48 dp de objetivo.
class MenuIndicadores extends StatelessWidget {
  const MenuIndicadores({
    super.key,
    required this.actual,
    required this.onIr,
    required this.child,
  });

  final int actual;
  final ValueChanged<int> onIr;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final total = MenuOpcion.values.length;
    final color = Theme.of(context).colorScheme;
    return Column(
      children: [
        IconButton(
          tooltip: 'Anterior',
          icon: const Icon(Icons.keyboard_arrow_up, size: 32),
          onPressed: actual > 0 ? () => onIr(actual - 1) : null,
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: child),
              // En horizontal no caben 5 × 48 dp: se desplazan en vez de
              // encoger por debajo del objetivo táctil mínimo.
              SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < total; i++)
                      Semantics(
                        button: true,
                        label:
                            'Ir a ${MenuOpcion.values[i].titulo}, '
                            '${i + 1} de $total',
                        excludeSemantics: true,
                        child: InkResponse(
                          onTap: () => onIr(i),
                          radius: 24,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: AnimatedContainer(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 200),
                                width: 8,
                                height: i == actual ? 20 : 8,
                                decoration: BoxDecoration(
                                  color: i == actual
                                      ? color.primary
                                      : color.onSurface.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Siguiente',
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: actual < total - 1 ? () => onIr(actual + 1) : null,
        ),
      ],
    );
  }
}
