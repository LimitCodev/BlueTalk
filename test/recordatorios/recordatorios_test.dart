import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/core/theme/calm_mode.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/ajustes/settings_controller.dart';
import 'package:bluetalk/features/rutinas/recordatorios/recordatorio_scheduler.dart';
import 'package:bluetalk/features/rutinas/recordatorios/recordatorio_scheduler_real.dart';
import 'package:bluetalk/features/rutinas/recordatorios/recordatorios_controller.dart';
import 'package:bluetalk/features/rutinas/rutinas_providers.dart';

import 'harness.dart';

void main() {
  group('sincronización de recordatorios (plan 1.1)', () {
    test('una actividad nueva se programa con su hora exacta', () async {
      final (container, doble) = await contenedorRecordatorios();
      const entrada = ScheduleEntry(
        id: 'act-merienda',
        title: 'Merienda',
        timeMinutes: 570,
      );

      await container.read(scheduleRepoProvider).saveEntry(entrada);
      container.invalidate(horarioProvider);
      await asentar();

      final id = idNotificacion('act-merienda');
      expect(doble.programadas, contains(id));
      expect(doble.programadas[id]!.timeMinutes, 570);
    });

    test('editar una actividad reprograma solo esa', () async {
      final (container, doble) = await contenedorRecordatorios();
      final repo = container.read(scheduleRepoProvider);
      await repo.saveEntry(const ScheduleEntry(
        id: 'act-a',
        title: 'Desayuno',
        timeMinutes: 480,
      ));
      await repo.saveEntry(const ScheduleEntry(
        id: 'act-b',
        title: 'Cena',
        timeMinutes: 1200,
      ));
      container.invalidate(horarioProvider);
      await asentar();

      final a = idNotificacion('act-a');
      final b = idNotificacion('act-b');
      expect(doble.conteoProgramar[a], 1);
      expect(doble.conteoProgramar[b], 1);

      await repo.saveEntry(const ScheduleEntry(
        id: 'act-a',
        title: 'Desayuno',
        timeMinutes: 495,
      ));
      container.invalidate(horarioProvider);
      await asentar();

      expect(doble.programadas[a]!.timeMinutes, 495);
      expect(doble.conteoProgramar[a], 2,
          reason: 'la editada se vuelve a programar');
      expect(doble.conteoProgramar[b], 1,
          reason: 'la que no cambió no se toca');
    });

    test('quitar una actividad cancela solo su aviso', () async {
      final (container, doble) = await contenedorRecordatorios();
      final repo = container.read(scheduleRepoProvider);
      await repo.saveEntry(const ScheduleEntry(
        id: 'act-a',
        title: 'Desayuno',
        timeMinutes: 480,
      ));
      await repo.saveEntry(const ScheduleEntry(
        id: 'act-b',
        title: 'Cena',
        timeMinutes: 1200,
      ));
      container.invalidate(horarioProvider);
      await asentar();

      final a = idNotificacion('act-a');
      final b = idNotificacion('act-b');

      // Quitar = deshabilitar (contrato actual de ScheduleRepo).
      await repo.saveEntry(const ScheduleEntry(
        id: 'act-b',
        title: 'Cena',
        timeMinutes: 1200,
        enabled: false,
      ));
      container.invalidate(horarioProvider);
      await asentar();

      expect(doble.canceladas, contains('act-b'));
      expect(doble.programadas, isNot(contains(b)));
      expect(doble.conteoProgramar[a], 1,
          reason: 'la actividad que sigue igual no se reprograma');
    });

    test('apagar recordatorios cancela todos los avisos', () async {
      final (container, doble) = await contenedorRecordatorios();
      await container.read(scheduleRepoProvider).saveEntry(const ScheduleEntry(
        id: 'act-a',
        title: 'Desayuno',
        timeMinutes: 480,
      ));
      container.invalidate(horarioProvider);
      await asentar();
      expect(doble.programadas, isNotEmpty);

      await container
          .read(settingsProvider.notifier)
          .setRemindersEnabled(false);
      await asentar();

      expect(doble.cancelarTodosLlamado, greaterThanOrEqualTo(1));
      expect(doble.programadas, isEmpty);
      expect(container.read(recordatoriosProvider), isFalse);
    });

    test('volver a encender repograma las habilitadas', () async {
      final (container, doble) = await contenedorRecordatorios();
      await container.read(scheduleRepoProvider).saveEntry(const ScheduleEntry(
        id: 'act-a',
        title: 'Desayuno',
        timeMinutes: 480,
      ));
      container.invalidate(horarioProvider);
      await asentar();

      await container
          .read(settingsProvider.notifier)
          .setRemindersEnabled(false);
      await asentar();
      expect(doble.programadas, isEmpty);

      await container
          .read(settingsProvider.notifier)
          .setRemindersEnabled(true);
      await asentar();

      expect(doble.programadas, isNotEmpty);
      expect(doble.conteoProgramar[idNotificacion('act-a')], 2);
      expect(container.read(recordatoriosProvider), isTrue);
    });

    test('sin permiso concedido nada se rompe', () async {
      final (container, doble) =
          await contenedorRecordatorios(permiso: false);

      final concedido = await container
          .read(recordatoriosProvider.notifier)
          .pedirPermisoNotificaciones();

      expect(concedido, isFalse);
      expect(doble.permisoPedido, 1);
      // El horario sigue programado: el permiso no lo bloquea (en
      // Android 13+ el sistema sencillamente no mostraría el aviso).
      expect(doble.programadas, isNotEmpty);
      expect(container.read(settingsProvider).value?.remindersEnabled, isTrue);
    });

    test('el modo calma reprograma con silencio sin cambiar la hora',
        () async {
      final (container, doble) = await contenedorRecordatorios();
      await container.read(scheduleRepoProvider).saveEntry(const ScheduleEntry(
        id: 'act-a',
        title: 'Desayuno',
        timeMinutes: 480,
      ));
      container.invalidate(horarioProvider);
      await asentar();

      final a = idNotificacion('act-a');
      final antes = doble.conteoProgramar[a]!;

      await container.read(calmModeProvider.notifier).set(true);
      await asentar();

      expect(doble.conteoProgramar[a], antes + 1,
          reason: 'se reprograma para elegir el canal de silencio');
      expect(doble.programadas[a]!.timeMinutes, 480);
    });
  });

  group('texto literal y próxima ocurrencia (plan 1.1)', () {
    test('el aviso usa el texto literal, sin emojis', () {
      const entrada = ScheduleEntry(
        id: 'x',
        title: 'Merienda',
        timeMinutes: 600,
      );
      expect(textoRecordatorio(entrada), 'Es hora de: Merienda.');
    });

    group('proximaOcurrencia', () {
      setUpAll(() {
        tzdata.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('America/Lima'));
      });

      test('si la hora de hoy aún no pasó, avisa hoy', () {
        final d = proximaOcurrencia(
          570,
          ahora: tz.TZDateTime(tz.local, 2026, 10, 15, 8, 0),
        );
        expect(d.year, 2026);
        expect(d.month, 10);
        expect(d.day, 15);
        expect(d.hour, 9);
        expect(d.minute, 30);
      });

      test('si la hora de hoy ya pasó, avisa mañana', () {
        final d = proximaOcurrencia(
          570,
          ahora: tz.TZDateTime(tz.local, 2026, 10, 15, 10, 0),
        );
        expect(d.day, 16);
        expect(d.hour, 9);
        expect(d.minute, 30);
      });

      test('en el minuto exacto, el próximo aviso es mañana', () {
        final d = proximaOcurrencia(
          570,
          ahora: tz.TZDateTime(tz.local, 2026, 10, 15, 9, 30),
        );
        expect(d.day, 16);
      });
    });
  });
}
