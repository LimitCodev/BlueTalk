import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';

/// Controlador de ajustes: carga desde `SettingsRepo` y persiste cada cambio.
///
/// Los sliders usan la pareja `preview*` + [guardarCambios]: mientras el
/// dedo se mueve solo cambia el estado en memoria (vista previa) y el JSON
/// se escribe una vez al soltar (PERF-CORE-02 de la auditoría).
class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => ref.read(settingsRepoProvider).load();

  void _preview(AppSettings next) => state = AsyncData(next);

  Future<void> _update(AppSettings next) async {
    // Estado optimista: la UI responde al instante (gama baja).
    _preview(next);
    await guardarCambios();
  }

  /// Escribe en disco el estado actual (una vez por gesto).
  Future<void> guardarCambios() =>
      ref.read(settingsRepoProvider).save(state.requireValue);

  Future<void> setTextScale(double value) =>
      _update(state.requireValue.copyWith(textScale: value));

  Future<void> setTtsRate(double value) =>
      _update(state.requireValue.copyWith(ttsRate: value));

  Future<void> setTtsPitch(double value) =>
      _update(state.requireValue.copyWith(ttsPitch: value));

  Future<void> setRemindersEnabled(bool value) =>
      _update(state.requireValue.copyWith(remindersEnabled: value));

  /// Vista previa del tamaño de letra sin escribir en disco.
  void previewTextScale(double value) =>
      _preview(state.requireValue.copyWith(textScale: value));

  /// Vista previa de la velocidad de voz sin escribir en disco.
  void previewTtsRate(double value) =>
      _preview(state.requireValue.copyWith(ttsRate: value));

  /// Vista previa del tono de voz sin escribir en disco.
  void previewTtsPitch(double value) =>
      _preview(state.requireValue.copyWith(ttsPitch: value));

  /// Tema de color (plan 13 P4): id de `AppColors.temas`. Un id
  /// desconocido (valor corrupto a mano) no se aplica: se conserva el
  /// tema actual (revisión Etapa B, LEVE).
  Future<void> setTema(String id) async {
    if (!AppColors.temas.containsKey(id)) return;
    await _update(state.requireValue.copyWith(tema: id));
  }
}

/// Ajustes actuales de la app (`AsyncData` tras cargar).
final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
