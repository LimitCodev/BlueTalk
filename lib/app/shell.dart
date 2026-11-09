import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/calm_mode.dart';
import '../core/widgets/logo_bluetalk.dart';
import 'atras_shell.dart';

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
        if (!didPop) manejarAtras(ref, shell);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LogoBluetalkWordmark(height: 23, pill: true),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _tabs[index].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
