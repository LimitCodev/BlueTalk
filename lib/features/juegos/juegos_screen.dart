import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'avance_juegos.dart';
import 'juegos_controller.dart';

/// Pestaña "Aprender" del shell: juegos y cuentos (plan 03).
///
/// Autocontenido: su navegación (inicio, memoria, cuentos, artista) es
/// interna, sin rutas propias, para no acoplarse al router raíz. El shell
/// pone el Scaffold, el AppBar y la NavigationBar.
class JuegosScreen extends ConsumerWidget {
  const JuegosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(juegosProvider);

    return switch (vista) {
      JuegoVista.inicio => const _HomeView(),
      JuegoVista.memoria => const _Pendiente('Memoria'),
      JuegoVista.cuentos => const _Pendiente('Cuentos'),
      JuegoVista.artista => const _Pendiente('Artista'),
    };
  }
}

/// Inicio: tarjetas de los juegos + avance con barras.
class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: const [
        _JuegoCard(
          vista: JuegoVista.memoria,
          icono: Icons.extension,
          titulo: 'Memoria',
          subtitulo: 'Encuentra las parejas de pictogramas.',
        ),
        _JuegoCard(
          vista: JuegoVista.cuentos,
          icono: Icons.menu_book,
          titulo: 'Cuentos interactivos',
          subtitulo: 'Lee un cuento y toca la imagen que falta.',
        ),
        _JuegoCard(
          vista: JuegoVista.artista,
          icono: Icons.palette,
          titulo: 'Artista',
          subtitulo: 'Dibuja con colores y guarda tus dibujos.',
        ),
        AvanceJuegosSection(),
      ],
    );
  }
}

/// Tarjeta de un juego: targets ≥48dp, literal, sin metáforas.
class _JuegoCard extends ConsumerWidget {
  const _JuegoCard({
    required this.vista,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  final JuegoVista vista;
  final IconData icono;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(juegosProvider.notifier).abrir(vista),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: AppColors.primaryStrong),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vista de un juego aún no entregado (se reemplaza en su commit).
class _Pendiente extends ConsumerWidget {
  const _Pendiente(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Este juego llega en el siguiente paso.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => ref.read(juegosProvider.notifier).irAlInicio(),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Volver'),
          ),
        ],
      ),
    );
  }
}
