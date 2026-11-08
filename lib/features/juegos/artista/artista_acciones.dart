import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'artista_controller.dart';
import 'artista_dibujos.dart';

/// Guarda el dibujo y avisa del resultado (o de que la galería está llena).
Future<void> guardarDibujo(BuildContext context, WidgetRef ref) async {
  final guardado = await ref.read(artistaProvider.notifier).guardar();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          guardado
              ? 'Dibujo guardado en Mis dibujos'
              : 'Tu galería ya tiene ${GaleriaController.maxDibujos} dibujos. '
                    'Borra uno de Mis dibujos para guardar este.',
        ),
      ),
    );
}
