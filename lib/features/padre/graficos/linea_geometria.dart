import 'dart:ui';

/// Puntos de la línea normalizados al máximo, sin dividir entre cero.
///
/// El primer punto va a la izquierda y el último a la derecha. Con un solo
/// valor se centra horizontalmente.
List<Offset> puntosLinea(List<num> valores, Size tamano) {
  if (valores.isEmpty) return const [];
  var maximo = 0.0;
  for (final valor in valores) {
    if (valor > maximo) maximo = valor.toDouble();
  }
  final ancho = valores.length == 1 ? 0.0 : tamano.width / (valores.length - 1);
  return [
    for (var i = 0; i < valores.length; i++)
      Offset(
        valores.length == 1 ? tamano.width / 2 : i * ancho,
        maximo <= 0
            ? tamano.height
            : tamano.height *
                (1 - (valores[i] < 0 ? 0 : valores[i]) / maximo),
      ),
  ];
}

/// Curva suave que pasa por todos los [puntos] (Catmull-Rom a Bézier).
Path caminoSuave(List<Offset> puntos) {
  final camino = Path()..moveTo(puntos.first.dx, puntos.first.dy);
  if (puntos.length == 1) return camino;
  for (var i = 0; i < puntos.length - 1; i++) {
    final anterior = i == 0 ? puntos[i] : puntos[i - 1];
    final actual = puntos[i];
    final siguiente = puntos[i + 1];
    final posterior = i + 2 < puntos.length ? puntos[i + 2] : siguiente;
    final c1 = Offset(
      actual.dx + (siguiente.dx - anterior.dx) / 6,
      actual.dy + (siguiente.dy - anterior.dy) / 6,
    );
    final c2 = Offset(
      siguiente.dx - (posterior.dx - actual.dx) / 6,
      siguiente.dy - (posterior.dy - actual.dy) / 6,
    );
    camino.cubicTo(
      c1.dx,
      c1.dy,
      c2.dx,
      c2.dy,
      siguiente.dx,
      siguiente.dy,
    );
  }
  return camino;
}
