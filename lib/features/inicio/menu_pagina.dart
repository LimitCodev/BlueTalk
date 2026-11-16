import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'menu_centrado.dart';
import 'menu_entrada.dart';
import 'menu_opciones.dart';
import 'menu_tarjeta.dart';

/// Una tarjeta del carrusel del menú.
///
/// Sigue al dedo con la misma animación que el resto (escala y opacidad
/// según la distancia al centro) y se encoge entera si la pantalla es muy
/// baja, por ejemplo en horizontal o con el texto del sistema al máximo.
class MenuPagina extends ConsumerWidget {
  const MenuPagina({
    super.key,
    required this.indice,
    required this.opciones,
    required this.pagina,
  });

  final int indice;
  final List<MenuOpcion> opciones;
  final PageController pagina;

  double _posicion(WidgetRef ref) {
    if (!pagina.hasClients) return ref.read(menuCentradoProvider).toDouble();
    return pagina.position.haveDimensions
        ? pagina.page ?? 0
        : ref.read(menuCentradoProvider).toDouble();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: pagina,
      builder: (context, _) => LayoutBuilder(
        builder: (context, caja) => FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: caja.maxWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: MenuEntrada(
                orden: indice,
                child: MenuTarjeta(
                  opcion: opciones[indice],
                  distancia: (_posicion(ref) - indice).abs(),
                  onTap: () => indice == ref.read(menuCentradoProvider)
                      ? context.go(opciones[indice].ruta)
                      : ref.read(menuCentradoProvider.notifier).ir(indice),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
