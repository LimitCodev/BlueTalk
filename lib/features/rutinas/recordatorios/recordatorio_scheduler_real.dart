import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/theme/calm_mode.dart';
import '../../../data/models/models.dart';
import 'recordatorio_scheduler.dart';

const _canalRutinas = 'bluetalk_recordatorios';
const _canalCalma = 'bluetalk_recordatorios_calma';

/// Próxima ocurrencia de [timeMinutes] (horas/minutos desde medianoche) en
/// la zona horaria local: hoy si aún no pasó esa hora, mañana si ya pasó.
tz.TZDateTime proximaOcurrencia(int timeMinutes, {tz.TZDateTime? ahora}) {
  final desde = ahora ?? tz.TZDateTime.now(tz.local);
  final hora = timeMinutes ~/ 60;
  final minuto = timeMinutes % 60;
  var fecha = tz.TZDateTime(
    tz.local,
    desde.year,
    desde.month,
    desde.day,
    hora,
    minuto,
  );
  if (!fecha.isAfter(desde)) {
    fecha = tz.TZDateTime(
      tz.local,
      desde.year,
      desde.month,
      desde.day + 1,
      hora,
      minuto,
    );
  }
  return fecha;
}

/// Implementación real con `flutter_local_notifications` (plan 1.1).
///
/// Programa con horarios **inexactos** (`inexactAllowWhileIdle`): Play
/// restringe las alarmas exactas a apps de alarma/calendario, y un
/// recordatorio con unos minutos de tolerancia es aceptable.
class RecordatorioSchedulerReal implements RecordatorioScheduler {
  RecordatorioSchedulerReal({
    FlutterLocalNotificationsPlugin? plugin,
    required this.enCalma,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Estado actual del modo calma: decide el canal (con o sin sonido).
  final bool Function() enCalma;

  static Future<void>? _iniciando;

  /// Zona horaria, canales e inicialización: una sola vez, perezoso.
  /// Si falla (plugin no disponible), se limpia para reintentar luego.
  Future<void> _asegurar() {
    final enCurso = _iniciando ??= _inicializar(_plugin);
    return enCurso.catchError((Object _) {
      _iniciando = null;
    });
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  static Future<void> _inicializar(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    tzdata.initializeTimeZones();
    try {
      final zona = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zona.identifier));
    } catch (_) {
      // Sin zona del sistema (prácticamente imposible en Android):
      // tz.local queda en UTC y los avisos se calcularían en UTC.
    }
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    final android =
        plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // Canal normal: sonido de sistema (nunca estridente) y vibración.
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _canalRutinas,
          'Recordatorios de rutina',
          description: 'Avisa cada día de la próxima actividad del niño.',
          importance: Importance.defaultImportance,
        ),
      );
      // Modo calma: silencio total (plan 1.1).
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _canalCalma,
          'Recordatorios de rutina (modo calma)',
          description: 'Los mismos avisos, sin sonido ni vibración.',
          playSound: false,
          enableVibration: false,
        ),
      );
    }
  }

  NotificationDetails _detalles() {
    final calma = enCalma();
    return NotificationDetails(
      android: AndroidNotificationDetails(
        calma ? _canalCalma : _canalRutinas,
        calma
            ? 'Recordatorios de rutina (modo calma)'
            : 'Recordatorios de rutina',
        channelDescription: 'Avisa cada día de la próxima actividad.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: !calma,
        enableVibration: !calma,
      ),
    );
  }

  @override
  Future<void> programar(ScheduleEntry entrada) async {
    await _asegurar();
    await _plugin.zonedSchedule(
      id: idNotificacion(entrada.id),
      title: textoRecordatorio(entrada),
      scheduledDate: proximaOcurrencia(entrada.timeMinutes),
      notificationDetails: _detalles(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Repite todos los días a la misma hora local (plan 1.1).
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelar(String entryId) async {
    await _asegurar();
    await _plugin.cancel(id: idNotificacion(entryId));
  }

  @override
  Future<void> cancelarTodos() async {
    await _asegurar();
    await _plugin.cancelAll();
  }

  @override
  Future<bool> pedirPermiso() async {
    await _asegurar();
    // En Android <13 no hay permiso en tiempo de ejecución (no-op → true).
    return await _android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<bool> estaPermitido() async {
    await _asegurar();
    return await _android?.areNotificationsEnabled() ?? true;
  }
}

/// Scheduler real; el modo calma se lee al programar para elegir canal.
final recordatorioSchedulerProvider = Provider<RecordatorioScheduler>(
  (ref) => RecordatorioSchedulerReal(
    enCalma: () => ref.read(calmModeProvider),
  ),
);
