import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/ajustes/ajustes_screen.dart';
import 'package:bluetalk/features/ajustes/settings_controller.dart';
import 'package:bluetalk/features/onboarding/profile_controller.dart';
import 'package:bluetalk/features/rutinas/recordatorios/recordatorio_scheduler_real.dart';
import 'package:bluetalk/features/rutinas/recordatorios/recordatorios_controller.dart';

import 'harness.dart';

void main() {
  Future<(ProviderContainer, DobleRecordatorioScheduler)>
      pumpAjustesRecordatorios(
    WidgetTester tester, {
    bool permiso = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final doble = DobleRecordatorioScheduler()..permisoConcedido = permiso;
    final container = ProviderContainer(
      overrides: [
        ...overridesDeRutinas(await prefsDePrueba()),
        recordatorioSchedulerProvider.overrideWithValue(doble),
        // Ajustes solo se alcanza tras onboarding: hay perfil local.
        initialProfileProvider.overrideWithValue(
          const ChildProfile(id: 'local', nickname: 'Sol'),
        ),
      ].cast(),
    );
    addTearDown(container.dispose);
    // El sincronizador debe estar vivo: en la app lo mantiene la raíz.
    container.listen(recordatoriosProvider, (_, _) {});

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: AjustesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (container, doble);
  }

  Finder interruptor() =>
      find.widgetWithText(SwitchListTile, 'Recordatorios de rutina');

  Future<void> hacerVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Finder botonDialogo() => find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Activar recordatorios'),
      );

  testWidgets('apagar recordatorios cancela todos los avisos', (tester) async {
    final (container, doble) = await pumpAjustesRecordatorios(tester);
    // El horario de seeds estaba programado (interruptor por defecto ON).
    expect(doble.programadas, isNotEmpty);

    await hacerVisible(tester, interruptor());
    await tester.tap(interruptor());
    await tester.pumpAndSettle();

    expect(doble.cancelarTodosLlamado, greaterThanOrEqualTo(1));
    expect(doble.programadas, isEmpty);
    expect(container.read(settingsProvider).value?.remindersEnabled, isFalse);
  });

  testWidgets('encender explica literalmente y después pide el permiso',
      (tester) async {
    final (container, doble) = await pumpAjustesRecordatorios(tester);

    // Por defecto está encendido: lo apago para probar el encendido.
    await hacerVisible(tester, interruptor());
    await tester.tap(interruptor());
    await tester.pumpAndSettle();

    await tester.tap(interruptor());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'BlueTalk avisará cada día de la próxima actividad del niño. '
        'Después Android te pedirá su permiso para mostrar los avisos.',
      ),
      findsOneWidget,
    );
    expect(botonDialogo(), findsOneWidget);

    await tester.tap(botonDialogo());
    await tester.pumpAndSettle();

    expect(doble.permisoPedido, 1);
    expect(container.read(settingsProvider).value?.remindersEnabled, isTrue);
  });

  testWidgets('sin permiso no se activan los recordatorios y avisa',
      (tester) async {
    final (container, doble) =
        await pumpAjustesRecordatorios(tester, permiso: false);

    await hacerVisible(tester, interruptor());
    await tester.tap(interruptor()); // apaga
    await tester.pumpAndSettle();
    await tester.tap(interruptor()); // enciende → diálogo
    await tester.pumpAndSettle();

    await tester.tap(botonDialogo());
    await tester.pumpAndSettle();

    expect(doble.permisoPedido, 1);
    expect(container.read(settingsProvider).value?.remindersEnabled, isFalse);
    expect(
      find.text('No se dio permiso. Los recordatorios no se activaron.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5)); // cierra el SnackBar
  });

  testWidgets('con Android sin avisos se ofrece «Activar recordatorios»',
      (tester) async {
    final (_, doble) = await pumpAjustesRecordatorios(tester, permiso: false);

    final botonSeccion = find.widgetWithText(FilledButton, 'Activar recordatorios');
    await hacerVisible(tester, botonSeccion);
    expect(
      find.text('Android necesita tu permiso para mostrar los avisos.'),
      findsOneWidget,
    );

    await tester.tap(botonSeccion);
    await tester.pumpAndSettle();
    expect(botonDialogo(), findsOneWidget);

    await tester.tap(botonDialogo());
    await tester.pumpAndSettle();

    expect(doble.permisoPedido, 1);
    expect(
      find.text('No se concedió. Actívalo en los ajustes de Android.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5)); // cierra el SnackBar
  });
}
