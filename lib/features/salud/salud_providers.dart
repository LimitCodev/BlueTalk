import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../data/models/models.dart';
import '../rutinas/rutinas_providers.dart' show claveFecha;

/// Opción de check-in emocional: mood 1–5 con picto y etiqueta literal.
class OpcionEmocion {
  const OpcionEmocion({
    required this.mood,
    required this.pictoId,
    required this.label,
  });

  final int mood;
  final String pictoId;
  final String label;
}

/// Emociones del check-in: los 5 pictos de la categoría `emociones` del
/// semilla (plan 04 §2). Literal, sin metáforas.
const opcionesEmocion = <OpcionEmocion>[
  OpcionEmocion(mood: 1, pictoId: 'sad_man', label: 'Triste'),
  OpcionEmocion(mood: 2, pictoId: 'angry_man', label: 'Enojado'),
  OpcionEmocion(mood: 3, pictoId: 'worried_man', label: 'Preocupado'),
  OpcionEmocion(mood: 4, pictoId: 'afraid_man', label: 'Asustado'),
  OpcionEmocion(mood: 5, pictoId: 'happy_man', label: 'Feliz'),
];

/// Hábito simple del día (plan 04 §2): semilla configurable en código;
/// la persistencia es por día vía `WellbeingRepo`.
class HabitoDia {
  const HabitoDia({
    required this.id,
    required this.title,
    this.pictoId,
  });

  final String id;
  final String title;
  final String? pictoId;
}

/// Semilla de hábitos: agua, descanso visual, movimiento y descanso.
const semillaHabitos = <HabitoDia>[
  HabitoDia(id: 'agua', title: 'Tomar agua', pictoId: 'water'),
  HabitoDia(id: 'vista', title: 'Descansar la vista'),
  HabitoDia(id: 'movimiento', title: 'Moverme un rato', pictoId: 'run_,_to'),
  HabitoDia(id: 'descanso', title: 'Descansar', pictoId: 'sleep_male_,_to'),
];

/// Check-in de ánimo de HOY (el último de hoy manda; null si aún no hay).
final emocionDeHoyProvider = FutureProvider<MoodEntry?>((ref) async {
  final moods = await ref.watch(wellbeingRepoProvider).moods();
  final hoy = claveFecha(DateTime.now());
  MoodEntry? ultimo;
  for (final mood in moods) {
    if (claveFecha(mood.date) == hoy) ultimo = mood;
  }
  return ultimo;
});

/// Registra el check-in emocional de hoy (alimenta el dashboard padre).
Future<void> registrarEmocion(WidgetRef ref, OpcionEmocion opcion) async {
  final ahora = DateTime.now();
  await ref.read(wellbeingRepoProvider).addMood(
        MoodEntry(
          id: 'mood_${ahora.microsecondsSinceEpoch}',
          date: ahora,
          mood: opcion.mood,
        ),
      );
  ref.invalidate(emocionDeHoyProvider);
  ref.invalidate(resumenSemanaProvider);
}

/// Hábitos marcados hoy: id de hábito → true.
final habitosHoyProvider = FutureProvider<Set<String>>((ref) async {
  final habits = await ref.watch(wellbeingRepoProvider).habits();
  final hoy = claveFecha(DateTime.now());
  return {
    for (final habit in habits)
      if (habit.done &&
          habit.id.startsWith('hab_') &&
          habit.id.endsWith('_$hoy'))
        habit.id.split('_')[1],
  };
});

/// Id fechado de un hábito (`hab_agua_2026-10-13`).
String idHabito(String habitoId, DateTime dia) =>
    'hab_${habitoId}_${claveFecha(dia)}';

/// Marca o desmarca un hábito de hoy.
Future<void> alternarHabito(WidgetRef ref, HabitoDia habito) async {
  final ahora = DateTime.now();
  final marcados = await ref.read(wellbeingRepoProvider).habits();
  final actual = marcados.any(
    (h) => h.id == idHabito(habito.id, ahora) && h.done,
  );

  await ref.read(wellbeingRepoProvider).saveHabit(
        HabitEntry(
          id: idHabito(habito.id, ahora),
          date: ahora,
          title: habito.title,
          pictoId: habito.pictoId,
          done: !actual,
        ),
      );
  ref.invalidate(habitosHoyProvider);
  ref.invalidate(resumenSemanaProvider);
}

/// Check-ins de la semana (últimos 7 días) para la sección de estadísticas.
final resumenSemanaProvider = FutureProvider<int>((ref) async {
  final moods = await ref.watch(wellbeingRepoProvider).moods();
  final hoy = DateTime.now();
  final inicio = DateTime(hoy.year, hoy.month, hoy.day)
      .subtract(const Duration(days: 6));
  return moods.where((m) => !m.date.isBefore(inicio)).length;
});
