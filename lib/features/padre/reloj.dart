import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reloj inyectable de la zona de adultos.
///
/// El gate, el límite diario y el dashboard calculan «hoy» y el bloqueo
/// tras intentos fallidos con esta función; los tests la sustituyen por un
/// reloj falso para poder avanzar 60 segundos sin esperarlos.
final relojProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// ¿Dos instantes caen en el mismo día calendario?
bool mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Medianoche del día donde cae [fecha].
DateTime inicioDelDia(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);

/// Siete días terminados en [fecha] (el más antiguo primero).
List<DateTime> ultimos7Dias(DateTime fecha) => [
      for (var i = 6; i >= 0; i--)
        DateTime(fecha.year, fecha.month, fecha.day - i),
    ];

const _nombresDeDia = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

/// Etiqueta corta de un día para las gráficas («Lun», «Mar»…).
String etiquetaDia(DateTime fecha) => _nombresDeDia[fecha.weekday % 7];
