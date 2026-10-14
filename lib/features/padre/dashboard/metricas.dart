import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../reloj.dart';

/// Métricas locales de uso para el dashboard del padre (plan 05 §2).
///
/// Se calculan sobre `UsageRepo` (cap 200 eventos), `GameProgressRepo`,
/// `ScheduleRepo` y `WellbeingRepo`: todo local, sin red. Se muestran con el
/// banner «Datos de demostración» hasta que exista sync real con Supabase.
class Metricas {
  const Metricas({
    required this.pictosHoy,
    required this.pictosDistintosHoy,
    required this.pictosPorCategoriaHoy,
    required this.nombresDeCategoria,
    required this.sesionesJuegoHoy,
    required this.segundosJuegoHoy,
    required this.dias,
    required this.eventosPorDia,
    required this.checkInsSemana,
    required this.cuentosCompletados,
    required this.dibujosGuardados,
    required this.nivelMemoria,
    required this.actividadesHorario,
    required this.actividadesHechasHoy,
  });

  /// Toques de pictogramas en las últimas 24 h.
  final int pictosHoy;
  final int pictosDistintosHoy;

  /// Toques de hoy agrupados por categoría (`categoryId` → toques).
  final Map<String, int> pictosPorCategoriaHoy;

  /// Nombre legible de cada categoría (`id` → nombre del seed).
  final Map<String, String> nombresDeCategoria;

  /// Sesiones de juego iniciadas y terminadas hoy.
  final int sesionesJuegoHoy;
  final int segundosJuegoHoy;

  /// Fechas de la gráfica de 7 días y sus totales de eventos.
  final List<DateTime> dias;
  final List<int> eventosPorDia;

  final int checkInsSemana;
  final int cuentosCompletados;
  final int dibujosGuardados;
  final int? nivelMemoria;
  final int actividadesHorario;

  /// Eventos `actividad_*` de hoy (marca de «hecha» del horario).
  final int actividadesHechasHoy;

  int get minutosJuegoHoy => segundosJuegoHoy ~/ 60;
}

/// Carga y agrega las métricas del dashboard.
final metricasProvider = FutureProvider<Metricas>((ref) async {
  final eventos = await ref.watch(usageRepoProvider).events();
  final ahora = ref.watch(relojProvider)();
  final categorias = await ref.watch(pictogramRepoProvider).categories();
  final memoria = await ref.watch(gameProgressRepoProvider).progress('memoria');
  final horario = await ref.watch(scheduleRepoProvider).schedule();
  final moods = await ref.watch(wellbeingRepoProvider).moods();

  final desde24h = ahora.subtract(const Duration(hours: 24));
  var pictosHoy = 0;
  final pictosDistintos = <String>{};
  final porCategoria = <String, int>{};
  var sesionesJuego = 0;
  var segundosJuego = 0;
  final cuentos = <String>{};
  var dibujos = 0;
  var actividadesHechas = 0;

  for (final evento in eventos) {
    switch (evento.type) {
      case 'picto_tap':
        if (evento.createdAt.isAfter(desde24h)) {
          pictosHoy++;
          final pictoId = evento.data['pictoId'];
          if (pictoId is String) pictosDistintos.add(pictoId);
          final categoria = evento.data['categoryId'];
          if (categoria is String) {
            porCategoria.update(categoria, (n) => n + 1, ifAbsent: () => 1);
          }
        }
      case 'juego_fin':
        if (mismoDia(evento.createdAt, ahora)) {
          sesionesJuego++;
          segundosJuego += (evento.data['segundos'] as num?)?.toInt() ?? 0;
        }
      case 'cuento_completado':
        final cuento = evento.data['cuento'];
        if (cuento is String) cuentos.add(cuento);
      case 'dibujo_guardado':
        dibujos++;
      default:
        // Marca de «hecha» del horario: el agente de rutinas aún no fija
        // el tipo exacto, se acepta cualquier `actividad_*`.
        if (evento.type.startsWith('actividad') &&
            mismoDia(evento.createdAt, ahora)) {
          actividadesHechas++;
        }
    }
  }

  final dias = ultimos7Dias(ahora);
  final eventosPorDia = [
    for (final dia in dias)
      eventos.where((evento) => mismoDia(evento.createdAt, dia)).length,
  ];

  final inicioSemana = dias.first;
  final checkInsSemana = moods
      .where(
        (mood) =>
            !mood.date.isBefore(inicioSemana) && !mood.date.isAfter(ahora),
      )
      .length;

  return Metricas(
    pictosHoy: pictosHoy,
    pictosDistintosHoy: pictosDistintos.length,
    pictosPorCategoriaHoy: porCategoria,
    nombresDeCategoria: {
      for (final categoria in categorias) categoria.id: categoria.name,
    },
    sesionesJuegoHoy: sesionesJuego,
    segundosJuegoHoy: segundosJuego,
    dias: dias,
    eventosPorDia: eventosPorDia,
    checkInsSemana: checkInsSemana,
    cuentosCompletados: cuentos.length,
    dibujosGuardados: dibujos,
    nivelMemoria: memoria?.level,
    actividadesHorario: horario.length,
    actividadesHechasHoy: actividadesHechas,
  );
});
