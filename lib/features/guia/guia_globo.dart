import 'package:flutter/material.dart';

import 'guia_botones.dart';
import 'guia_lista.dart';
import 'guia_pasos.dart';
import 'mascota.dart';

/// Globo de texto de la guía con la mascota y sus botones (plan 14B §1).
class GuiaGlobo extends StatelessWidget {
  const GuiaGlobo({
    super.key,
    required this.paso,
    required this.numero,
    required this.texto,
    required this.onAtras,
    required this.onSiguiente,
    required this.onSaltar,
    this.confirmarSalto = false,
    this.onCancelarSalto,
  });

  final GuiaPaso paso;
  final int numero;
  final String texto;
  final VoidCallback? onAtras;
  final VoidCallback onSiguiente;
  final VoidCallback onSaltar;
  final bool confirmarSalto;
  final VoidCallback? onCancelarSalto;

  bool get _ultimo => numero == pasosGuia.length;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estilo = tema.textTheme.titleMedium?.copyWith(fontSize: 18);
    final ancho = MediaQuery.sizeOf(context).width;
    final mensaje = confirmarSalto
        ? Text(
            '¿Saltar la guía? Te llevamos al Modo padre para crear tu '
            'código.',
            style: estilo,
          )
        : Text.rich(
            TextSpan(
              style: estilo,
              children: [
                if (paso.titulo case final t?)
                  TextSpan(
                    text: '$t: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                TextSpan(text: texto),
              ],
            ),
          );
    return Semantics(
      container: true,
      liveRegion: true,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GuiaCabecera(
                numero: numero,
                conSaltar: !confirmarSalto && !_ultimo,
                onSaltar: onSaltar,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Ave(
                    postura: confirmarSalto ? PosturaAve.candado : paso.postura,
                    tamano: ancho < 360 ? 84 : 108,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: mensaje),
                ],
              ),
              const SizedBox(height: 8),
              GuiaBotones(
                ultimo: _ultimo,
                confirmarSalto: confirmarSalto,
                onAtras: onAtras,
                onSiguiente: onSiguiente,
                onSaltar: onSaltar,
                onCancelarSalto: onCancelarSalto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
