import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'menu_centrado.dart';
import 'menu_entrada.dart';
import 'menu_indicadores.dart';
import 'menu_opciones.dart';
import 'menu_tarjeta.dart';

/// Carrusel vertical del menú (plan 14A §A2): la tarjeta del centro a
/// tamaño completo y las vecinas más pequeñas y tenues, siguiendo al dedo.
class MenuCarrusel extends ConsumerStatefulWidget {
  const MenuCarrusel({super.key});

  @override
  ConsumerState<MenuCarrusel> createState() => _MenuCarruselState();
}

class _MenuCarruselState extends ConsumerState<MenuCarrusel> {
  final _pagina = PageController(viewportFraction: 0.38);

  @override
  void dispose() {
    _pagina.dispose();
    super.dispose();
  }

  void _moverA(int indice) {
    if (!_pagina.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pagina.jumpToPage(indice);
    } else {
      _pagina.animateToPage(
        indice,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  double _posicion() => _pagina.hasClients && _pagina.position.haveDimensions
      ? _pagina.page ?? 0
      : ref.read(menuCentradoProvider).toDouble();

  @override
  Widget build(BuildContext context) {
    // La guía (o las flechas) piden un centro: el carrusel se desliza ahí.
    ref.listen(menuCentradoProvider, (_, indice) {
      if (_pagina.hasClients && _pagina.page?.round() != indice) {
        _moverA(indice);
      }
    });
    final centro = ref.watch(menuCentradoProvider);
    final opciones = MenuOpcion.values;
    return MenuIndicadores(
      actual: centro,
      onIr: ref.read(menuCentradoProvider.notifier).ir,
      child: PageView.builder(
        controller: _pagina,
        scrollDirection: Axis.vertical,
        itemCount: opciones.length,
        onPageChanged: ref.read(menuCentradoProvider.notifier).ir,
        itemBuilder: (context, i) => AnimatedBuilder(
          animation: _pagina,
          // Pantallas bajas (horizontal, teclado): la tarjeta se encoge
          // entera en vez de desbordar.
          builder: (context, _) => LayoutBuilder(
            builder: (context, caja) => FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: caja.maxWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: MenuEntrada(
                    orden: i,
                    child: MenuTarjeta(
                      opcion: opciones[i],
                      distancia: (_posicion() - i).abs(),
                      onTap: () => i == ref.read(menuCentradoProvider)
                          ? context.go(opciones[i].ruta)
                          : ref.read(menuCentradoProvider.notifier).ir(i),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
