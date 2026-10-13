import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';

/// Filtro de escala de grises: saturación 0 sobre todo el árbol (plan 00 §4).
const ColorFilter calmColorFilter = ColorFilter.mode(
  Color(0xFF000000),
  BlendMode.saturation,
);

/// Controlador del modo calma. Persiste en preferencias locales.
class CalmModeController extends Notifier<bool> {
  static const prefKey = 'bluetalk_calm_mode';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(prefKey) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(prefKey, value);
  }
}

/// Estado del modo calma (grises + animaciones apagadas, persistente).
final calmModeProvider = NotifierProvider<CalmModeController, bool>(
  CalmModeController.new,
);

/// Interruptor reutilizable (≥48dp) para Ajustes y el shell principal.
class CalmModeToggle extends ConsumerWidget {
  const CalmModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(calmModeProvider);

    return SwitchListTile(
      title: const Text('Modo calma'),
      subtitle: const Text('Pantalla en gris y sin animaciones'),
      value: active,
      onChanged: (value) async => ref.read(calmModeProvider.notifier).set(value),
    );
  }
}
