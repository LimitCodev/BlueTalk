import 'package:flutter/material.dart';


/// Explicación literal previa a pedir el permiso de notificaciones
/// (plan 1.1): nunca se pide al arrancar, solo desde Ajustes.
/// Devuelve `true` si el usuario quiere continuar al permiso del sistema.
Future<bool> explicarPermisoRecordatorios(BuildContext context) async {
  final continuar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Activar recordatorios'),
      content: const Text(
        'BlueTalk avisará cada día de la próxima actividad del niño. '
        'Después Android te pedirá su permiso para mostrar los avisos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Activar recordatorios'),
        ),
      ],
    ),
  );
  return continuar ?? false;
}
