import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/calm_mode.dart';
import '../features/ajustes/settings_controller.dart';
import 'router.dart';

/// Raíz de la app: tema celeste pastel + router + interruptor global de calma.
class BlueTalkApp extends ConsumerWidget {
  const BlueTalkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calm = ref.watch(calmModeProvider);
    final appScale =
        ref.watch(settingsProvider).value?.textScale ?? 1.0;

    return MaterialApp.router(
      title: 'BlueTalk',
      theme: buildBlueTalkTheme(),
      routerConfig: ref.read(routerProvider),
      // Toda la UI pasa por aquí: animaciones apagadas + grises en modo calma.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final Widget tree = MediaQuery(
          data: media.copyWith(
            disableAnimations: media.disableAnimations || calm,
            // Tamaño de texto de la app multiplicando el del sistema.
            textScaler: TextScaler.linear(
              media.textScaler.scale(1.0) * appScale,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
        return calm
            ? ColorFiltered(colorFilter: calmColorFilter, child: tree)
            : tree;
      },
    );
  }
}
