import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../graficos/colores_grafico.dart';
import '../graficos/dona.dart';
import '../graficos/dona_leyenda.dart';
import '../graficos/tarjeta_grafico.dart';
import '../monitoreo/uso_telefono_model.dart';
import 'informe_modelo.dart';

/// Uso de otras apps del teléfono (solo tiempos; nunca contenido).
class SeccionApps extends StatelessWidget {
  const SeccionApps({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    if (informe.diasConApps == 0) return const SizedBox.shrink();
    final paleta = context.colores;
    final top = informe.apps;
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
    final otras = informe.segundosPantalla - suma;
    if (otras > 0) {
      porciones.add((
        etiqueta: 'Otras',
        valor: otras,
        color: colorOtras(paleta),
      ));
    }
    final detalle = porciones
        .map((porcion) => '${porcion.etiqueta} ${formatearDuracion(porcion.valor)}')
        .join(', ');
    return TarjetaGrafico(
      pregunta: '¿En qué apps pasó el tiempo?',
      numero: formatearDuracion(informe.segundosPantalla),
      frase: 'en ${informe.diasConApps} días con datos',
      hayDatos: porciones.isNotEmpty,
      semantica: 'Tiempo en otras apps: $detalle.',
      grafico: DonaConLeyenda(
        porciones: porciones,
        formato: formatearDuracion,
        descripcion: 'Tiempo en otras apps: $detalle.',
      ),
    );
  }
}
