import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `directa` es el APK fuera de Play, con filtro VPN y acceso al uso. Sin
/// sabor o con `play` se aplica la ruta A de requisitosPlayStore.md.
const edicionDirecta = appFlavor == 'directa';

final edicionDirectaProvider = Provider<bool>((ref) => edicionDirecta);

final _lineaDeFiltro = RegExp(
  r'VPN|filtro de páginas|pantalla del filtro',
  caseSensitive: false,
);
final _fraseDeFiltro = RegExp(r' *[^.\n]*filtro[^.\n]*\.');

/// Texto legal de Play: sin los párrafos del filtro, que allí no existe.
String lineasDeEdicion(String texto) => edicionDirecta
    ? texto
    : quitarLineasDeFiltro(texto);

String quitarLineasDeFiltro(String texto) => texto
    .split('\n')
    .where((linea) => !_lineaDeFiltro.hasMatch(linea))
    .map(quitarFrasesDeFiltro)
    .join('\n');

/// Quita de una explicación las frases que hablan del filtro.
String quitarFrasesDeFiltro(String texto) =>
    texto.replaceAll(_fraseDeFiltro, '');
