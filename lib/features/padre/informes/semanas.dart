import 'informe_modelo.dart';

typedef Semana = ({
  DateTime desde,
  DateTime hasta,
  int pictos,
  int segundosJuego,
  int? segundosPantalla,
});

/// Agrupa la serie diaria en tramos de 7 días desde el más antiguo; el
/// último tramo puede ser más corto. La pantalla es `null` si ningún día
/// del tramo tiene datos (no se inventa un cero).
List<Semana> porSemanas(List<PuntoDia> serie) => [
      for (var i = 0; i < serie.length; i += 7)
        _sumar(serie.sublist(i, i + 7 > serie.length ? serie.length : i + 7)),
    ];

Semana _sumar(List<PuntoDia> dias) {
  final conPantalla = dias.where((d) => d.segundosPantalla != null);
  return (
    desde: dias.first.dia,
    hasta: dias.last.dia,
    pictos: dias.fold(0, (s, d) => s + d.pictos),
    segundosJuego: dias.fold(0, (s, d) => s + d.segundosJuego),
    segundosPantalla: conPantalla.isEmpty
        ? null
        : conPantalla.fold<int>(0, (s, d) => s + d.segundosPantalla!),
  );
}
