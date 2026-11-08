import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../juegos_catalog.dart';
import 'cuentos_controller.dart';
import 'cuentos_opcion_tarea.dart';

/// Tarea "¡Completar cuento!": una página con un hueco y 3 opciones
/// táctiles. Tocar la correcta completa el cuento.
class TareaCompletar extends ConsumerWidget {
  const TareaCompletar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cuentosProvider).requireValue;
    final cuentos = ref.watch(cuentosSeedProvider).value ?? const [];
    final pictos = ref.watch(pictosProvider).value ?? const [];

    Story? cuento;
    for (final c in cuentos) {
      if (c.id == estado.storyId) cuento = c;
    }
    if (cuento == null || estado.opciones.isEmpty) {
      return const Center(child: Text('Este cuento no tiene imagen.'));
    }

    final opciones = [
      for (final id in estado.opciones)
        for (final picto in pictos)
          if (picto.id == id) picto,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '¡Completar cuento!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            cuento.pages.last,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          // Hueco: el sitio de la imagen que falta.
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: context.colores.bg,
              border: Border.all(
                color: context.colores.primaryStrong,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 44,
                color: context.colores.primaryStrong,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca la imagen que falta.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final opcion in opciones)
                OpcionTarea(
                  picto: opcion,
                  incorrecta: estado.opcionIncorrecta == opcion.id,
                  onTap: () =>
                      ref.read(cuentosProvider.notifier).tocarOpcion(opcion.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
