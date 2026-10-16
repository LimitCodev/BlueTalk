import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/calm_mode.dart';
import '../../../data/models/models.dart';
import '../../ajustes/settings_controller.dart';
import '../rutinas_providers.dart';
import 'recordatorio_scheduler_real.dart';

/// Sincroniza los recordatorios con el horario y con `remindersEnabled`
/// (plan 1.1): un Notifier escucha ambos cambios y ajusta **solo** lo que
/// cambió (crear/editar → se reprograma esa; quitar → se cancela esa;
/// interruptor apagado → se cancelan todos).
class RecordatoriosController extends Notifier<bool> {
  /// Entradas actualmente programadas (id → entrada) para detectar cambios.
  final Map<String, ScheduleEntry> _programadas = {};

  @override
  bool build() {
    ref.listen(
      horarioProvider,
      (_, next) =>
          next.whenData((entradas) => _seguro(() => _syncHorario(entradas))),
    );
    ref.listen(
      settingsProvider,
      (_, next) =>
          next.whenData((ajustes) => _seguro(() => _syncAjustes(ajustes))),
    );
    ref.listen(calmModeProvider, (_, _) => _seguro(_reprogramarPorCalma));

    // Si los datos ya estaban cargados antes de escuchar, sincroniza ya
    // (idempotente: reprogramar la misma entrada es inofensivo).
    final horario = ref.read(horarioProvider).value;
    final ajustes = ref.read(settingsProvider).value;
    if (ajustes != null) {
      _seguro(() => _syncAjustes(ajustes));
      if (horario != null && ajustes.remindersEnabled) {
        _seguro(() => _syncHorario(horario));
      }
    }
    return ajustes?.remindersEnabled ?? false;
  }

  /// Cancela todos los avisos programados sin tocar nada más.
  ///
  /// Lo usa el borrado total de datos (plan 11 §1.2): tras `prefs.clear()`
  /// no debe quedar ningún aviso del horario anterior.
  Future<void> cancelarTodoProgramado() async {
    await ref.read(recordatorioSchedulerProvider).cancelarTodos();
    _programadas.clear();
  }

  /// Pide el permiso de notificaciones (solo desde Ajustes, plan 1.1).
  /// Sin permiso o con error se devuelve `false`: nada se rompe.
  Future<bool> pedirPermisoNotificaciones() async {
    try {
      return await ref.read(recordatorioSchedulerProvider).pedirPermiso();
    } catch (_) {
      // Plugin no disponible o permiso inaccesible: sin permiso.
      return false;
    }
  }

  Future<void> _syncAjustes(AppSettings ajustes) async {
    final scheduler = ref.read(recordatorioSchedulerProvider);
    state = ajustes.remindersEnabled;
    if (!ajustes.remindersEnabled) {
      // Interruptor apagado: se cancelan todos (plan 1.1).
      await scheduler.cancelarTodos();
      _programadas.clear();
      return;
    }
    final horario = ref.read(horarioProvider).value;
    if (horario != null) await _syncHorario(horario);
  }

  Future<void> _syncHorario(List<ScheduleEntry> entradas) async {
    final ajustes = ref.read(settingsProvider).value;
    if (ajustes == null || !ajustes.remindersEnabled) return;

    final scheduler = ref.read(recordatorioSchedulerProvider);

    // Quitadas del horario: se cancela solo esa.
    for (final id in _programadas.keys.toList(growable: false)) {
      if (!entradas.any((entrada) => entrada.id == id)) {
        await scheduler.cancelar(id);
        _programadas.remove(id);
      }
    }

    // Nuevas o editadas: se reprograma solo esa.
    for (final entrada in entradas) {
      final anterior = _programadas[entrada.id];
      if (anterior == null || !_misma(anterior, entrada)) {
        await scheduler.programar(entrada);
      }
      _programadas[entrada.id] = entrada;
    }
  }

  /// Cambió el modo calma: mismos avisos, otro canal (silencio o normal).
  Future<void> _reprogramarPorCalma() async {
    if (_programadas.isEmpty) return;
    final scheduler = ref.read(recordatorioSchedulerProvider);
    for (final entrada in _programadas.values) {
      await scheduler.programar(entrada);
    }
  }

  /// Un fallo del plugin de avisos nunca debe romper la app: el estado se
  /// recalcula en el siguiente cambio de horario o de ajustes.
  Future<void> _seguro(Future<void> Function() accion) async {
    try {
      await accion();
    } catch (_) {
      // Sin avisos no se rompe nada (plan 1.1).
    }
  }

  bool _misma(ScheduleEntry a, ScheduleEntry b) =>
      a.title == b.title &&
      a.timeMinutes == b.timeMinutes &&
      a.pictoId == b.pictoId &&
      a.enabled == b.enabled;
}

/// Lo escucha la raíz de la app para mantenerse vivo (plan 1.1).
final recordatoriosProvider = NotifierProvider<RecordatoriosController, bool>(
  RecordatoriosController.new,
);

/// ¿Puede la app mostrar avisos? (en Android 13+, `false` sin permiso).
final notificacionesPermitidasProvider = FutureProvider<bool>(
  (ref) => ref.read(recordatorioSchedulerProvider).estaPermitido(),
);
