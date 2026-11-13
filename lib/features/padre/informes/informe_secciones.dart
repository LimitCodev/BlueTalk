import 'package:flutter/material.dart';

import 'informe_modelo.dart';
import 'informe_texto.dart';
import 'lista_ranking.dart';

class CabeceraInforme extends StatelessWidget {
  const CabeceraInforme({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        'Del ${fechaLarga(informe.desde)} al ${fechaLarga(informe.hasta)}',
      ),
      subtitle: const Text('Orientativo. No es un diagnóstico.'),
    );
  }
}

/// Ranking de pictogramas con barra proporcional.
class SeccionPalabras extends StatelessWidget {
  const SeccionPalabras({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListaRanking(
        titulo: 'Palabras más usadas',
        ranking: informe.pictos,
      ),
    );
  }
}
