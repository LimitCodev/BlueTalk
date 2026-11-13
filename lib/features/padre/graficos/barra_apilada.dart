import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'animacion.dart';
import 'barra_geometria.dart';
import 'barra_leyenda.dart';

export 'barra_geometria.dart';
export 'barra_leyenda.dart';

/// Barra 100 % apilada con icono y etiqueta por segmento, nunca solo color.
class BarraApilada extends StatelessWidget {
  const BarraApilada({
    super.key,
    required this.segmentos,
    required this.descripcion,
    this.alto = 30,
  });

  final List<SegmentoApilado> segmentos;
  final String descripcion;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final partes = porcentajes([for (final s in segmentos) s.valor]);
    return Semantics(
      container: true,
      label: descripcion,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(alto / 2),
            child: SizedBox(
              height: alto,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: context.colores.borde),
                  ),
                  Positioned.fill(
                    child: AnimacionGrafico(
                      builder: (context, t) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: t,
                          heightFactor: 1,
                          child: Row(
                            children: [
                              for (var i = 0; i < segmentos.length; i++)
                                if (partes[i] > 0)
                                  Expanded(
                                    flex: partes[i],
                                    child: ColoredBox(
                                      color: segmentos[i].color,
                                      child: Center(
                                        child: partes[i] >= 15
                                            ? Icon(
                                                segmentos[i].icono,
                                                size: 16,
                                                color: _tinta(
                                                  segmentos[i].color,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          LeyendaApilada(segmentos: segmentos, partes: partes),
        ],
      ),
    );
  }

  Color _tinta(Color fondo) =>
      ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
          ? Colors.white
          : Colors.black;
}
