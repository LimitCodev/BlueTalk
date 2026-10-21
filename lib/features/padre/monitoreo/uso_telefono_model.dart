/// Diagnóstico local del uso del teléfono (plan 14).
///
/// Solo contiene tiempos de primer plano por app. No hay mensajes,
/// pantallas, historiales ni contenido: esos datos no se leen nunca.
library;

/// Tiempo que una app estuvo en primer plano en el periodo consultado.
class UsoApp {
  const UsoApp({
    required this.paquete,
    required this.nombre,
    required this.segundos,
    this.iconoBase64,
  });

  final String paquete;
  final String nombre;
  final int segundos;

  /// Ícono PNG en base64 que entrega Android; puede faltar.
  final String? iconoBase64;

  factory UsoApp.fromMap(Map<Object?, Object?> map) => UsoApp(
        paquete: (map['paquete'] as String?) ?? '',
        nombre: (map['nombre'] as String?) ?? '',
        segundos: (map['segundos'] as num?)?.toInt() ?? 0,
        iconoBase64: map['icono'] as String?,
      );
}

/// Resumen de uso de un periodo, calculado en el teléfono.
class ResumenUso {
  const ResumenUso({
    required this.permiso,
    required this.totalSegundos,
    required this.apps,
    required this.desde,
    required this.hasta,
  });

  final bool permiso;
  final int totalSegundos;

  /// Apps ordenadas de mayor a menor tiempo (máximo 25).
  final List<UsoApp> apps;
  final DateTime desde;
  final DateTime hasta;

  static ResumenUso sinPermiso(DateTime desde, DateTime hasta) => ResumenUso(
        permiso: false,
        totalSegundos: 0,
        apps: const [],
        desde: desde,
        hasta: hasta,
      );

  factory ResumenUso.fromMap(Map<Object?, Object?> map) {
    final crudas = map['apps'];
    final apps = <UsoApp>[];
    if (crudas is List) {
      for (final item in crudas) {
        if (item is Map) apps.add(UsoApp.fromMap(item));
      }
    }
    apps.sort((a, b) => b.segundos.compareTo(a.segundos));
    return ResumenUso(
      permiso: map['permiso'] as bool? ?? false,
      totalSegundos: (map['totalSegundos'] as num?)?.toInt() ?? 0,
      apps: List.unmodifiable(apps),
      desde: DateTime.fromMillisecondsSinceEpoch(
        (map['desde'] as num?)?.toInt() ?? 0,
      ),
      hasta: DateTime.fromMillisecondsSinceEpoch(
        (map['hasta'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  /// La app con más tiempo, o `null` si no hubo uso.
  UsoApp? get appPrincipal => apps.isEmpty ? null : apps.first;

  int get segundosApps => apps.fold(0, (suma, app) => suma + app.segundos);
}

/// Texto humano y literal para una duración en segundos.
///
/// Ejemplos: «menos de 1 min», «45 min», «2 h 15 min», «3 h».
String formatearDuracion(int segundos) {
  if (segundos <= 0) return '0 min';
  if (segundos < 60) return 'menos de 1 min';
  final minutos = segundos ~/ 60;
  if (minutos < 60) return '$minutos min';
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  if (resto == 0) return '$horas h';
  return '$horas h $resto min';
}
