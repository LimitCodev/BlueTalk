import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/calm_mode.dart';
import 'app_avatar.dart';

/// Shell fijo con navegación inferior predecible (plan 01 §4):
/// Comunicar · Aprender · Rutinas · Ajustes.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (label: 'Comunicar', icon: Icons.chat_bubble_outline, selected: Icons.chat_bubble),
    (label: 'Aprender', icon: Icons.menu_book_outlined, selected: Icons.menu_book),
    (label: 'Rutinas', icon: Icons.schedule_outlined, selected: Icons.schedule),
    (label: 'Ajustes', icon: Icons.settings_outlined, selected: Icons.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calm = ref.watch(calmModeProvider);
    final index = shell.currentIndex;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppAvatar(size: 28),
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
    );
  }
}
