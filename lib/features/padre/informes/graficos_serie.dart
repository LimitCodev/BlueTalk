import 'package:flutter/material.dart';

import '../graficos/linea_tendencia.dart';
import '../graficos/tarjeta_grafico.dart';
import '../reloj.dart';
import 'grafica_columnas.dart';
import 'informe_modelo.dart';

String _descripcion(Informe informe, List<int> valores, String unidad) {
  final etiquetas = [
    for (final punto in informe.serie)
      informe.periodo == Periodo.semana
          ? etiquetaDia(punto.dia)
          : '${punto.dia.day}/${punto.dia.month}',
  ];
  final partes = <String>[
    for (var i = 0; i < valores.length; i++) '${etiquetas[i]} ${valores[i]}',
  ];
  return '$unidad por día: ${partes.join(', ')}.';
}

/// Semana con columnas; mes con línea suave.
class SeccionSerie extends StatelessWidget {
  const SeccionSerie({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final valores = [for (final punto in informe.serie) punto.pictos];
    final etiquetas = [
      for (final punto in informe.serie)
        informe.periodo == Periodo.semana
            ? etiquetaDia(punto.dia)
            : '${punto.dia.day}/${punto.dia.month}',
    ];
    final descripcion = _descripcion(informe, valores, 'Pictogramas');
    return TarjetaGrafico(
      pregunta: '¿Cómo cambió la comunicación día a día?',
      numero: '${informe.actual.pictos}',
      frase: 'pictogramas en el periodo',
      hayDatos: valores.any((valor) => valor > 0),
      semantica: descripcion,
      grafico: informe.periodo == Periodo.semana
          ? GraficaColumnas(
              valores: valores,
              etiquetas: etiquetas,
              unidad: 'pictogramas',
              descripcion: descripcion,
            )
          : LineaTendencia(
              valores: valores,
              etiquetas: etiquetas,
              descripcion: descripcion,
            ),
    );
  }
}

/// Columnas de minutos de juego por día.
class SeccionJuego extends StatelessWidget {
  const SeccionJuego({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final minutos = [for (final punto in informe.serie) punto.segundosJuego ~/ 60];
    final etiquetas = [
      for (final punto in informe.serie)
        informe.periodo == Periodo.semana
            ? etiquetaDia(punto.dia)
            : '${punto.dia.day}/${punto.dia.month}',
    ];
    final descripcion = _descripcion(informe, minutos, 'Minutos de juego');
    return TarjetaGrafico(
      pregunta: '¿Cuánto tiempo jugó?',
      numero: '${informe.actual.segundosJuego ~/ 60} min',
      frase: 'en ${informe.actual.sesionesJuego} sesiones',
      hayDatos: minutos.any((valor) => valor > 0),
      semantica: descripcion,
      grafico: GraficaColumnas(
        valores: minutos,
        etiquetas: etiquetas,
        unidad: 'minutos',
        descripcion: descripcion,
      ),
    );
  }
}
