import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/data/local/mock_repos.dart';
import 'package:bluetalk/data/local/seed_store.dart';
import 'package:bluetalk/data/models/models.dart';

/// Seed falso con UNA entrada (el patrón de `seeds_test.dart` sin assets).
SeedStore _store() => SeedStore(
      (path) async => jsonEncode([
        {
          'id': 'desayuno',
          'title': 'Desayuno',
          'timeMinutes': 480,
          'pictoId': 'breakfast',
          'enabled': true,
        },
      ]),
    );

void main() {
  test('el horario sobrevive al reinicio de la app', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final repo = SeedScheduleRepo(_store(), prefs);
    expect(await repo.schedule(), hasLength(1));

    // Actividad nueva (la crea un padre).
    await repo.saveEntry(
      const ScheduleEntry(
        id: 'escuela',
        title: 'Escuela',
        timeMinutes: 450,
        pictoId: 'school',
      ),
    );
    // Actividad seed desactivada.
    final semilla = (await repo.schedule())
        .firstWhere((e) => e.id == 'desayuno');
    await repo.saveEntry(
      ScheduleEntry(
        id: semilla.id,
        title: semilla.title,
        timeMinutes: semilla.timeMinutes,
        pictoId: semilla.pictoId,
        enabled: false,
      ),
    );

    // "Reinicio": repo nuevo con las mismas prefs relee desde disco.
    final reinicio = SeedScheduleRepo(
      _store(),
      await SharedPreferences.getInstance(),
    );
    final entries = await reinicio.schedule();

    expect(entries, hasLength(2), reason: 'nueva + seed');
    // Orden por timeMinutes: escuela (450) antes que desayuno (480).
    expect(entries.map((e) => e.id), ['escuela', 'desayuno']);
    expect(
      entries.firstWhere((e) => e.id == 'desayuno').enabled,
      isFalse,
      reason: 'la edición debe persistir',
    );
  });

  test('prefs corruptas no impiden cargar el seed del horario', () async {
    SharedPreferences.setMockInitialValues({'bluetalk_schedule': '{{ no es json'});
    final prefs = await SharedPreferences.getInstance();

    final repo = SeedScheduleRepo(_store(), prefs);
    expect(await repo.schedule(), hasLength(1));
  });
}
