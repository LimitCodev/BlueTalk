import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'menu_opciones.dart';

/// Tarjeta del menú principal, como la de `/menu` de la web.
///
/// [distancia] va de 0 (centrada) a 1 (vecina): encoge y se atenúa
/// mientras el dedo desliza el carrusel.
class MenuTarjeta extends StatelessWidget {
  const MenuTarjeta({
    super.key,
    required this.opcion,
    required this.onTap,
    this.distancia = 0,
  });

  final MenuOpcion opcion;
  final VoidCallback onTap;
  final double distancia;

  @override
  Widget build(BuildContext context) {
    final paleta = context.colores;
    final cat = coloresCategorias[opcion.categoria]!;
    final tinta = cat.texto(paleta);
    final t = distancia.clamp(0.0, 1.0);
    final texto = Theme.of(context).textTheme;
    return Transform.scale(
      scale: 1 - 0.1 * t,
      child: Opacity(
        opacity: 1 - 0.6 * t,
        child: Semantics(
          button: true,
          label: '${opcion.titulo}. ${opcion.descripcion}',
          excludeSemantics: true,
          child: Material(
            color: cat.relleno(paleta),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cat.bordeSobre(paleta), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: tinta.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(opcion.icono, size: 36, color: tinta),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opcion.titulo,
                            style: texto.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: tinta,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(opcion.descripcion, style: texto.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
