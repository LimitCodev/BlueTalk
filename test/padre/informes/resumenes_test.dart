import 'package:bluetalk/core/almacen/almacen_local.dart';
import 'package:bluetalk/data/local/mock_repos.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/padre/informes/acumular_evento.dart';
import 'package:bluetalk/features/padre/informes/resumen_dia.dart';
import 'package:bluetalk/features/padre/informes/resumenes_repo.dart';
import 'package:bluetalk/features/padre/informes/usage_repo_con_resumen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

UsageEvent ev(String tipo, DateTime t, [Map<String, dynamic> d = const {}]) =>
    UsageEvent(id: '$tipo${t.microsecondsSinceEpoch}', type: tipo, createdAt: t, data: d);

final lunes = DateTime(2026, 11, 2, 10);

Future<(SharedPreferences, ResumenesRepo)> nuevo() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return (prefs, ResumenesRepo(AlmacenPrefs(prefs)));
}

void main() {
  group('acumular', () {
    test('cuenta toques por categoría y pictograma', () {
      var r = acumular(null, ev('picto_tap', lunes, {'categoryId': 'comida', 'pictoId': 'agua'}));
      r = acumular(r, ev('picto_tap', lunes, {'categoryId': 'comida', 'pictoId': 'pan'}));
      expect((r.dia, r.pictos), ('2026-11-02', 2));
      expect(r.categorias, {'comida': 2});
      expect(r.pictosUsados, {'agua': 1, 'pan': 1});
    });

    test('desmarcar una actividad la quita; repetir no duplica', () {
      var r = acumular(null, ev('actividad_hecha', lunes, {'entradaId': 'a'}));
      r = acumular(r, ev('actividad_hecha', lunes, {'entradaId': 'a'}));
      expect(r.actividadesHechas, {'a'});
      r = acumular(r, ev('actividad_pendiente', lunes, {'entradaId': 'a'}));
      expect(r.actividadesHechas, isEmpty);
    });

    test('suma juego, cuentos y dibujos; ignora tipos desconocidos', () {
      var r = acumular(null, ev('juego_fin', lunes, {'segundos': 90}));
      r = acumular(r, ev('cuento_completado', lunes));
      r = acumular(r, ev('dibujo_guardado', lunes));
      r = acumular(r, ev('rutina_vista', lunes));
      expect((r.sesionesJuego, r.segundosJuego, r.cuentos, r.dibujos), (1, 90, 1, 1));
    });

    test('ida y vuelta por JSON conserva todo, también las apps', () {
      final r = conApps(
        acumular(null, ev('picto_tap', lunes, {'categoryId': 'c', 'pictoId': 'p'})),
        const UsoAppsDia(totalSegundos: 60, apps: {'x.y': (nombre: 'Y', segundos: 60)}),
      );
      final vuelta = ResumenDia.fromMap(Map<String, dynamic>.from(r.toMap()));
      expect(vuelta.toMap(), r.toMap());
    });
  });

  group('ResumenesRepo', () {
    test('persiste por mes y otra instancia lo lee', () async {
      final (prefs, repo) = await nuevo();
      await repo.sumar(ev('picto_tap', DateTime(2026, 10, 31, 23)));
      await repo.sumar(ev('picto_tap', DateTime(2026, 11, 1, 8)));
      expect(prefs.getString('bluetalk_resumen_2026-10'), isNotNull);
      expect(prefs.getString('bluetalk_resumen_2026-11'), isNotNull);
      final otra = ResumenesRepo(AlmacenPrefs(prefs));
      final dias = otra.rango(DateTime(2026, 10, 30), DateTime(2026, 11, 2));
      expect(dias.map((d) => d.dia), ['2026-10-31', '2026-11-01']);
    });

    test('conserva solo los últimos 13 meses', () async {
      final (prefs, repo) = await nuevo();
      for (var m = 0; m < 15; m++) {
        await repo.sumar(ev('picto_tap', DateTime(2025, 1 + m, 5)));
      }
      expect(prefs.getStringList('bluetalk_resumen_meses'), hasLength(13));
      expect(prefs.getString('bluetalk_resumen_2025-01'), isNull);
      expect(prefs.getString('bluetalk_resumen_2026-03'), isNotNull);
    });

    test('un mes corrupto se trata como vacío', () async {
      SharedPreferences.setMockInitialValues({'bluetalk_resumen_2026-11': '{no'});
      final repo = ResumenesRepo(AlmacenPrefs(await SharedPreferences.getInstance()));
      expect(repo.dia('2026-11-02'), isNull);
    });

    test('sembrar una vez no cuenta dos veces un día ya resumido', () async {
      final (_, repo) = await nuevo();
      await repo.sumar(ev('picto_tap', lunes));
      final viejos = [ev('picto_tap', lunes), ev('picto_tap', lunes.subtract(const Duration(days: 1)))];
      await repo.sembrarUnaVez(viejos);
      await repo.sembrarUnaVez(viejos);
      expect(repo.dia('2026-11-02')!.pictos, 1);
      expect(repo.dia('2026-11-01')!.pictos, 1);
    });
  });

  test('el decorador guarda el evento y su resumen', () async {
    final (prefs, repo) = await nuevo();
    final usage = UsageRepoConResumen(PrefsUsageRepo(prefs), repo);
    await usage.record(ev('picto_tap', lunes));
    expect(await usage.events(), hasLength(1));
    expect(repo.dia('2026-11-02')!.pictos, 1);
  });
}
