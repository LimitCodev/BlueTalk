import 'package:flutter/material.dart';

import '../graficos/anillo_porcentaje.dart';
import '../graficos/tarjeta_grafico.dart';
import '../informes/grafica_columnas.dart';
import '../reloj.dart';
import 'metricas.dart';
import 'resumen_dona.dart';
import 'resumen_kpis.dart';

/// Los cuatro gráficos del Resumen del adulto (plan 14C §4).
class ResumenGraficos extends StatelessWidget {
  const ResumenGraficos({super.key, required this.metricas});

  final Metricas metricas;

  @override
  Widget build(BuildContext context) {
    final hechas = metricas.actividadesHechasHoy;
    final total = metricas.actividadesHorario;
    final eventos = [for (final valor in metricas.eventosPorDia) valor];
    final sumaEventos = eventos.fold<int>(0, (suma, valor) => suma + valor);
    final descripcionSemana = 'Eventos por día en los últimos 7 días: '
        '${[
      for (var i = 0; i < metricas.dias.length; i++)
        '${etiquetaDia(metricas.dias[i])} ${eventos[i]}',
    ].join(', ')}.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TarjetaGrafico(
          pregunta: '¿Cuántas actividades hizo hoy?',
          numero: '$hechas de $total',
          frase: 'actividades del horario marcadas hoy',
          hayDatos: total > 0,
          semantica: 'Actividades de hoy: $hechas de $total, '
              '${(fraccion(hechas, total) * 100).round()} por ciento.',
          grafico: AnilloPorcentaje(
            hechas: hechas,
            total: total,
            descripcion: 'Actividades de hoy: $hechas de $total.',
          ),
        ),
        DonaTemasHoy(metricas: metricas),
        KpisHoy(metricas: metricas),
        TarjetaGrafico(
          pregunta: '¿Cómo fue esta semana?',
          numero: '$sumaEventos',
          frase: 'eventos en los últimos 7 días',
          hayDatos: sumaEventos > 0,
          semantica: descripcionSemana,
          grafico: GraficaColumnas(
            valores: eventos,
            etiquetas: [for (final dia in metricas.dias) etiquetaDia(dia)],
            resaltado: metricas.dias.length - 1,
            unidad: 'eventos',
            descripcion: descripcionSemana,
          ),
        ),
      ],
    );
  }
}
