import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/data/local/mock_repos.dart';
import 'package:bluetalk/data/models/models.dart';

void main() {
  test('los toques de pictogramas no desplazan el tiempo de juego', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsUsageRepo(await SharedPreferences.getInstance());
    final hoy = DateTime(2026, 10, 14, 12);

    await repo.record(
      UsageEvent(
        id: 'j1',
        type: 'juego_fin',
        createdAt: hoy,
        data: const {'segundos': 600},
      ),
    );
    for (var i = 0; i < 400; i++) {
      await repo.record(UsageEvent(id: 't$i', type: 'picto_tap', createdAt: hoy));
    }

    final events = await repo.events();
    expect(
      events.where((e) => e.type == 'juego_fin'),
      hasLength(1),
      reason: 'el juego_fin no puede perderse entre los toques',
    );
    expect(events.where((e) => e.type == 'picto_tap'), hasLength(300));
  });

  test('los no-tapos de hace 20 días se purgan al registrar otro', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsUsageRepo(await SharedPreferences.getInstance());
    final hoy = DateTime(2026, 10, 14, 12);

    await repo.record(
      UsageEvent(
        id: 'v1',
        type: 'cuento_completado',
        createdAt: hoy.subtract(const Duration(days: 20)),
      ),
    );
    await repo.record(UsageEvent(id: 'h1', type: 'juego_fin', createdAt: hoy));

    final events = await repo.events();
    expect(events.map((e) => e.id), ['h1']);
  });

  test('un no-tapo reciente no se purga', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsUsageRepo(await SharedPreferences.getInstance());
    final hoy = DateTime(2026, 10, 14, 12);

    await repo.record(
      UsageEvent(
        id: 'd1',
        type: 'dibujo_guardado',
        createdAt: hoy.subtract(const Duration(days: 13)),
      ),
    );
    await repo.record(UsageEvent(id: 'h1', type: 'juego_fin', createdAt: hoy));

    expect((await repo.events()).map((e) => e.id), ['d1', 'h1']);
  });
}
