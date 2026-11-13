import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Marco común de los gráficos del adulto (plan 14C §2).
///
/// Cada tarjeta responde una pregunta en lenguaje literal, muestra un número
/// grande con su frase y, si no hay datos, el texto amable en vez de un
/// círculo vacío. Toda la tarjeta se anuncia como un solo nodo de semántica.
class TarjetaGrafico extends StatelessWidget {
  const TarjetaGrafico({
    super.key,
    required this.pregunta,
    required this.numero,
    required this.frase,
    required this.semantica,
    this.grafico,
    this.hayDatos = true,
    this.mensajeVacio = 'Aún no hay datos. Aparecerán cuando tu hijo o hija '
        'use la app.',
  });

  final String pregunta;
  final String numero;
  final String frase;

  /// Texto completo para el lector de pantalla.
  final String semantica;
  final Widget? grafico;
  final bool hayDatos;
  final String mensajeVacio;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: hayDatos ? semantica : '$pregunta. $mensajeVacio',
      excludeSemantics: true,
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(pregunta, style: estilo.titleMedium),
              const SizedBox(height: 8),
              if (!hayDatos)
                Text(mensajeVacio)
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        numero,
                        style: estilo.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.colores.primaryStrongText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(frase)),
                  ],
                ),
                if (grafico != null) ...[
                  const SizedBox(height: 12),
                  grafico!,
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
