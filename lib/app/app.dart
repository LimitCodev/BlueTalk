import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/calm_mode.dart';
import '../features/ajustes/settings_controller.dart';
import '../features/rutinas/recordatorios/recordatorios_controller.dart';
import 'router.dart';

/// Raíz de la app: tema celeste pastel + router + interruptor global de calma.
class BlueTalkApp extends ConsumerWidget {
  const BlueTalkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mantiene vivo el sincronizador de recordatorios (plan 1.1).
    ref.listen(recordatoriosProvider, (_, _) {});

    final calm = ref.watch(calmModeProvider);
    final ajustes = ref.watch(settingsProvider).value;
    final appScale = ajustes?.textScale ?? 1.0;
    // Tema de color elegido en Ajustes (plan 13 P4): cambiarlo refresca
    // toda la app al instante (vista previa en vivo).
    final paleta =
        AppColors.temas[ajustes?.tema ?? 'celeste'] ?? AppColors.celeste;

    return MaterialApp.router(
      title: 'BlueTalk',
      theme: buildBlueTalkTheme(paleta),
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
