import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'animacion.dart';
import 'dona_geometria.dart';
import 'dona_pintor.dart';

export 'dona_geometria.dart';

/// Una porción ya pintada: etiqueta, valor y color del segmento.
typedef SegmentoDona = ({String etiqueta, int valor, Color color});

/// Dona con el total —o el segmento tocado— en el centro.
class Dona extends StatefulWidget {
  const Dona({
    super.key,
    required this.porciones,
    required this.descripcion,
    this.tituloCentro = 'Total',
    this.alto = 190,
  });

  final List<SegmentoDona> porciones;
  final String descripcion;
  final String tituloCentro;
  final double alto;

  @override
  State<Dona> createState() => _DonaState();
}

class _DonaState extends State<Dona> {
  int? _seleccion;

  void _tocar(Offset punto) {
    final tamano = context.size;
    if (tamano == null) return;
    final indice = indiceDona(punto, tamano, [for (final p in widget.porciones) p.valor]);
    if (indice != null) setState(() => _seleccion = indice);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.porciones.fold<int>(0, (s, p) => s + p.valor);
    final elegida = _seleccion == null ? null : widget.porciones[_seleccion!];
    final estilo = Theme.of(context).textTheme;
    final angulos = angulosDona([for (final p in widget.porciones) p.valor]);
    return Semantics(
      container: true,
      label: widget.descripcion,
      excludeSemantics: true,
      child: SizedBox(
        height: widget.alto,
        child: GestureDetector(
          onTapDown: (detalle) => _tocar(detalle.localPosition),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimacionGrafico(
                    builder: (context, avance) => CustomPaint(
                      painter: PintorDona(
                        angulos: angulos,
                        colores: [for (final p in widget.porciones) p.color],
                        base: context.colores.borde,
                        progreso: avance,
                        seleccion: _seleccion,
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      elegida?.etiqueta ?? widget.tituloCentro,
                      style: estilo.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${elegida?.valor ?? total}',
                      style: estilo.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.colores.primaryStrongText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
