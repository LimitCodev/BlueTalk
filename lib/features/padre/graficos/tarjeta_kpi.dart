import 'package:flutter/material.dart';

import 'kpi_variacion.dart';

export 'kpi_variacion.dart';

/// Número grande con flecha y frase de comparación.
class TarjetaKpi extends StatelessWidget {
  const TarjetaKpi({
    super.key,
    required this.titulo,
    required this.valor,
    this.unidad,
    this.actual,
    this.anterior,
    this.periodo = 'el periodo anterior',
  });

  final String titulo;
  final String valor;
  final String? unidad;
  final int? actual;
  final int? anterior;
  final String periodo;

  @override
  Widget build(BuildContext context) {
    final dato = actual != null && anterior != null
        ? variacion(actual!, anterior!)
        : null;
    final detalle = dato == null ? null : textoVariacion(dato, periodo);
    final estilo = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: [
        titulo,
        '$valor${unidad == null ? '' : ' $unidad'}',
        ?detalle,
      ].join('. '),
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                style: estilo.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      valor,
                      style: estilo.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (unidad != null) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(unidad!, style: estilo.bodySmall),
                      ),
                    ],
                  ],
                ),
              ),
              if (detalle != null) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      iconoVariacion(dato!.direccion),
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 2),
                    Expanded(child: Text(detalle, style: estilo.bodySmall)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
