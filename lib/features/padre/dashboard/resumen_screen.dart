import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../diagnostico/observaciones.dart';
import '../reloj.dart';
import 'barras.dart';
import 'metricas.dart';

/// Resumen del padre: banner de demostración, métricas locales y
/// observaciones con disclaimer (plan 05 §2–§3).
class ResumenScreen extends ConsumerWidget {
  const ResumenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricas = ref.watch(metricasProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const _BannerDemo(),
        switch (metricas) {
          AsyncData(:final value) => _Cuerpo(metricas: value),
          AsyncError() => _SinDatos(
              onReintentar: () => ref.invalidate(metricasProvider),
            ),
          _ => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        },
        const ObservacionesSection(),
      ],
    );
  }
}

/// Banner obligatorio: hasta que haya sync real, todo aquí es demostración.
class _BannerDemo extends StatelessWidget {
  const _BannerDemo();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: AppColors.onWarning, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos de demostración',
                  style: TextStyle(
                    color: AppColors.onWarning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Métricas calculadas localmente en este dispositivo. '
                  'Todavía no hay sincronización con la nube.',
                  style: TextStyle(color: AppColors.onWarning, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SinDatos extends StatelessWidget {
  const _SinDatos({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('No se pudieron cargar las métricas.'),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: onReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.metricas});

  final Metricas metricas;

  @override
  Widget build(BuildContext context) {
    final entradas = metricas.pictosPorCategoriaHoy.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categorias = entradas.take(3).toList();
    final maximoCategoria =
        entradas.isEmpty ? 1 : math.max(1, entradas.first.value);
    final maximoEventos = metricas.eventosPorDia.isEmpty
        ? 1
        : math.max(
            1,
            metricas.eventosPorDia.reduce((a, b) => a > b ? a : b),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Uso del día'),
        FilaMetrica(
          titulo: 'Pictogramas tocados hoy',
          valor: '${metricas.pictosHoy}',
        ),
        FilaMetrica(
          titulo: 'Pictogramas distintos hoy',
          valor: '${metricas.pictosDistintosHoy}',
        ),
        for (final categoria in categorias)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BarraDato(
              etiqueta: metricas.nombresDeCategoria[categoria.key] ??
                  categoria.key,
              valor: categoria.value / maximoCategoria,
              detalle: '${categoria.value}',
            ),
          ),
        const SectionHeader('Juegos'),
        FilaMetrica(
          titulo: 'Sesiones de juego hoy',
          valor: '${metricas.sesionesJuegoHoy}',
        ),
        FilaMetrica(
          titulo: 'Tiempo de juego hoy',
          valor: '${metricas.minutosJuegoHoy} min',
        ),
        FilaMetrica(
          titulo: 'Memoria: nivel alcanzado',
          valor: metricas.nivelMemoria == null ? '—' : '${metricas.nivelMemoria}',
        ),
        FilaMetrica(
          titulo: 'Cuentos completados',
          valor: '${metricas.cuentosCompletados}',
        ),
        FilaMetrica(
          titulo: 'Dibujos guardados',
          valor: '${metricas.dibujosGuardados}',
        ),
        const SectionHeader('Horario'),
        FilaMetrica(
          titulo: 'Actividades del horario',
          valor: '${metricas.actividadesHorario}',
        ),
        FilaMetrica(
          titulo: 'Actividades marcadas hoy',
          valor: '${metricas.actividadesHechasHoy}',
        ),
        const SectionHeader('Últimos 7 días'),
        for (var i = 0; i < metricas.dias.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BarraDato(
              etiqueta: etiquetaDia(metricas.dias[i]),
              valor: metricas.eventosPorDia[i] / maximoEventos,
              detalle: '${metricas.eventosPorDia[i]} eventos',
            ),
          ),
        FilaMetrica(
          titulo: 'Check-ins de ánimo (7 días)',
          valor: '${metricas.checkInsSemana}',
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Los datos se guardan solo en este teléfono y se muestran como '
            'demostración mientras no haya sincronización real.',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
