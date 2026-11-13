import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../graficos/colores_grafico.dart';
import '../graficos/dona.dart';
import '../graficos/dona_leyenda.dart';
import '../graficos/tarjeta_grafico.dart';
import 'informe_modelo.dart';

/// Dona de categorías: hasta cuatro temas y «Otras» con el resto.
class SeccionCategorias extends StatelessWidget {
  const SeccionCategorias({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final paleta = context.colores;
    final top = informe.categorias;
    final limite = top.length < 4 ? top.length : 4;
    var suma = 0;
    final porciones = <SegmentoDona>[];
    for (var i = 0; i < limite; i++) {
      porciones.add((
        etiqueta: top[i].nombre,
        valor: top[i].valor,
        color: colorPorIndice(i, paleta),
      ));
      suma += top[i].valor;
    }
    final otras = informe.actual.pictos - suma;
    if (otras > 0) {
      porciones.add((
        etiqueta: 'Otras',
        valor: otras,
        color: colorOtras(paleta),
      ));
    }
    final detalle = porciones
        .map((porcion) => '${porcion.etiqueta} ${porcion.valor}')
        .join(', ');
    return TarjetaGrafico(
      pregunta: '¿De qué temas habló más?',
      numero: '${informe.actual.pictos}',
      frase: 'pictogramas en el periodo',
      hayDatos: porciones.isNotEmpty,
      semantica: 'Temas del periodo: $detalle. '
          'Total ${informe.actual.pictos} pictogramas.',
      grafico: DonaConLeyenda(
        porciones: porciones,
        descripcion: 'Temas del periodo: $detalle.',
      ),
    );
  }
}
