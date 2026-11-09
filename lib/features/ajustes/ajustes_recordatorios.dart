import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/section_header.dart';
import 'settings_controller.dart';
import '../rutinas/recordatorios/recordatorios_controller.dart';
import 'ajustes_permiso_avisos.dart';
import 'ajustes_recordatorios_aviso.dart';

/// Recordatorios de rutina (plan 1.1): interruptor de `remindersEnabled`
/// y permiso de avisos pedido siempre con explicación literal previa.
class RecordatoriosSection extends ConsumerWidget {
  const RecordatoriosSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);
    final ajustes = asyncSettings.value;
    final activos = ajustes?.remindersEnabled ?? false;
    final permitido = ref.watch(notificacionesPermitidasProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Recordatorios'),
        // Con los ajustes ilegibles el interruptor no puede funcionar:
        // se explica en su sitio en vez de dejar un muñón silencioso
        // (revisión fase 1, BAJA).
        if (asyncSettings.hasError)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No se pueden cambiar los recordatorios ahora.'),
          )
        else
          SwitchListTile(
            title: const Text('Recordatorios de rutina'),
            subtitle: const Text('Avisa cada día de la próxima actividad.'),
            value: activos,
            onChanged: ajustes == null
                ? null
                : (valor) async {
                    if (!valor) {
                      await ref
                          .read(settingsProvider.notifier)
                          .setRemindersEnabled(false);
                      return;
                    }
                    // Encender: primero la explicación literal y después el
                    // permiso del sistema; nunca al arrancar (plan 1.1).
                    final continuar = await explicarPermisoRecordatorios(
                      context,
                    );
                    if (!continuar || !context.mounted) return;
                    final concedido = await ref
                        .read(recordatoriosProvider.notifier)
                        .pedirPermisoNotificaciones();
                    // El permiso puede haber cambiado fuera de la app.
                    ref.invalidate(notificacionesPermitidasProvider);
                    if (concedido) {
                      if (!context.mounted) return;
                      await ref
                          .read(settingsProvider.notifier)
                          .setRemindersEnabled(true);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se dio permiso. Los recordatorios no se activaron.',
                          ),
                        ),
                      );
                    }
                  },
          ),
        if (activos && permitido.value == false)
          const AvisoPermisoRecordatorios(),
      ],
    );
  }
}
