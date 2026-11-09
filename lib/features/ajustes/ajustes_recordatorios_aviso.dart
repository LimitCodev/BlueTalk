import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../rutinas/recordatorios/recordatorios_controller.dart';
import 'ajustes_permiso_avisos.dart';

/// Recordatorios encendidos pero Android sin permiso de avisos: explica el
/// motivo y ofrece pedirlo otra vez (con la explicación previa).
class AvisoPermisoRecordatorios extends ConsumerWidget {
  const AvisoPermisoRecordatorios({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Android necesita tu permiso para mostrar los avisos.'),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () async {
              final continuar = await explicarPermisoRecordatorios(context);
              if (!continuar || !context.mounted) return;
              final concedido = await ref
                  .read(recordatoriosProvider.notifier)
                  .pedirPermisoNotificaciones();
              ref.invalidate(notificacionesPermitidasProvider);
              if (!concedido && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No se concedió. Actívalo en los ajustes de Android.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Activar recordatorios'),
          ),
        ],
      ),
    );
  }
}
