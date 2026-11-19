import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/calm_mode.dart';
import '../features/ajustes/settings_controller.dart';
import '../features/guia/guia_capa.dart';
import '../features/rutinas/recordatorios/recordatorios_controller.dart';
import 'di.dart';
import 'router.dart';

/// Tema ya construido por id de paleta. Evita regenerar el `ThemeData`
/// (y con él todo `MaterialApp`) en cada cambio de ajustes.
final _temaProvider = Provider.family<ThemeData, String>(
  (ref, id) => buildBlueTalkTheme(AppColors.temas[id] ?? AppColors.celeste),
);

/// Raíz de la app: tema celeste pastel + router + interruptor global de calma.
class BlueTalkApp extends ConsumerStatefulWidget {
  const BlueTalkApp({super.key});

  @override
  ConsumerState<BlueTalkApp> createState() => _BlueTalkAppState();
}

class _BlueTalkAppState extends ConsumerState<BlueTalkApp> {
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
    // Al salir a segundo plano se vacían las colas de métricas: como mucho
    // se pierde la ráfaga de los últimos 2 s (PERF-CORE-01).
    _ciclo = AppLifecycleListener(onPause: _volcar, onDetach: _volcar);
  }

  void _volcar() {
    unawaited(ref.read(prefsUsageRepoProvider).flush());
    unawaited(ref.read(resumenesRepoProvider).flush());
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mantiene vivo el sincronizador de recordatorios (plan 1.1).
    ref.listen(recordatoriosProvider, (_, _) {});

    final calm = ref.watch(calmModeProvider);
    // `select` aísla lo que de verdad pinta la raíz: mover la velocidad o
    // el tono de la voz ya no reconstruye `MaterialApp.router` entero.
    final appScale = ref.watch(
      settingsProvider.select((s) => s.value?.textScale ?? 1.0),
    );
    final tema = ref.watch(
      settingsProvider.select((s) => s.value?.tema ?? 'celeste'),
    );

    return MaterialApp.router(
      title: 'BlueTalk',
      theme: ref.watch(_temaProvider(tema)),
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
          // La guía de la mascota va encima de toda la app (plan 14B).
          child: GuiaCapa(child: child ?? const SizedBox.shrink()),
        );
        return calm
            ? ColorFiltered(colorFilter: calmColorFilter, child: tree)
            : tree;
      },
    );
  }
}
