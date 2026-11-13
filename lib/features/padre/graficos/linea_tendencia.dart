import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'animacion.dart';
import 'linea_pintor.dart';

export 'linea_geometria.dart';

/// Línea suave con área rellena; al tocar un día muestra su valor.
class LineaTendencia extends StatefulWidget {
  const LineaTendencia({
    super.key,
    required this.valores,
    required this.descripcion,
    this.etiquetas = const [],
    this.alto = 160,
  });

  final List<num> valores;
  final List<String> etiquetas;
  final String descripcion;
  final double alto;

  @override
  State<LineaTendencia> createState() => _LineaTendenciaState();
}

class _LineaTendenciaState extends State<LineaTendencia> {
  int? _seleccion;

  void _tocar(Offset punto) {
    final tamano = context.size;
    final n = widget.valores.length;
    if (tamano == null || n == 0) return;
    var indice = (punto.dx / tamano.width * n).floor();
    indice = indice < 0 ? 0 : (indice >= n ? n - 1 : indice);
    setState(() => _seleccion = indice);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.valores.isEmpty) return const SizedBox.shrink();
    final indice = _seleccion ?? widget.valores.length - 1;
    final etiqueta =
        indice < widget.etiquetas.length ? widget.etiquetas[indice] : 'Día ${indice + 1}';
    return Semantics(
      container: true,
      label: widget.descripcion,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$etiqueta: ${widget.valores[indice]}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: widget.alto,
            child: GestureDetector(
              onTapDown: (detalle) => _tocar(detalle.localPosition),
              child: RepaintBoundary(
                child: AnimacionGrafico(
                  builder: (context, t) => CustomPaint(
                    painter: PintorLinea(
                      valores: widget.valores,
                      progreso: t,
                      color: context.colores.primaryStrong,
                      relleno: context.colores.primary.withValues(alpha: 0.18),
                      base: context.colores.borde,
                      seleccion: indice,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
