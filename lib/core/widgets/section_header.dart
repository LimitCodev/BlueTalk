import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Encabezado de sección compartido por todas las pantallas.
///
/// Usa [context.colores.primaryStrongText]: los encabezados son texto y necesitan
/// ≥4.5:1 sobre el fondo (el pastel [context.colores.primary] solo da 1.74:1).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colores.primaryStrongText,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
