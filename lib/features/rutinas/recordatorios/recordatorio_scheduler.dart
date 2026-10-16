import '../../../data/models/models.dart';

/// Interfaz de los recordatorios locales de rutina (plan 1.1).
///
/// Pantallas y controladores solo ven esta interfaz:
/// `flutter_local_notifications` no se importa fuera de la implementación.
abstract interface class RecordatorioScheduler {
  /// Programa (o reprograma) el recordatorio diario de una actividad.
  Future<void> programar(ScheduleEntry entrada);

  /// Cancela el recordatorio de una actividad por su id.
  Future<void> cancelar(String entryId);

  /// Cancela todos los recordatorios programados.
  Future<void> cancelarTodos();

  /// Pide el permiso de notificaciones con el diálogo del sistema.
  /// `true` si queda concedido (en Android anterior a 13 es automático).
  Future<bool> pedirPermiso();

  /// ¿Puede la app mostrar avisos ahora mismo?
  Future<bool> estaPermitido();
}

/// Id estable de notificación derivado del id de la actividad
/// (`entry.id.hashCode & 0x7fffffff`, plan 1.1).
int idNotificacion(String entryId) => entryId.hashCode & 0x7fffffff;

/// Texto literal del aviso (plan 1.1): sin emojis ni sonidos estridentes.
String textoRecordatorio(ScheduleEntry entrada) =>
    'Es hora de: ${entrada.title}.';
