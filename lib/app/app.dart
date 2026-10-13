import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/calm_mode.dart';

/// Raíz de la app: tema celeste pastel + interruptor global del modo calma.
class BlueTalkApp extends ConsumerWidget {
  const BlueTalkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calm = ref.watch(calmModeProvider);

    return MaterialApp(
      title: 'BlueTalk',
      theme: buildBlueTalkTheme(),
      // Toda la UI pasa por aquí: animaciones apagadas + grises en modo calma.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final Widget tree = MediaQuery(
          data: media.copyWith(
            disableAnimations: media.disableAnimations || calm,
          ),
          child: child ?? const SizedBox.shrink(),
        );
        return calm
            ? ColorFiltered(colorFilter: calmColorFilter, child: tree)
            : tree;
      },
      home: const Scaffold(
        body: Center(
          child: Text('BlueTalk'),
        ),
      ),
    );
  }
}
