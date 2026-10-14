import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/models.dart';
import '../reloj.dart';

/// Disclaimer obligatorio de toda observación (plan 05 §3).
const disclaimerObservaciones =
    'Orientativa, no es diagnóstico clínico. No sustituye a un profesional.';

enum SeveridadObservacion { info, atencion }

/// Salida del motor: una regla del seed que se cumple, con su detalle.
class Observacion {
  const Observacion({
    required this.id,
    required this.label,
    required this.detalle,
    required this.severidad,
  });

  final String id;

  /// Texto de la regla (`assets/seed/reglas.json`).
  final String label;

  /// Cifras concretas que explican por qué saltó la regla.
  final String detalle;

  final SeveridadObservacion severidad;
}

/// Motor determinista de observaciones (plan 05 §3).
///
/// Solo reglas conocidas de `reglas.json`; sin datos suficientes no se emite
/// nada (evita avisos vacíos en una app recién instalada). Pensado para
/// enchufar Supabase después sin tocar el motor: entra por parámetros.
List<Observacion> evaluarReglas({
  required List<ObservationRule> reglas,
  required List<UsageEvent> eventos,
  required List<MoodEntry> moods,
  required List<HabitEntry> habitos,
  required DateTime ahora,
}) {
  final desde24h = ahora.subtract(const Duration(hours: 24));
  final inicioSemana = DateTime(ahora.year, ahora.month, ahora.day - 6);

  final taps = eventos
      .where((e) => e.type == 'picto_tap' && e.createdAt.isAfter(desde24h))
      .toList();
  final sesiones = eventos
      .where((e) => e.type == 'juego_fin' && e.createdAt.isAfter(desde24h))
      .toList();
  final moodsSemana = moods
      .where((m) => !m.date.isBefore(inicioSemana) && !m.date.isAfter(ahora))
      .toList();
  final habitosSemana = habitos
      .where((h) => !h.date.isBefore(inicioSemana) && !h.date.isAfter(ahora))
      .toList();

  final salidas = <Observacion>[];
  void emitir(ObservationRule regla, String detalle, SeveridadObservacion severidad) {
    salidas.add(
      Observacion(
        id: regla.id,
        label: regla.label,
        detalle: detalle,
        severidad: severidad,
      ),
    );
  }

  for (final regla in reglas) {
    if (!regla.enabled) continue;

    switch (regla.id) {
      case 'r_pocos_pictos':
        if (taps.isEmpty) break;
        final distintos = {
          for (final tap in taps)
            if (tap.data['pictoId'] is String) tap.data['pictoId'] as String,
        }.length;
        if (distintos < 5) {
          emitir(
            regla,
            'Ha tocado $distintos pictogramas distintos en las últimas 24 '
            'horas; lo recomendado es superar 5.',
            SeveridadObservacion.info,
          );
        }
      case 'r_poco_tiempo':
        final conDuracion = [
          for (final sesion in sesiones)
            if (sesion.data['segundos'] is num)
              (sesion.data['segundos'] as num).toInt(),
        ];
        if (conDuracion.length >= 2) {
          final media =
              conDuracion.reduce((a, b) => a + b) / conDuracion.length;
          if (media < 60) {
            emitir(
              regla,
              'Las sesiones de juego de las últimas 24 horas duran una media '
              'de ${media.round()} segundos.',
              SeveridadObservacion.info,
            );
          }
        }
      case 'r_cambio_humor':
        if (moodsSemana.length >= 3) {
          final valores = moodsSemana.map((m) => m.mood).toList()..sort();
          if (valores.last - valores.first >= 3) {
            emitir(
              regla,
              'Entre los ${moodsSemana.length} check-ins de la semana la '
              'carita pasa de ${valores.first} a ${valores.last} '
              '(escala del 1 al 5).',
              SeveridadObservacion.atencion,
            );
          }
        }
      case 'r_habito_sin_completar':
        final porTitulo = <String, List<HabitEntry>>{};
        for (final habito in habitosSemana) {
          porTitulo.putIfAbsent(habito.title, () => []).add(habito);
        }
        for (final entrada in porTitulo.entries) {
          final diasSinMarcar = <String>{};
          for (final habito in entrada.value) {
            if (!habito.done) diasSinMarcar.add(inicioDelDia(habito.date).toIso8601String());
          }
          if (diasSinMarcar.length >= 3) {
            emitir(
              regla,
              'El hábito «${entrada.key}» quedó sin marcar en '
              '${diasSinMarcar.length} de los últimos 7 días.',
              SeveridadObservacion.atencion,
            );
            break; // un aviso por hábito es suficiente
          }
        }
      case 'r_mismo_picto':
        if (taps.length >= 10) {
          final conteo = <String, int>{};
          for (final tap in taps) {
            final pictoId = tap.data['pictoId'];
            if (pictoId is String) {
              conteo.update(pictoId, (n) => n + 1, ifAbsent: () => 1);
            }
          }
          if (conteo.isNotEmpty) {
            final maximo = conteo.values.reduce((a, b) => a > b ? a : b);
            final porcentaje = (maximo * 100) ~/ taps.length;
            if (porcentaje >= 60) {
              emitir(
                regla,
                'Un mismo pictograma supone el $porcentaje% de los toques '
                'de las últimas 24 horas.',
                SeveridadObservacion.info,
              );
            }
          }
        }
      default:
        // Reglas futuras se ignoran hasta que el motor las conozca.
        break;
    }
  }
  return salidas;
}

/// Observaciones generadas a partir de las reglas del seed.
final observacionesProvider = FutureProvider<List<Observacion>>((ref) async {
  final filas = await ref.watch(seedStoreProvider).list('reglas');
  final reglas = [for (final fila in filas) ObservationRule.fromMap(fila)];
  final eventos = await ref.watch(usageRepoProvider).events();
  final bienestar = ref.watch(wellbeingRepoProvider);
  final moods = await bienestar.moods();
  final habitos = await bienestar.habits();

  return evaluarReglas(
    reglas: reglas,
    eventos: eventos,
    moods: moods,
    habitos: habitos,
    ahora: ref.watch(relojProvider)(),
  );
});

/// Sección «Observaciones» con su disclaimer siempre visible.
class ObservacionesSection extends ConsumerWidget {
  const ObservacionesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observaciones = ref.watch(observacionesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Observaciones'),
        switch (observaciones) {
          AsyncData(:final value) when value.isEmpty => const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                'Todavía no hay observaciones. Aparecerán cuando haya datos '
                'de uso del niño.',
              ),
            ),
          AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final observacion in value)
                  _TarjetaObservacion(observacion: observacion),
              ],
            ),
          AsyncError() => const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text('No se pudieron cargar las observaciones.'),
            ),
          _ => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        },
        const _Disclaimer(),
      ],
    );
  }
}

class _TarjetaObservacion extends StatelessWidget {
  const _TarjetaObservacion({required this.observacion});

  final Observacion observacion;

  @override
  Widget build(BuildContext context) {
    final atencion = observacion.severidad == SeveridadObservacion.atencion;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              atencion ? Icons.warning_amber_outlined : Icons.lightbulb_outline,
              color: AppColors.primaryStrong,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          observacion.label,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: atencion
                              ? AppColors.warning
                              : AppColors.primary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          atencion ? 'Atención' : 'Información',
                          style: TextStyle(
                            fontSize: 12,
                            color: atencion
                                ? AppColors.onWarning
                                : AppColors.primaryInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    observacion.detalle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Disclaimer fijo de la sección (no depende de los datos cargados).
class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primaryStrong),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined,
              color: AppColors.primaryStrong, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text(disclaimerObservaciones, style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
