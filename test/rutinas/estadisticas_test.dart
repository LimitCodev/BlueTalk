import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/rutinas/rutinas_providers.dart';

import 'harness.dart';

Future<void> abrirEstadisticas(WidgetTester tester) async {
  await tester.tap(find.text('Mis estadísticas'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra uso por día, check-ins y avance del día',
      (tester) async {
    final container = await pumpRutinas(tester);

    // Registra actividad y un check-in para que las barras tengan datos.
    await container.read(usageRepoProvider).record(
          UsageEvent(
            id: 'e1',
            type: 'actividad_hecha',
            createdAt: DateTime.now(),
            data: {'entradaId': 'h_recreo'},
          ),
        );
    await container.read(wellbeingRepoProvider).addMood(
          MoodEntry(
            id: 'm1',
            date: DateTime.now(),
            mood: 5,
          ),
        );
    container.invalidate(hechasHoyProvider);
    container.invalidate(resumenUsoProvider);

    await abrirEstadisticas(tester);

    expect(find.text('Uso de la app (7 días)'), findsOneWidget);
    expect(find.text('Check-ins de ánimo esta semana: 1'), findsOneWidget);
    expect(find.text('Actividades hechas hoy: 1 de 6'), findsOneWidget);
  });

  testWidgets('con datos vacíos muestra ceros sin fallar', (tester) async {
    await pumpRutinas(tester);
    await abrirEstadisticas(tester);

    expect(find.text('Check-ins de ánimo esta semana: 0'), findsOneWidget);
    expect(find.text('Actividades hechas hoy: 0 de 6'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });
}
