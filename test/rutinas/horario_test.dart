import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/features/rutinas/rutinas_providers.dart';

import 'harness.dart';

void main() {
  testWidgets('el horario lista las actividades del semilla por hora',
      (tester) async {
    await pumpRutinas(tester);
    await tester.tap(find.text('Mi horario'));
    await tester.pumpAndSettle();

    expect(find.text('Entrada'), findsOneWidget);
    expect(find.text('Clases'), findsOneWidget);
    expect(find.text('Recreo'), findsOneWidget);
    expect(find.text('Salida'), findsOneWidget);
    // Orden por hora: Entrada (08:00) antes que Salida (16:00).
    final entrada = tester.getTopLeft(find.text('Entrada')).dy;
    final salida = tester.getTopLeft(find.text('Salida')).dy;
    expect(entrada, lessThan(salida));
  });

  testWidgets('tocar una actividad la marca como hecha con aviso',
      (tester) async {
    final container = await pumpRutinas(tester);
    await tester.tap(find.text('Mi horario'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recreo'));
    await tester.pumpAndSettle();

    expect(find.text('Recreo: hecha'), findsOneWidget);
    expect(
      (await container.read(hechasHoyProvider.future)).contains('h_recreo'),
      isTrue,
    );

    // Volver a tocar la desmarca (feedback suave, reversible).
    await tester.tap(find.text('Recreo'));
    await tester.pumpAndSettle();
    expect(find.text('Recreo: pendiente otra vez'), findsOneWidget);
    expect(
      (await container.read(hechasHoyProvider.future)).isEmpty,
      isTrue,
    );
  });

  testWidgets('marcar una actividad persiste al reabrir la pestaña',
      (tester) async {
    await pumpRutinas(tester);
    await tester.tap(find.text('Mi horario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Almuerzo'));
    await tester.pump();

    // Reabre la pestaña con las mismas preferencias: el estado viene de los
    // eventos persistidos, no de la memoria del widget.
    final container = await pumpRutinas(tester, resetPrefs: false);
    await tester.tap(find.text('Mi horario'));
    await tester.pumpAndSettle();

    final hechas = await container.read(hechasHoyProvider.future);
    expect(hechas, contains('h_almuerzo'));
  });

  testWidgets('el semilla muestra la hora formateada de cada actividad',
      (tester) async {
    await pumpRutinas(tester);
    await tester.tap(find.text('Mi horario'));
    await tester.pumpAndSettle();

    // 480 minutos → 08:00; 960 → 16:00.
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('16:00'), findsOneWidget);
  });

  testWidgets('el banner muestra la siguiente actividad del día',
      (tester) async {
    await pumpRutinas(tester);

    // El semilla completo está pendiente: el banner siempre puede nombrar
    // la próxima actividad (la de hora >= ahora, o la primera del día).
    expect(find.textContaining('Siguiente actividad'), findsOneWidget);
  });

  test('formatHora convierte minutos a hh:mm', () {
    expect(formatHora(0), '00:00');
    expect(formatHora(570), '09:30');
    expect(formatHora(1439), '23:59');
  });
}
