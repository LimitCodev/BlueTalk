import 'dart:math' as math;
import 'dart:ui';

/// Una porción de la dona antes de asignarle color.
typedef PorcionDona = ({String etiqueta, int valor});

/// Un ángulo de la dona: empieza en [inicio] y abarca [barrido] radianes.
typedef AnguloDona = ({double inicio, double barrido});

/// Agrupa en «Otras» las porciones menores cuando hay más de cuatro.
///
/// Devuelve como mucho 5 porciones (4 + «Otras») ordenadas de mayor a menor.
List<PorcionDona> agruparDona(List<PorcionDona> datos) {
  final limpios = [
    for (final dato in datos)
      if (dato.valor > 0) dato,
  ]..sort((a, b) => b.valor.compareTo(a.valor));
  if (limpios.length <= 4) return limpios;
  final otras = limpios.skip(4).fold<int>(0, (suma, d) => suma + d.valor);
  return [...limpios.take(4), (etiqueta: 'Otras', valor: otras)];
}

/// Reparte 2π entre [valores] de forma proporcional.
///
/// La suma de los barridos es exactamente 2π. Con total 0 devuelve una lista
/// vacía: la tarjeta muestra el estado sin datos, nunca un círculo vacío.
List<AnguloDona> angulosDona(List<int> valores) {
  final total = valores.fold<int>(0, (suma, v) => suma + (v > 0 ? v : 0));
  if (total <= 0) return const [];
  final salida = <AnguloDona>[];
  var inicio = 0.0;
  for (final valor in valores) {
    final barrido = 2 * math.pi * (valor > 0 ? valor : 0) / total;
    salida.add((inicio: inicio, barrido: barrido));
    inicio += barrido;
  }
  if (salida.isNotEmpty) {
    final ultimo = salida.removeLast();
    salida.add((inicio: ultimo.inicio, barrido: 2 * math.pi - ultimo.inicio));
  }
  return salida;
}

/// Índice del segmento que corresponde a un toque, o null si no hay dona.
int? indiceDona(Offset punto, Size tamano, List<int> valores) {
  final angulos = angulosDona(valores);
  if (angulos.isEmpty) return null;
  final dx = punto.dx - tamano.width / 2;
  final dy = punto.dy - tamano.height / 2;
  var giro = math.atan2(dy, dx) + math.pi / 2;
  if (giro < 0) giro += 2 * math.pi;
  for (var i = 0; i < angulos.length; i++) {
    final fin = angulos[i].inicio + angulos[i].barrido;
    if (giro >= angulos[i].inicio && giro < fin) return i;
  }
  return null;
}
