import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'menu_opciones.dart';
import 'menu_tarjeta.dart';

/// Menú como lista simple: con TalkBack (plan 14A §A2) cada botón se
/// recorre en orden sin carrusel.
class InicioLista extends StatelessWidget {
  const InicioLista({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final opcion in MenuOpcion.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MenuTarjeta(
              opcion: opcion,
              onTap: () => context.go(opcion.ruta),
            ),
          ),
      ],
    );
  }
}
