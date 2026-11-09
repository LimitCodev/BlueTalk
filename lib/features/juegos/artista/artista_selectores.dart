import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'artista_botones.dart';
import 'artista_controller.dart';

/// Paleta de pinceles en una fila desplazable de 48 dp.
/// [antes] se llama antes de elegir (cancela un «¿Seguro?» pendiente).
class FilaColores extends ConsumerWidget {
  const FilaColores({super.key, required this.antes});

  final VoidCallback antes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(artistaProvider);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (nombre, color) in pincelesPastel)
            BotonColor(
              nombre: nombre,
              color: color,
              seleccionado: !estado.goma && estado.color == color,
              onTap: () {
                antes();
                ref.read(artistaProvider.notifier).elegirColor(color);
              },
            ),
        ],
      ),
    );
  }
}

/// Los tres grosores del pincel. [antes]: como en [FilaColores].
class FilaGrosores extends ConsumerWidget {
  const FilaGrosores({super.key, required this.antes});

  final VoidCallback antes;

  static const _grosores = [
    ('Fino', grosorFino),
    ('Medio', grosorMedio),
    ('Grosor', grosorGrueso),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actual = ref.watch(artistaProvider).grosor;
    return Wrap(
      spacing: 8,
      children: [
        for (final (etiqueta, grosor) in _grosores)
          BotonGrosor(
            etiqueta: etiqueta,
            grosor: grosor,
            activo: actual == grosor,
            onTap: () {
              antes();
              ref.read(artistaProvider.notifier).elegirGrosor(grosor);
            },
          ),
      ],
    );
  }
}
