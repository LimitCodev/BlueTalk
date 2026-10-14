import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../dashboard/barras.dart';
import '../reloj.dart';

/// Disclaimer de salud, idéntico al plan 04 §2 (obligatorio en la
/// cabecera de la sección, también en la vista del padre).
const disclaimerSalud =
    'Esta app no reemplaza evaluación profesional. Consulta a tu especialista.';

const _emociones = ['😢', '🙁', '😐', '🙂', '😄'];
const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Cara del check-in emocional (1–5) como texto literal para tests y TTS.
String emocionDe(int mood) => _emociones[(mood - 1).clamp(0, 4)];

/// Fecha larga sin depender de `intl` («13 de octubre»).
String fechaLarga(DateTime fecha) => '${fecha.day} de ${_meses[fecha.month - 1]}';

/// Resumen semanal de check-ins y hábitos del niño (plan 05 §5).
class ResumenSalud {
  const ResumenSalud({
    required this.dias,
    required this.checkInsPorDia,
    required this.habitosHechos,
    required this.habitosTotal,
    required this.historial,
  });

  final List<DateTime> dias;
  final List<int> checkInsPorDia;
  final int habitosHechos;
  final int habitosTotal;

  /// Últimos check-ins de la semana, del más reciente al más antiguo.
  final List<(DateTime, int)> historial;

  int get checkInsSemana =>
      checkInsPorDia.fold(0, (total, dia) => total + dia);
}

final resumenSaludProvider = FutureProvider<ResumenSalud>((ref) async {
  final bienestar = ref.watch(wellbeingRepoProvider);
  final ahora = ref.read(relojProvider)();
  final dias = ultimos7Dias(ahora);

  final moods = await bienestar.moods();
  final habitos = await bienestar.habits();
  final inicioSemana = dias.first;

  final semana = moods
      .where((mood) => !mood.date.isBefore(inicioSemana) && !mood.date.isAfter(ahora))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final habitosSemana = habitos
      .where(
        (habito) =>
            !habito.date.isBefore(inicioSemana) && !habito.date.isAfter(ahora),
      )
      .toList();

  return ResumenSalud(
    dias: dias,
    checkInsPorDia: [
      for (final dia in dias)
        moods.where((mood) => mismoDia(mood.date, dia)).length,
    ],
    habitosHechos: habitosSemana.where((habito) => habito.done).length,
    habitosTotal: habitosSemana.length,
    historial: [
      for (final mood in semana.take(10)) (mood.date, mood.mood),
    ],
  );
});

/// Vista del padre para salud (plan 05 §5).
class SaludPadreScreen extends ConsumerWidget {
  const SaludPadreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen = ref.watch(resumenSaludProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const _DisclaimerSalud(),
        switch (resumen) {
          AsyncData(:final value) => _Cuerpo(resumen: value),
          AsyncError() => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No se pudo cargar el resumen de salud.'),
            ),
          _ => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        },
      ],
    );
  }
}

/// Cabecera con el disclaimer exacto del plan 04.
class _DisclaimerSalud extends StatelessWidget {
  const _DisclaimerSalud();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primaryStrong),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.medical_services_outlined,
            color: AppColors.primaryStrong,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              disclaimerSalud,
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.resumen});

  final ResumenSalud resumen;

  @override
  Widget build(BuildContext context) {
    final maximoDia = resumen.checkInsPorDia.isEmpty
        ? 1
        : resumen.checkInsPorDia.reduce((a, b) => a > b ? a : b);
    final total = resumen.checkInsSemana;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Check-ins de los últimos 7 días'),
        FilaMetrica(titulo: 'Total de check-ins', valor: '$total'),
        for (var i = 0; i < resumen.dias.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BarraDato(
              etiqueta: etiquetaDia(resumen.dias[i]),
              valor: maximoDia == 0 ? 0 : resumen.checkInsPorDia[i] / maximoDia,
              detalle: '${resumen.checkInsPorDia[i]}',
            ),
          ),
        const SectionHeader('Hábitos'),
        FilaMetrica(
          titulo: 'Hábitos marcados esta semana',
          valor: '${resumen.habitosHechos} de ${resumen.habitosTotal}',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BarraDato(
            etiqueta: 'Progreso de hábitos',
            valor: resumen.habitosTotal == 0
                ? 0
                : resumen.habitosHechos / resumen.habitosTotal,
            detalle: resumen.habitosTotal == 0
                ? 'sin datos'
                : '${resumen.habitosHechos} de ${resumen.habitosTotal}',
          ),
        ),
        const SectionHeader('Historial'),
        if (resumen.historial.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Todavía no hay check-ins esta semana.'),
          )
        else
          for (final (fecha, mood) in resumen.historial)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  Expanded(child: Text(fechaLarga(fecha))),
                  Text(
                    emocionDe(mood),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Datos guardados solo en este teléfono.',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
