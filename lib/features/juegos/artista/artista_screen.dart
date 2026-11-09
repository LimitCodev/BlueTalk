import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cabecera_juego.dart';
import 'artista_barra.dart';
import 'artista_lienzo.dart';

/// Artista (plan 03 §4): lienzo con pinceles pastel, grosor, goma,
/// deshacer y galería local de dibujos guardados.
class ArtistaScreen extends ConsumerWidget {
  const ArtistaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [
        CabeceraJuego('Artista'),
        BarraHerramientas(),
        // El lienzo ocupa todo el alto libre: no hay nada que desplazar,
        // así un arrastre vertical nunca compite con un scroll (plan 13 P2).
        Expanded(child: Lienzo()),
      ],
    );
  }
}
