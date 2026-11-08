import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../diagnostico/observaciones.dart';
import '../monitoreo/uso_telefono_controller.dart';
import '../monitoreo/uso_telefono_model.dart';
import '../monitoreo/uso_telefono_screen.dart';
import '../reloj.dart';
import '../informes/informes_screen.dart';
import 'banner_demo.dart';
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
        const BannerDemo(),
        const AccesoInformes(),
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
        const _UsoTelefonoResumen(),
        const ObservacionesSection(),
      ],
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

/// Tarjeta compacta del diagnóstico de uso para el resumen del adulto.
class _UsoTelefonoResumen extends ConsumerWidget {
  const _UsoTelefonoResumen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permiso = ref.watch(permisoUsoProvider);
    final resumen = ref.watch(resumenUsoProvider);
    final periodo = ref.watch(periodoUsoProvider);

    void abrir() => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const UsoTelefonoScreen()),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Uso del teléfono'),
        Card(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: abrir,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.insights_outlined,
                    color: context.colores.primaryStrongText,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: switch ((permiso.value, resumen.value)) {
                      (false, _) || (null, _) => const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activar diagnóstico de uso',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Falta el permiso «Acceso al uso» de Android.',
                            ),
                          ],
                        ),
                      (true, final ResumenUso valor) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${periodo.titulo}: '
                              '${formatearDuracion(valor.totalSegundos)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              valor.appPrincipal == null
                                  ? 'Sin uso registrado en el periodo.'
                                  : 'Más tiempo: '
                                      '${valor.appPrincipal!.nombre} '
                                      '(${formatearDuracion(valor.appPrincipal!.segundos)})',
                            ),
                          ],
                        ),
                      _ => const Text('Leyendo el uso del teléfono…'),
                    },
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
