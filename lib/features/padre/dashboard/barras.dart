import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Barra horizontal hecha en Flutter: track + relleno, sin animación
/// (respeta el Modo calma) y con semántica para lectores de pantalla.
///
/// Mismo criterio que `AvanceJuegos`: sin librerías de gráficas (plan 00 §5).
class BarraDato extends StatelessWidget {
  const BarraDato({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.detalle,
  });

  /// Texto de la fila (p.ej. «Lun» o «Comida»).
  final String etiqueta;

  /// Fracción 0–1 a rellenar.
  final double valor;

  /// Valor numérico a la derecha de la etiqueta (p.ej. «12 eventos»).
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final fraccion = valor.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (detalle != null)
                Text(
                  detalle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Semantics(
            excludeSemantics: true,
            label: detalle == null
                ? '$etiqueta: ${(fraccion * 100).round()} por ciento'
                : '$etiqueta: $detalle',
            child: Container(
              height: 12,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: context.colores.primary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                widthFactor: fraccion,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: context.colores.primaryStrong,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de texto con su valor a la derecha (métricas del resumen).
class FilaMetrica extends StatelessWidget {
  const FilaMetrica({super.key, required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(titulo)),
          const SizedBox(width: 8),
          Text(
            valor,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
