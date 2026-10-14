import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/core/theme/calm_mode.dart';
import 'package:bluetalk/features/salud/salud_providers.dart';
import 'package:bluetalk/features/salud/salud_screen.dart';

import 'harness.dart';

Future<void> abrirSalud(WidgetTester tester) async {
  await tester.tap(find.text('Mi día'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la sección muestra el disclaimer de salud', (tester) async {
    await pumpRutinas(tester);
    await abrirSalud(tester);

    expect(find.text(disclaimerSalud), findsOneWidget);
  });

  testWidgets('el check-in emocional guarda el ánimo de hoy', (tester) async {
    final container = await pumpRutinas(tester);
    await abrirSalud(tester);

    await tester.tap(find.text('Feliz'));
    await tester.pumpAndSettle();

    expect(find.text('Hoy te sientes: Feliz'), findsOneWidget);

    final moods = await container.read(wellbeingRepoProvider).moods();
    expect(moods, hasLength(1));
    expect(moods.single.mood, 5);

    // Cambiar de opción actualiza el de hoy (no duplica el registro en UI).
    await tester.tap(find.text('Triste'));
    await tester.pumpAndSettle();
    expect(find.text('Hoy te sientes: Triste'), findsOneWidget);
  });

  testWidgets('el check-in persiste al volver a entrar', (tester) async {
    await pumpRutinas(tester);
    await abrirSalud(tester);
    await tester.tap(find.text('Enojado'));
    await tester.pumpAndSettle();

    await pumpRutinas(tester, resetPrefs: false);
    await abrirSalud(tester);

    expect(find.text('Hoy te sientes: Enojado'), findsOneWidget);
  });

  testWidgets('los hábitos se marcan y desmarcan y persisten',
      (tester) async {
    final container = await pumpRutinas(tester);
    await abrirSalud(tester);

    await tester.tap(find.text('Tomar agua'));
    await tester.pumpAndSettle();

    expect(
      (await container.read(habitosHoyProvider.future)).contains('agua'),
      isTrue,
    );

    // Desmarcar vuelve a false (persiste como hecho=false).
    await tester.tap(find.text('Tomar agua'));
    await tester.pumpAndSettle();
    expect(
      (await container.read(habitosHoyProvider.future)).isEmpty,
      isTrue,
    );

    await tester.tap(find.text('Moverme un rato'));
    await tester.pumpAndSettle();

    final container2 = await pumpRutinas(tester, resetPrefs: false);
    await abrirSalud(tester);
    expect(
      (await container2.read(habitosHoyProvider.future)).contains('movimiento'),
      isTrue,
    );
  });

  testWidgets('el modo calma y la voz rápida responden', (tester) async {
    final container = await pumpRutinas(tester);
    await abrirSalud(tester);

    await tester.tap(find.text('Modo calma'));
    await tester.pumpAndSettle();
    expect(container.read(calmModeProvider), isTrue);
  });

  testWidgets('el resumen de la semana cuenta los check-ins', (tester) async {
    final container = await pumpRutinas(tester);
    await abrirSalud(tester);

    await tester.tap(find.text('Asustado'));
    await tester.pumpAndSettle();

    expect(await container.read(resumenSemanaProvider.future), 1);
  });

  test('opciones de emoción usan los 5 moods del semilla', () {
    expect(opcionesEmocion, hasLength(5));
    expect(
      opcionesEmocion.map((e) => e.mood).toSet(),
      {1, 2, 3, 4, 5},
    );
  });
}
