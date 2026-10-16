import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/data/local/mock_repos.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/padre/salud_padre/salud_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('la vista de salud del padre resume la semana con su disclaimer',
      (tester) async {
    final prefs = await prefsDePrueba();
    final bienestar = PrefsWellbeingRepo(prefs);
    await bienestar.addMood(
      MoodEntry(id: 'm1', date: ahoraFija, mood: 4),
    );
    await bienestar.addMood(
      MoodEntry(
        id: 'm2',
        date: ahoraFija.subtract(const Duration(days: 2)),
        mood: 2,
      ),
    );
    await bienestar.saveHabit(
      HabitEntry(
        id: 'h1',
        date: ahoraFija,
        title: 'Beber agua',
        done: true,
      ),
    );
    await bienestar.saveHabit(
      HabitEntry(
        id: 'h2',
        date: ahoraFija.subtract(const Duration(days: 1)),
        title: 'Descanso visual',
        done: false,
      ),
    );

    final container = await pumpPadre(
      tester,
      home: const Scaffold(body: SaludPadreScreen()),
      overrides: overridesDePadre(prefs),
    );

    // Disclaimer idéntico al del plan 04, en cabecera.
    expect(
      find.text(
        'Esta app no reemplaza evaluación profesional. '
        'Consulta a tu especialista.',
      ),
      findsOneWidget,
    );
    expect(find.text(disclaimerSalud), findsOneWidget);
    expect(find.text('Check-ins de los últimos 7 días'), findsOneWidget);
    expect(find.text('Hábitos marcados esta semana'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);
    expect(find.text('13 de octubre'), findsOneWidget);
    expect(find.text('🙂'), findsOneWidget);

    final resumen = await container.read(resumenSaludProvider.future);
    expect(resumen.checkInsSemana, 2);
    expect(resumen.habitosHechos, 1);
    expect(resumen.habitosTotal, 2);
    expect(resumen.historial.first, (ahoraFija, 4));
  });

  testWidgets('sin check-ins sigue mostrando el disclaimer', (tester) async {
    final prefs = await prefsDePrueba();
    await pumpPadre(
      tester,
      home: const Scaffold(body: SaludPadreScreen()),
      overrides: overridesDePadre(prefs),
    );

    expect(find.text(disclaimerSalud), findsOneWidget);
    expect(
      find.text('Todavía no hay check-ins esta semana.'),
      findsOneWidget,
    );
    expect(find.text('0 de 0'), findsOneWidget);
  });
}
