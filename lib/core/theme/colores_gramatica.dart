import 'app_colors.dart';

/// Tono de cada clase gramatical del tablero nuclear (Fitzgerald
/// modificado). Reutiliza tonos ya validados en AA; la etiqueta siempre
/// está visible, así que el color nunca es la única pista.
ColoresCategoria? coloresDeClase(String? clase) => coloresCategorias[switch (clase) {
  'verbo' => 'acciones',
  'pronombre' => 'animales',
  'descriptor' => 'clima',
  'social' => 'emociones',
  'lugar' => 'personas',
  'pregunta' => 'familia',
  _ => '',
}];
