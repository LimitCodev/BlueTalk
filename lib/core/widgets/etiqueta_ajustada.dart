import 'package:flutter/material.dart';

/// Etiqueta de una línea para fichas estrechas: se reduce antes que cortarse
/// con puntos suspensivos o partirse a mitad de palabra («Preocupado»).
class EtiquetaAjustada extends StatelessWidget {
  const EtiquetaAjustada(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      texto,
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}
