import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../graficos/colores_grafico.dart';
import '../graficos/dona.dart';
import '../graficos/dona_leyenda.dart';
import '../graficos/tarjeta_grafico.dart';
import 'metricas.dart';

/// Dona de temas usados hoy, con los colores de las categorías.
class DonaTemasHoy extends StatelessWidget {
  const DonaTemasHoy({super.key, required this.metricas});

  final Metricas metricas;

  @override
  Widget build(BuildContext context) {
    final paleta = context.colores;
    final entradas = metricas.pictosPorCategoriaHoy.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colorPorNombre = <String, Color>{
      for (final entrada in entradas)
        metricas.nombresDeCategoria[entrada.key] ?? entrada.key:
            colorCategoria(entrada.key, paleta),
    };
    final porciones = [
      for (final porcion in agruparDona([
        for (final entrada in entradas)
          (
            etiqueta: metricas.nombresDeCategoria[entrada.key] ?? entrada.key,
            valor: entrada.value,
          ),
      ]))
        (
          etiqueta: porcion.etiqueta,
          valor: porcion.valor,
          color: porcion.etiqueta == 'Otras'
              ? colorOtras(paleta)
              : colorPorNombre[porcion.etiqueta] ?? colorOtras(paleta),
        ),
    ];
    final detalle = porciones
        .map((p) => '${p.etiqueta} ${p.valor}')
        .join(', ');
    return TarjetaGrafico(
      pregunta: '¿Qué temas usó hoy para comunicarse?',
      numero: '${metricas.pictosHoy}',
      frase: 'pictogramas tocados hoy',
      hayDatos: porciones.isNotEmpty,
      semantica: 'Temas de hoy: $detalle. '
          'Total ${metricas.pictosHoy} pictogramas.',
      grafico: DonaConLeyenda(
        porciones: porciones,
        descripcion: 'Temas de hoy: $detalle.',
      ),
    );
  }
}
