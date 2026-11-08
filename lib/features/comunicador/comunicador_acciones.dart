import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../data/models/models.dart';
import 'comunicador_catalog.dart';
import 'comunicador_controller.dart';
import 'comunicador_prefs.dart';
import 'phrase_controller.dart';
import 'saved_messages.dart';
import 'speak_action.dart';

/// Tocar un picto: agrega a la frase, registra el uso y habla si está activo.
Future<void> onPictoTap(
  BuildContext context,
  WidgetRef ref,
  Pictogram picto,
) async {
  ref.read(phraseProvider.notifier).add(picto);

  // Alimenta el dashboard del modo padre (plan 02 §6).
  unawaited(
    ref
        .read(usageRepoProvider)
        .record(
          UsageEvent(
            id: '${picto.id}_${DateTime.now().microsecondsSinceEpoch}',
            type: 'picto_tap',
            createdAt: DateTime.now(),
            data: {'categoryId': picto.categoryId, 'pictoId': picto.id},
          ),
        ),
  );

  if (ref.read(speakOnTapProvider)) {
    await speakText(context, ref, picto.label);
  }
}

/// Mantener presionado: fija o desfija el picto en el inicio, con aviso.
Future<void> onPictoLongPress(
  BuildContext context,
  WidgetRef ref,
  Pictogram picto,
) async {
  await ref.read(favoritesProvider.notifier).toggle(picto.id);
  if (!context.mounted) return;

  final favorited = ref.read(favoritesProvider).contains(picto.id);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          favorited
              ? 'Pictograma fijado en el inicio'
              : 'Pictograma quitado del inicio',
        ),
      ),
    );
}

/// Tocar un mensaje guardado: recarga sus pictos en la barra de frase.
Future<void> cargarMensaje(
  BuildContext context,
  WidgetRef ref,
  SavedMessage message,
) async {
  final catalog = await ref.read(catalogProvider.future);
  final pictos = [
    for (final id in message.pictoIds) catalog.pictogramById(id),
  ].whereType<Pictogram>().toList();
  ref.read(phraseProvider.notifier).load(pictos);
  ref.read(comunicadorProvider.notifier).goHome();
}
