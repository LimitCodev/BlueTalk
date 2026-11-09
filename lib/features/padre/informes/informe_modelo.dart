/// Informe para la persona adulta (docente, madre, padre o apoderado).
///
/// Orientativo, nunca diagnóstico: la pantalla y el texto lo dicen siempre.
library;

enum Periodo {
  semana(7, 'semanal'),
  mes(30, 'mensual');

  const Periodo(this.dias, this.nombre);

  final int dias;
  final String nombre;
}

/// Totales de un periodo, para comparar con el anterior.
class Totales {
  const Totales({
    this.pictos = 0,
    this.pictosDistintos = 0,
    this.segundosJuego = 0,
    this.sesionesJuego = 0,
    this.cuentos = 0,
    this.dibujos = 0,
    this.actividades = 0,
  });

  final int pictos;
  final int pictosDistintos;
  final int segundosJuego;
  final int sesionesJuego;
  final int cuentos;
  final int dibujos;
  final int actividades;
}

/// Un día de la gráfica. [segundosPantalla] es `null` si no hay datos.
typedef PuntoDia = ({
  DateTime dia,
  int pictos,
  int segundosJuego,
  int? segundosPantalla,
});

typedef Ranking = List<({String nombre, int valor})>;

class Informe {
  const Informe({
    required this.periodo,
    required this.desde,
    required this.hasta,
    required this.diasConDatos,
    required this.serie,
    required this.actual,
    required this.anterior,
    required this.categorias,
    required this.pictos,
    required this.apps,
    required this.segundosPantalla,
    required this.diasConApps,
    required this.animos,
  });

  final Periodo periodo;
  final DateTime desde;
  final DateTime hasta;

  /// Días del periodo con algún uso de BlueTalk (honestidad del informe).
  final int diasConDatos;
  final List<PuntoDia> serie;
  final Totales actual;
  final Totales anterior;

  /// Más usados, de mayor a menor (como mucho 5).
  final Ranking categorias;
  final Ranking pictos;

  /// Apps del teléfono por segundos en primer plano (como mucho 5).
  final Ranking apps;

  /// Tiempo total de pantalla en los [diasConApps] días con datos.
  final int segundosPantalla;
  final int diasConApps;

  /// Check-ins de ánimo: valor 1–5 → veces.
  final Map<int, int> animos;
}
