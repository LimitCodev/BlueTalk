import '../inicio/menu_opciones.dart';
import 'mascota.dart';

/// Partes de la app que la guía ilumina.
enum GuiaObjetivo {
  menuCarrusel,
  tarjetaComunicar,
  tarjetaAprender,
  tarjetaRutinas,
  tarjetaAjustes,
  tarjetaPadre,
  fraseBarra,
  tableroNuclear,
  categorias,
  barraSuperior,
}

class GuiaPaso {
  const GuiaPaso({
    required this.ruta,
    required this.postura,
    required this.texto,
    this.titulo,
    this.objetivo,
    this.tarjeta,
  });

  final String ruta;
  final PosturaAve postura;

  /// Nombre de la sección en negrita antes del [texto] (puede faltar).
  final String? titulo;
  final String texto;
  final GuiaObjetivo? objetivo;

  /// Tarjeta del menú que se centra antes de iluminarla.
  final MenuOpcion? tarjeta;
}

/// Objetivo de cada tarjeta del menú (una clave por tarjeta).
GuiaObjetivo objetivoTarjeta(MenuOpcion opcion) => switch (opcion) {
  MenuOpcion.comunicar => GuiaObjetivo.tarjetaComunicar,
  MenuOpcion.aprender => GuiaObjetivo.tarjetaAprender,
  MenuOpcion.rutinas => GuiaObjetivo.tarjetaRutinas,
  MenuOpcion.ajustes => GuiaObjetivo.tarjetaAjustes,
  MenuOpcion.padre => GuiaObjetivo.tarjetaPadre,
};
