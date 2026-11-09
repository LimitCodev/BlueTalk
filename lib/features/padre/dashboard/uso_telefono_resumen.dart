import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../monitoreo/uso_telefono_controller.dart';
import '../monitoreo/uso_telefono_model.dart';
import '../monitoreo/uso_telefono_screen.dart';

/// Tarjeta compacta del diagnóstico de uso para el resumen del adulto.
class UsoTelefonoResumen extends ConsumerWidget {
  const UsoTelefonoResumen({super.key});

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
