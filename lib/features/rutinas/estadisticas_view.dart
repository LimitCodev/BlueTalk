import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/section_header.dart';
import 'horario_view.dart';
import 'rutinas_controller.dart';
import 'rutinas_providers.dart';

/// Estadísticas básicas junto al horario (plan 04 §4): uso por día,
/// check-ins de la semana y avance del día. Barras hechas en Flutter
/// (sin recharts ni librerías de gráficas).
class EstadisticasView extends ConsumerWidget {
  const EstadisticasView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen = ref.watch(resumenUsoProvider);

    return switch (resumen) {
      AsyncData(:final value) => _EstadisticasContenido(resumen: value),
      AsyncError() => const Center(
          child: Text('No se pudieron cargar las estadísticas.'),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _EstadisticasContenido extends ConsumerWidget {
  const _EstadisticasContenido({required this.resumen});

  final ResumenUso resumen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maximo = resumen.usoPorDia.fold<int>(
      1,
      (max, dia) => dia.$2 > max ? dia.$2 : max,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
          child: Row(
            children: [
              OutlinedButton.icon(
                style:
                    OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
                onPressed: () =>
                    ref.read(rutinasProvider.notifier).irAlInicio(),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Volver'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mis estadísticas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SectionHeader('Uso de la app (7 días)'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Acciones hechas por día',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (dia, cantidad) in resumen.usoPorDia)
                      Expanded(
                        child: _BarraDiaria(
                          etiqueta: dia,
                          cantidad: cantidad,
                          altura: 96 * cantidad / maximo,
                        ),
                      ),
                  ],
                ),
              ),
              const SectionHeader('Mis check-ins'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Check-ins de ánimo esta semana: '
                  '${resumen.checkinsSemana}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SectionHeader('Mi día'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Actividades hechas hoy: ${resumen.hechasHoy} de '
                  '${resumen.actividadesHoy}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: BarraDia(
                  valor: resumen.actividadesHoy == 0
                      ? 0
                      : resumen.hechasHoy / resumen.actividadesHoy,
                  etiqueta: '${resumen.hechasHoy} de ${resumen.actividadesHoy} '
                      'actividades hechas hoy',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Barra vertical de un día (7 en fila), con semántica por barra.
class _BarraDiaria extends StatelessWidget {
  const _BarraDiaria({
    required this.etiqueta,
    required this.cantidad,
    required this.altura,
  });

  final String etiqueta;
  final int cantidad;
  final double altura;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        value: '$etiqueta: $cantidad acciones',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$cantidad',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Container(
              height: altura < 4 ? 4 : altura,
              decoration: const BoxDecoration(
                color: Color(0xFF7FC9EA),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(etiqueta, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
