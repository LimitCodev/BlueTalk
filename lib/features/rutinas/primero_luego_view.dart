import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import 'cabecera_vista.dart';
import 'primero_luego_tarjeta.dart';
import 'rutinas_providers.dart';

/// Pendiente que sigue a la próxima actividad; null si es la última de hoy.
final luegoActividadProvider = FutureProvider<ScheduleEntry?>((ref) async {
  final primero = await ref.watch(proximaActividadProvider.future);
  if (primero == null) return null;
  final entradas = await ref.watch(horarioProvider.future);
  final hechas = await ref.watch(hechasHoyProvider.future);
  final posicion = entradas.indexWhere((e) => e.id == primero.id);
  return entradas
      .skip(posicion + 1)
      .where((e) => !hechas.contains(e.id))
      .firstOrNull;
});

/// Vista «Primero y luego» (plan 11 §2.2): qué toca ahora y qué viene después.
class PrimeroLuegoView extends ConsumerWidget {
  const PrimeroLuegoView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const CabeceraVista(titulo: 'Primero y luego'),
        Expanded(child: _contenido(ref)),
      ],
    );
  }

  Widget _contenido(WidgetRef ref) {
    final primero = ref.watch(proximaActividadProvider);
    if (primero.hasError && !primero.hasValue) {
      return const _Aviso('No se pudo cargar el horario.');
    }
    // `hasValue` y no un `switch`: al marcar «Listo» no parpadea un spinner.
    if (!primero.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final actual = primero.value;
    if (actual == null) {
      final hayActividades = ref.watch(horarioProvider).value?.isNotEmpty;
      return _Aviso(
        hayActividades ?? false
            ? 'Ya hiciste todas las actividades de hoy.'
            : 'Todavía no hay actividades en tu horario.',
      );
    }
    return PasosPrimeroLuego(
      primero: actual,
      luego: ref.watch(luegoActividadProvider).value,
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
