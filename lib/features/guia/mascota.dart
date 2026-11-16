import 'package:flutter/material.dart';

/// Posturas del ave de BlueTalk (plan 14B §2). Ninguna se voltea: todas
/// llevan texto («BlueTalk», «SECURE») que se leería en espejo.
enum PosturaAve {
  saludaTablero('ave_saluda_tablero'),
  brazosAbiertos('ave_brazos_abiertos'),
  manosJuntas('ave_manos_juntas'),
  volando('ave_volando'),
  alasAbiertas('ave_alas_abiertas'),
  perfil('ave_perfil'),
  bandera('ave_bandera'),
  pulgar('ave_pulgar'),
  pensando('ave_pensando'),
  candado('ave_candado'),
  candadoSenala('ave_candado_senala');

  const PosturaAve(this.archivo);
  final String archivo;
  String get asset => 'assets/mascota/$archivo.png';
}

/// El ave de BlueTalk (plan 14B §2). Sin volteo; decorativa para TalkBack
/// (el globo ya dice todo). Entra con un salto suave salvo en modo calma.
class Ave extends StatelessWidget {
  const Ave({super.key, required this.postura, this.tamano = 120});

  final PosturaAve postura;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final imagen = Image.asset(
      postura.asset,
      width: tamano,
      height: tamano,
      // Los PNG miden 479 px: decodificar a menos ahorra RAM en gama baja.
      cacheWidth: 300,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
    if (MediaQuery.disableAnimationsOf(context)) return imagen;
    return TweenAnimationBuilder<double>(
      key: ValueKey(postura),
      tween: Tween(begin: 0.8, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      builder: (context, escala, hijo) =>
          Transform.scale(scale: escala, child: hijo),
      child: imagen,
    );
  }
}
