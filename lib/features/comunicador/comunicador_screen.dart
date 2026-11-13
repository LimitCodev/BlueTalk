import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guia/guia_objetivos.dart';
import '../guia/guia_pasos.dart';
import 'comunicador_controller.dart';
import 'phrase_bar.dart';
import 'comunicador_categoria_view.dart';
import 'comunicador_encabezados.dart';
import 'comunicador_inicio_view.dart';
import 'comunicador_mensajes_view.dart';

/// Comunicador AAC (plan 02): categorías, pictogramas offline, barra de
/// frase y voz. Cuerpo de la pestaña "Comunicar" del shell.
///
/// Autocontenido: su navegación (inicio, categoría, mis mensajes) es
/// interna, sin rutas propias, para no acoplarse al router raíz.
class ComunicadorScreen extends ConsumerWidget {
  const ComunicadorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(comunicadorProvider);
    final categoryId = view.categoryId;

    return Column(
      children: [
        if (categoryId != null)
          CategoryHeader(categoryId: categoryId)
        else if (view.showMessages)
          const MessagesHeader(),
        Expanded(
          child: categoryId != null
              ? CategoryView(categoryId: categoryId)
              : view.showMessages
              ? const MessagesView()
              : const HomeView(),
        ),
        const GuiaAncla(objetivo: GuiaObjetivo.fraseBarra, child: PhraseBar()),
      ],
    );
  }
}
