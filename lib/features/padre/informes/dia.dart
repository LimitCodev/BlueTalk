/// Día de calendario local como clave estable `AAAA-MM-DD`.
///
/// Se usa la fecha local del teléfono, no UTC: «lunes» es el lunes de la
/// familia aunque viaje o cambie el horario de verano.
String claveDia(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';

DateTime fechaDeClave(String clave) {
  final p = clave.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

/// Los [n] días que terminan en [fin] (incluido), del más antiguo al último.
List<DateTime> diasHasta(DateTime fin, int n) => [
      for (var i = n - 1; i >= 0; i--) DateTime(fin.year, fin.month, fin.day - i),
    ];
