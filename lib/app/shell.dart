import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/calm_mode.dart';
import '../core/widgets/logo_bluetalk.dart';
import '../features/juegos/juegos_controller.dart';

/// Si el botón Atrás puede salir de la app desde Comunicar (fila 3 del
/// plan 13 P1).
///
/// `true` por defecto. El plan 12 (modo niño/kiosko) lo pondrá en `false`
/// para que el niño no pueda salir de BlueTalk con el botón Atrás
/// (plan 13 P1, gancho «saleConAtras»).
final saleConAtrasProvider = Provider<bool>((ref) => true);

/// Shell fijo con navegación inferior predecible (plan 01 §4):
/// Comunicar · Aprender · Rutinas · Ajustes.
///
/// Centraliza el botón Atrás (plan 13 P1): dentro de la app el Atrás
/// siempre se mueve a un sitio de la tabla del plan, nunca se queda quieto
/// ni mata la app donde no toca. El único punto de salida es Comunicar
/// (con el gancho `saleConAtrasProvider` para el kiosko del plan 12).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (
      label: 'Comunicar',
      icon: Icons.chat_bubble_outline,
      selected: Icons.chat_bubble,
    ),
    (
      label: 'Aprender',
      icon: Icons.menu_book_outlined,
      selected: Icons.menu_book,
    ),
    (label: 'Rutinas', icon: Icons.schedule_outlined, selected: Icons.schedule),
    (label: 'Ajustes', icon: Icons.settings_outlined, selected: Icons.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calm = ref.watch(calmModeProvider);
    final index = shell.currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Fila 1: dentro de un juego, el Atrás vuelve a la lista de Aprender
        // (y cierra la sesión de juego con su duración, plan 03 §6).
        if (index == 1 && ref.read(juegosProvider) != JuegoVista.inicio) {
          ref.read(juegosProvider.notifier).irAlInicio();
          return;
        }
        // Fila 2: de Aprender, Rutinas o Ajustes, el Atrás va a Comunicar.
        if (index != 0) {
          shell.goBranch(0);
          return;
        }
        // Fila 3: en Comunicar el Atrás sale de la app… salvo en kiosko.
        if (ref.read(saleConAtrasProvider)) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LogoBluetalk(size: 28),
              const SizedBox(width: 10),
              Text(_tabs[index].label),
            ],
          ),
          actions: [
            // Botón de modo calma visible siempre en el shell (plan 01 §3).
            IconButton(
              icon: const Icon(Icons.contrast),
              tooltip: 'Modo calma',
              onPressed: () => ref.read(calmModeProvider.notifier).set(!calm),
            ),
          ],
        ),
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: shell.goBranch,
          destinations: [
            for (final tab in _tabs)
              NavigationDestination(
                label: tab.label,
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selected),
              ),
          ],
        ),
      ),
    );
  }
}
