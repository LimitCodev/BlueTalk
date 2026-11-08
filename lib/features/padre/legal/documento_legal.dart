import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'textos_legales.dart';

/// Documento completo: secciones y párrafos, con scroll (lazy).
class DocumentoLegal extends StatelessWidget {
  const DocumentoLegal({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final lineas = parsearLineas(texto);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final linea in lineas)
            if (linea.tipo == LineaLegalTipo.encabezado)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Text(
                  linea.texto,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: context.colores.primaryStrongText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (linea.tipo == LineaLegalTipo.vineta)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('• ${linea.texto}'),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(linea.texto),
              ),
        ],
      ),
    );
  }
}

/// Lectura libre (sin PIN ni aceptación) desde Ajustes: Play exige que la
/// política de privacidad se pueda leer dentro de la app.
class LecturaLegalScreen extends StatelessWidget {
  const LecturaLegalScreen({
    super.key,
    required this.titulo,
    required this.texto,
  });

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: DocumentoLegal(texto: texto),
      ),
    );
  }
}
