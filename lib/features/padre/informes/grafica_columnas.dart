import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../graficos/animacion.dart';
import 'grafica_columnas_pintor.dart';

/// Columnas por día, dibujadas en Flutter (sin librería de gráficas).
///
/// La entrada crece desde abajo y se apaga con el Modo calma. Un valor `null`
/// es «sin datos» y no se dibuja como cero. Al tocar una columna se muestra
/// su día y su valor. El lector de pantalla recibe [descripcion].
class GraficaColumnas extends StatefulWidget {
  const GraficaColumnas({
    super.key,
    required this.valores,
    required this.descripcion,
    this.alto = 120,
    this.etiquetas = const [],
    this.resaltado,
    this.unidad,
  });

  final List<int?> valores;
  final String descripcion;
  final double alto;
  final List<String> etiquetas;
  final int? resaltado;
  final String? unidad;

  @override
  State<GraficaColumnas> createState() => _GraficaColumnasState();
}

class _GraficaColumnasState extends State<GraficaColumnas> {
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
    final indice =
        _seleccion ?? widget.resaltado ?? widget.valores.length - 1;
    final etiqueta =
        indice < widget.etiquetas.length ? widget.etiquetas[indice] : 'Día ${indice + 1}';
    final valor = widget.valores[indice];
    final detalle = valor == null
        ? 'sin datos'
        : '$valor${widget.unidad == null ? '' : ' ${widget.unidad}'}';
    final colores = context.colores;
    return Semantics(
      container: true,
      label: widget.descripcion,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$etiqueta: $detalle',
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
                    painter: PintorColumnas(
                      valores: widget.valores,
                      normal: colores.primary,
                      destacado: colores.primaryStrong,
                      base: colores.borde,
                      progreso: t,
                      resaltado: widget.resaltado,
                      seleccion: _seleccion,
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
