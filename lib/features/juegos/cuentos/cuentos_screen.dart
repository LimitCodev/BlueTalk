import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cabecera_juego.dart';
import 'cuentos_controller.dart';
import 'cuentos_cabecera.dart';
import 'cuentos_completado.dart';
import 'cuentos_lector.dart';
import 'cuentos_lista.dart';
import 'cuentos_tarea.dart';

/// Juego cuentos interactivos (plan 03 §3): lista, lector de páginas y
/// tarea "¡Completar cuento!".
class CuentosScreen extends ConsumerWidget {
  const CuentosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cuentosProvider);

    return switch (estado) {
      AsyncData(:final value) =>
        value.enLista
            ? const Column(
                children: [
                  CabeceraJuego('Cuentos interactivos'),
                  Expanded(child: ListaCuentos()),
                ],
              )
            : Column(
                children: [
                  CabeceraCuentos(storyId: value.storyId!),
                  Expanded(
                    child: switch (value.fase) {
                      CuentoFase.leyendo => const LectorCuento(),
                      CuentoFase.completar => const TareaCompletar(),
                      CuentoFase.completado => const CuentoCompletado(),
                    },
                  ),
                ],
              ),
      AsyncError() => const Center(
        child: Text('No se pudieron cargar los cuentos.'),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
