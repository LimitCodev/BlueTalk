import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guia/guia_controller.dart';
import '../guia/guia_lista.dart';
import 'menu_opciones.dart';

/// Botón del menú que está (o debe quedar) en el centro del carrusel.
///
/// Lo cambia el dedo y también la guía de la mascota (plan 14B), que
/// centra la tarjeta que explica. Se reinicia al salir del menú: el menú
/// siempre empieza en Comunicar (plan 14A §2, orden fijo).
class MenuCentrado extends Notifier<int> {
  /// Empieza en Comunicar, o en la tarjeta que explica la guía.
  @override
  int build() {
    final paso = ref.read(guiaProvider);
    return paso == null ? 0 : pasosGuia[paso].tarjeta?.index ?? 0;
  }

  void centrar(MenuOpcion opcion) => ir(opcion.index);

  void ir(int indice) => state = indice.clamp(0, MenuOpcion.values.length - 1);
}

final menuCentradoProvider = NotifierProvider.autoDispose<MenuCentrado, int>(
  MenuCentrado.new,
);
