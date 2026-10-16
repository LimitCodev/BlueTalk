import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/contracts/repos.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/rutinas/rutinas_providers.dart';

import 'harness.dart';

Future<void> abrirEditor(WidgetTester tester) async {
  await tester.tap(find.text('Mi horario'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Editar horario (personas adultas)'));
  await tester.pumpAndSettle();
}

/// Repo de horario que falla al guardar pero deja leer (plan 13 P6.1).
///
/// Devuelve una actividad para que la cabecera con el botón de edición
/// exista (con lista vacía esa cabecera no se construye).
class _HorarioFalla implements ScheduleRepo {
  @override
  Future<List<ScheduleEntry>> schedule() async => const [
        ScheduleEntry(
          id: 'act_prueba',
          title: 'Entrada',
          timeMinutes: 8 * 60,
        ),
      ];

  @override
  Future<void> saveEntry(ScheduleEntry entry) async =>
      throw Exception('disco lleno');
}

void main() {
  testWidgets('el editor lista las actividades con editar y quitar',
      (tester) async {
    await pumpRutinas(tester);
    await abrirEditor(tester);

    expect(find.text('Editar horario'), findsOneWidget);
    expect(find.text('Nueva hora'), findsOneWidget);
    expect(find.text('Entrada'), findsOneWidget);
    expect(find.byTooltip('Editar Entrada'), findsOneWidget);
    expect(find.byTooltip('Quitar Entrada'), findsOneWidget);
  });

  testWidgets('Nueva hora crea una actividad visible en el horario',
      (tester) async {
    await pumpRutinas(tester);
    await abrirEditor(tester);

    await tester.tap(find.text('Nueva hora'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Paseo');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Paseo'), findsOneWidget);

    // Visible también en la vista del niño.
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mi horario'));
    await tester.pumpAndSettle();
    expect(find.text('Paseo'), findsOneWidget);
  });

  testWidgets('guardar sin nombre muestra un error y no guarda',
      (tester) async {
    final container = await pumpRutinas(tester);
    await abrirEditor(tester);

    await tester.tap(find.text('Nueva hora'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump();

    expect(find.text('Escribe el nombre de la actividad'), findsOneWidget);
    final entradas = await container.read(horarioProvider.future);
    expect(entradas.length, 6, reason: 'no debe guardarse nada');
  });

  testWidgets('quitar una actividad la lleva a "quitadas" y se restaura',
      (tester) async {
    final container = await pumpRutinas(tester);
    await abrirEditor(tester);

    await tester.tap(find.byTooltip('Quitar Entrada'));
    await tester.pumpAndSettle();

    // Ya no está en el horario (desaparece su fila "A las HH:mm") pero su
    // nombre aparece en la sección de quitadas, con opción de restaurar.
    expect(find.text('A las 08:00'), findsNothing);
    expect(find.text('Actividades quitadas'), findsOneWidget);
    expect(find.text('Entrada'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Restaurar'));
    await tester.pumpAndSettle();

    expect(find.text('Actividades quitadas'), findsNothing);
    expect(find.text('Entrada'), findsOneWidget);

    final entradas = await container.read(horarioProvider.future);
    expect(entradas.any((e) => e.id == 'h_entrada' && e.enabled), isTrue);
  });

  testWidgets('editar una actividad cambia su nombre', (tester) async {
    await pumpRutinas(tester);
    await abrirEditor(tester);

    await tester.tap(find.byTooltip('Editar Recreo'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Recreo largo');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Recreo largo'), findsOneWidget);
    expect(find.text('Recreo'), findsNothing);
  });

  testWidgets(
      'si guardar falla, se queda en el formulario y avisa en literal (P6.1)',
      (tester) async {
    await pumpRutinas(
      tester,
      extraOverrides: [
        scheduleRepoProvider.overrideWithValue(_HorarioFalla()),
      ],
    );
    await abrirEditor(tester);

    await tester.tap(find.text('Nueva hora'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Paseo');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // Nunca silencio (plan 13 P6.1): aviso literal y reintentable.
    expect(
      find.text('No se pudo guardar. Prueba otra vez.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Guardar'),
      findsOneWidget,
      reason: 'el formulario sigue abierto para reintentar',
    );
    expect(find.text('Paseo'), findsOneWidget, reason: 'conserva lo escrito');
  });
}
