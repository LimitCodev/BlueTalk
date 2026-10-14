import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../data/models/models.dart';

/// Clave estable de un día (`2026-10-13`) para los ids de check-ins y
/// hábitos: permite filtrar "lo de hoy" sin un campo de fecha nuevo.
String claveFecha(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';

/// Hora en texto a partir de minutos desde medianoche (570 → "09:30").
String formatHora(int timeMinutes) =>
    '${(timeMinutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(timeMinutes % 60).toString().padLeft(2, '0')}';

/// Actividades habilitadas del día, ordenadas por hora.
final horarioProvider = FutureProvider<List<ScheduleEntry>>((ref) async {
  final entries = await ref.watch(scheduleRepoProvider).schedule();
  final activas = [for (final e in entries) if (e.enabled) e];
  return activas..sort((a, b) => a.timeMinutes.compareTo(b.timeMinutes));
});

/// Mapa de todos los pictogramas por id (horario, hábitos y entorno).
final pictosPorIdProvider = FutureProvider<Map<String, Pictogram>>(
  (ref) async {
    final repo = ref.watch(pictogramRepoProvider);
    final categorias = await repo.categories();
    final map = <String, Pictogram>{};
    for (final categoria in categorias) {
      for (final picto in await repo.pictogramsOf(categoria.id)) {
        map[picto.id] = picto;
      }
    }
    return map;
  },
);

/// Ids de las actividades marcadas como hechas HOY.
///
/// El estado "hecha" vive en los eventos de uso (`actividad_hecha` /
/// `actividad_pendiente`, el último evento del día manda): así no se
/// ensucia la lista de hábitos que lee el dashboard del modo padre, y el
/// "hecho" es del día, no de la actividad para siempre.
final hechasHoyProvider = FutureProvider<Set<String>>((ref) async {
  final eventos = await ref.watch(usageRepoProvider).events();
  final hoy = claveFecha(DateTime.now());
  final ultimo = <String, bool>{};
  for (final evento in eventos) {
    if (evento.type != 'actividad_hecha' &&
        evento.type != 'actividad_pendiente') {
      continue;
    }
    final entradaId = evento.data['entradaId'];
    if (entradaId is! String || claveFecha(evento.createdAt) != hoy) continue;
    ultimo[entradaId] = evento.type == 'actividad_hecha';
  }
  return {for (final e in ultimo.entries) if (e.value) e.key};
});

/// Marca o desmarca una actividad como hecha (feedback inmediato; el
/// registro persiste vía `UsageRepo` y alimenta las estadísticas).
Future<void> marcarActividad(
  WidgetRef ref,
  ScheduleEntry entry, {
  required bool hecha,
}) async {
  final ahora = DateTime.now();
  await ref.read(usageRepoProvider).record(
        UsageEvent(
          id: 'act_${entry.id}_${ahora.microsecondsSinceEpoch}',
          type: hecha ? 'actividad_hecha' : 'actividad_pendiente',
          createdAt: ahora,
          data: {'entradaId': entry.id},
        ),
      );
  ref.invalidate(hechasHoyProvider);
  ref.invalidate(resumenUsoProvider);
}

/// Siguiente actividad pendiente (la de hora >= ahora; si ya pasaron todas,
/// la primera pendiente como "mañana"), o null si no queda ninguna.
final proximaActividadProvider = FutureProvider<ScheduleEntry?>((ref) async {
  final entradas = await ref.watch(horarioProvider.future);
  final hechas = await ref.watch(hechasHoyProvider.future);
  final pendientes = [
    for (final e in entradas)
      if (!hechas.contains(e.id)) e,
  ];
  if (pendientes.isEmpty) return null;

  final ahora = DateTime.now();
  final minutosAhora = ahora.hour * 60 + ahora.minute;
  for (final entrada in pendientes) {
    if (entrada.timeMinutes >= minutosAhora) return entrada;
  }
  return pendientes.first;
});

// --- Edición del horario (vista de persona adulta) ---

/// Guarda una actividad (nueva o editada) y refresca el horario.
Future<void> guardarActividad(WidgetRef ref, ScheduleEntry entry) async {
  await ref.read(scheduleRepoProvider).saveEntry(entry);
  ref.invalidate(horarioProvider);
}

/// Quita una actividad del horario del niño.
///
/// El contrato actual no tiene "borrar": se deshabilita (enabled=false) y la
/// vista de edición la lista en "Actividades quitadas" con opción de
/// restaurar. Si más adelante `ScheduleRepo` gana un delete, este es el
/// único punto a cambiar.
Future<void> quitarActividad(WidgetRef ref, ScheduleEntry entry) =>
    guardarActividad(ref, ScheduleEntry(
      id: entry.id,
      title: entry.title,
      timeMinutes: entry.timeMinutes,
      pictoId: entry.pictoId,
      enabled: false,
    ));

/// Nueva id para una actividad creada en la app.
String nuevaIdActividad() =>
    'act_${DateTime.now().microsecondsSinceEpoch}';

// --- Estadísticas básicas (plan 04 §4) ---

/// Resumen de uso: eventos por día (últimos 7), check-ins de ánimo de la
/// semana y actividades hechas de hoy. Sin librerías de gráficas.
class ResumenUso {
  const ResumenUso({
    required this.usoPorDia,
    required this.checkinsSemana,
    required this.hechasHoy,
    required this.actividadesHoy,
  });

  /// (fecha corta, cantidad de eventos) de los últimos 7 días, más antiguo
  /// primero.
  final List<(String, int)> usoPorDia;

  /// Check-ins de ánimo registrados en los últimos 7 días.
  final int checkinsSemana;
  final int hechasHoy;
  final int actividadesHoy;
}

/// Uso por día y check-ins leídos de los repos locales (offline).
final resumenUsoProvider = FutureProvider<ResumenUso>((ref) async {
  final eventos = await ref.watch(usageRepoProvider).events();
  final moods = await ref.watch(wellbeingRepoProvider).moods();
  final entradas = await ref.watch(horarioProvider.future);
  final hechas = await ref.watch(hechasHoyProvider.future);

  final hoy = DateTime.now();
  final conteo = <String, int>{};
  final etiquetas = <String, String>{};
  for (var i = 6; i >= 0; i--) {
    final dia = DateTime(hoy.year, hoy.month, hoy.day).subtract(
      Duration(days: i),
    );
    final clave = claveFecha(dia);
    conteo[clave] = 0;
    etiquetas[clave] = '${dia.day}/${dia.month}';
  }

  var checkinsSemana = 0;
  for (final evento in eventos) {
    final clave = claveFecha(evento.createdAt);
    if (conteo.containsKey(clave)) conteo[clave] = conteo[clave]! + 1;
  }
  for (final mood in moods) {
    if (conteo.containsKey(claveFecha(mood.date))) checkinsSemana++;
  }

  return ResumenUso(
    usoPorDia: [
      for (final clave in conteo.keys) (etiquetas[clave]!, conteo[clave]!),
    ],
    checkinsSemana: checkinsSemana,
    hechasHoy: hechas.length,
    actividadesHoy: entradas.length,
  );
});
