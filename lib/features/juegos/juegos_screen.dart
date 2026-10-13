import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cabecera_juego.dart';
import '../../core/theme/app_colors.dart';
import 'artista/artista_screen.dart';
import 'avance_juegos.dart';
import 'cuentos/cuentos_screen.dart';
import 'juegos_controller.dart';
import 'memoria/memoria_screen.dart';

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
      JuegoVista.memoria => const _MemoriaView(),
      JuegoVista.cuentos => const CuentosScreen(),
      JuegoVista.artista => const ArtistaScreen(),
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

/// Vista del memoria: cabecera + cuerpo del juego.
class _MemoriaView extends StatelessWidget {
  const _MemoriaView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CabeceraJuego('Memoria'),
        Expanded(child: MemoriaScreen()),
      ],
    );
  }
}
