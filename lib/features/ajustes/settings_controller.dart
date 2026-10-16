import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../data/models/models.dart';

/// Controlador de ajustes: carga desde `SettingsRepo` y persiste cada cambio.
class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => ref.read(settingsRepoProvider).load();

  Future<void> _update(AppSettings next) async {
    // Estado optimista: la UI responde al instante (gama baja).
    state = AsyncData(next);
    await ref.read(settingsRepoProvider).save(next);
  }

  Future<void> setTextScale(double value) =>
      _update(state.requireValue.copyWith(textScale: value));

  Future<void> setTtsRate(double value) =>
      _update(state.requireValue.copyWith(ttsRate: value));

  Future<void> setTtsPitch(double value) =>
      _update(state.requireValue.copyWith(ttsPitch: value));

  Future<void> setRemindersEnabled(bool value) =>
      _update(state.requireValue.copyWith(remindersEnabled: value));

  /// Tema de color (plan 13 P4): id de `AppColors.temas`.
  Future<void> setTema(String id) =>
      _update(state.requireValue.copyWith(tema: id));
}

/// Ajustes actuales de la app (`AsyncData` tras cargar).
final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
