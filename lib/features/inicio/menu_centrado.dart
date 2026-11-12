import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'menu_opciones.dart';

/// Botón del menú que está (o debe quedar) en el centro del carrusel.
///
/// Lo cambia el dedo y también la guía de la mascota (plan 14B), que
/// centra la tarjeta que explica. Se reinicia al salir del menú: el menú
/// siempre empieza en Comunicar (plan 14A §2, orden fijo).
class MenuCentrado extends Notifier<int> {
  @override
  int build() => 0;

  void centrar(MenuOpcion opcion) => ir(opcion.index);

  void ir(int indice) => state = indice.clamp(0, MenuOpcion.values.length - 1);
}

final menuCentradoProvider = NotifierProvider.autoDispose<MenuCentrado, int>(
  MenuCentrado.new,
);
