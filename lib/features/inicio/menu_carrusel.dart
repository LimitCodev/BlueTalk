import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'menu_centrado.dart';
import 'menu_geometria.dart';
import 'menu_indicadores.dart';
import 'menu_opciones.dart';
import 'menu_pagina.dart';

/// Carrusel vertical del menú (plan 14A §A2): la tarjeta del centro a
/// tamaño completo y las vecinas más pequeñas y tenues, siguiendo al dedo.
class MenuCarrusel extends ConsumerStatefulWidget {
  const MenuCarrusel({super.key});

  @override
  ConsumerState<MenuCarrusel> createState() => _MenuCarruselState();
}

class _MenuCarruselState extends ConsumerState<MenuCarrusel> {
  final _controlador = MenuPaginaController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _moverA(int indice) {
    final pagina = _controlador.paginaOpcional;
    if (pagina == null || !pagina.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      pagina.jumpToPage(indice);
    } else {
      pagina.animateToPage(
        indice,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // La guía (o las flechas) piden un centro: el carrusel se desliza ahí.
    ref.listen(menuCentradoProvider, (_, indice) {
      final pagina = _controlador.paginaOpcional;
      if (pagina != null &&
          pagina.hasClients &&
          pagina.page?.round() != indice) {
        _moverA(indice);
      }
    });
    final centro = ref.watch(menuCentradoProvider);
    final opciones = MenuOpcion.values;
    return MenuIndicadores(
      actual: centro,
      onIr: ref.read(menuCentradoProvider.notifier).ir,
      child: LayoutBuilder(
        builder: (context, caja) {
          final pagina = _controlador.sincronizar(
            MenuGeometria.fraccion(context, caja.maxHeight),
            centro,
          );
          return PageView.builder(
            controller: pagina,
            scrollDirection: Axis.vertical,
            itemCount: opciones.length,
            onPageChanged: ref.read(menuCentradoProvider.notifier).ir,
            itemBuilder: (context, i) =>
                MenuPagina(indice: i, opciones: opciones, pagina: pagina),
          );
        },
      ),
    );
  }
}
