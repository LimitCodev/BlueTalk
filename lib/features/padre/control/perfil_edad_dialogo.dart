import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/plataforma/edicion.dart';
import '../perfil_edad.dart';

/// Elección del perfil de edad (fase 3b).
///
/// Tocar una opción la aplica enseguida: se cierra el diálogo y el adulto
/// ve el resultado. No hay «Guardar» que pueda olvidarse.
class PerfilEdadDialogo extends ConsumerWidget {
  const PerfilEdadDialogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actual = ref.watch(perfilEdadProvider);
    final directa = ref.watch(edicionDirectaProvider);

    return AlertDialog(
      title: const Text('Perfil de edad'),
      content: SingleChildScrollView(
        // El diálogo no trae Material propio y un ListTile lo exige.
        child: Material(
          type: MaterialType.transparency,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              Text(
                'Elige la edad del niño o niña. Con eso se ocultan categorías '
                'del comunicador que no son de esa edad'
                '${directa ? ' y se ajustan los grupos del filtro de páginas' : ''}. '
                'Puedes cambiarlo cuando quieras.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              for (final perfil in PerfilEdad.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    perfil == actual
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(perfil.titulo),
                  subtitle: Text(
                    directa
                        ? perfil.explicacion
                        : quitarFrasesDeFiltro(perfil.explicacion),
                  ),
                  onTap: () async {
                    await ref
                        .read(perfilEdadProvider.notifier)
                        .elegir(perfil);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
