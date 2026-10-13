import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/local/mock_repos.dart';
import 'package:bluetalk/data/local/seed_store.dart';
import 'package:bluetalk/data/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SeedStore store;
  setUp(() => store = SeedStore(rootBundle.loadString));

  group('seeds', () {
    test('categorías: 7 ordenadas de 1 a 7', () async {
      final cats = (await store.list('categorias')).map(Category.fromMap).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      expect(cats, hasLength(7));
      expect(cats.first.id, 'emociones');
      expect(cats.last.id, 'clima');
      expect(cats.map((c) => c.order), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('pictogramas: 42 y cada asset existe en disco', () async {
      final rows = await store.list('pictogramas');
      expect(rows, hasLength(42));
      for (final row in rows) {
        final picto = Pictogram.fromMap(row);
        expect(
          File(picto.asset).existsSync(),
          isTrue,
          reason: 'Falta el archivo ${picto.asset}',
        );
      }
    });

    test('pictogramas: sin bloques <style> (flutter_svg ignora el CSS)', () async {
      final rows = await store.list('pictogramas');
      for (final row in rows) {
        final picto = Pictogram.fromMap(row);
        final svg = File(picto.asset).readAsStringSync();
        expect(
          svg.contains('<style'),
          isFalse,
          reason: '${picto.asset} usa clases CSS: flutter_svg las ignora y el '
              'picto se renderiza en negro. Los estilos van inline.',
        );
      }
    });

    test('pictogramas: sus categorías existen', () async {
      final catIds = (await store.list('categorias')).map((c) => c['id']).toSet();
      final rows = await store.list('pictogramas');
      for (final row in rows) {
        expect(catIds, contains(row['categoryId']));
      }
    });

    test('cuentos: 3 con páginas no vacías', () async {
      final cuentos = (await store.list('cuentos')).map(Story.fromMap).toList();
      expect(cuentos, hasLength(3));
      for (final cuento in cuentos) {
        expect(cuento.pages, isNotEmpty, reason: 'Sin páginas: ${cuento.id}');
      }
    });

    test('horario: entradas en minutos crecientes', () async {
      final rows = await store.list('horario');
      expect(rows, hasLength(6));
      final minutos =
          (await store.list('horario')).map((r) => r['timeMinutes'] as int);
      final sorted = [...minutos]..sort();
      expect(minutos, sorted);
      expect(minutos.first, 480);
    });

    test('reglas: 5 activadas por defecto', () async {
      final reglas = (await store.list('reglas')).map(ObservationRule.fromMap);
      expect(reglas, hasLength(5));
      expect(reglas.every((r) => r.enabled), isTrue);
    });
  });

  group('repositorios', () {
    test('perfil: guardar y recuperar con SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PrefsProfileRepo(prefs);

      expect(await repo.currentProfile(), isNull);

      const profile = ChildProfile(id: 'p1', nickname: 'Sol');
      await repo.saveProfile(profile);

      final loaded = await repo.currentProfile();
      expect(loaded, isNotNull);
      expect(loaded!.nickname, 'Sol');
      expect(loaded.avatarPicto, 'happy_man');
    });

    test('ajustes: default y persistencia', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PrefsSettingsRepo(prefs);

      final defaults = await repo.load();
      expect(defaults.ttsRate, 0.5);
      expect(defaults.textScale, 1.0);

      await repo.save(const AppSettings(ttsRate: 0.8, textScale: 1.3));
      final loaded = await repo.load();
      expect(loaded.ttsRate, 0.8);
      expect(loaded.textScale, 1.3);
      expect(loaded.remindersEnabled, isTrue);
    });

    test('pictogramas: por categoría y por id', () async {
      final repo = SeedPictogramRepo(store);

      final comida = await repo.pictogramsOf('comida');
      expect(comida.map((p) => p.id), containsAll(['apple', 'bread', 'milk']));

      final apple = await repo.pictogram('apple');
      expect(apple, isNotNull);
      expect(apple!.label, 'Manzana');

      expect(await repo.pictogram('no_existe'), isNull);
    });

    test('cuentos: lista y por id', () async {
      final repo = SeedStoryRepo(store);
      final cuentos = await repo.stories();
      expect(cuentos, hasLength(3));
      expect(await repo.story('cuento_gato'), isNotNull);
      expect(await repo.story('no_existe'), isNull);
    });

    test('horario: carga seeds y acepta cambios', () async {
      final repo = SeedScheduleRepo(store);
      final entries = await repo.schedule();
      expect(entries, hasLength(6));

      final primera = entries.first;
      await repo.saveEntry(
        ScheduleEntry(
          id: primera.id,
          title: primera.title,
          timeMinutes: primera.timeMinutes,
          pictoId: primera.pictoId,
          enabled: false,
        ),
      );

      final after = await repo.schedule();
      expect(after.firstWhere((e) => e.id == primera.id).enabled, isFalse);
      expect(after, hasLength(6));
    });

    test('bienestar: moods y hábitos persisten', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PrefsWellbeingRepo(prefs);
      final hoy = DateTime(2026, 10, 13);

      await repo.addMood(MoodEntry(id: 'm1', date: hoy, mood: 4));
      await repo.saveHabit(HabitEntry(id: 'h1', date: hoy, title: 'Cepillarse'));
      await repo.saveHabit(HabitEntry(id: 'h1', date: hoy, title: 'Cepillarse', done: true));

      expect(await repo.moods(), hasLength(1));
      final habits = await repo.habits();
      expect(habits, hasLength(1), reason: 'saveHabit debe reemplazar, no duplicar');
      expect(habits.single.done, isTrue);

      // Nueva instancia (app reiniciada): lo escrito sigue ahí.
      final fresh = PrefsWellbeingRepo(await SharedPreferences.getInstance());
      expect(await fresh.moods(), hasLength(1));
      expect((await fresh.habits()).single.done, isTrue);
    });

    test('uso: registra eventos y recorta a 200', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PrefsUsageRepo(prefs);

      for (var i = 0; i < 205; i++) {
        await repo.record(
          UsageEvent(
            id: 'u$i',
            type: 'picto_tap',
            createdAt: DateTime(2026, 10, 13),
            data: {'picto': 'apple'},
          ),
        );
      }

      final events = await repo.events();
      expect(events, hasLength(200), reason: 'tope para no engordar en gama baja');
      expect(events.last.id, 'u204', reason: 'se conservan los más recientes');
    });

    test('avance de juegos: persiste entre reinicios', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = PrefsGameProgressRepo(await SharedPreferences.getInstance());
      await repo.saveProgress(const GameProgress(gameId: 'memoria', level: 3, stars: 2));

      final progress = await repo.progress('memoria');
      expect(progress, isNotNull);
      expect(progress!.level, 3);
      expect(progress.stars, 2);
      expect(await repo.progress('otro'), isNull);

      final fresh =
          PrefsGameProgressRepo(await SharedPreferences.getInstance());
      expect((await fresh.progress('memoria'))?.level, 3);
    });

    test('prefs corruptas: perfil y ajustes no rompen el arranque', () async {
      SharedPreferences.setMockInitialValues({
        'bluetalk_profile': '{"id": "p1", "nick', // cortado a mitad
        'bluetalk_settings': 'no es json',
      });
      final prefs = await SharedPreferences.getInstance();

      final profile = await PrefsProfileRepo(prefs).currentProfile();
      expect(profile, isNull, reason: 'perfil corrupto se descarta, no lanza');

      final settings = await PrefsSettingsRepo(prefs).load();
      expect(settings.textScale, 1.0, reason: 'ajustes corruptos vuelven a defaults');

      // Las claves corruptas quedaron limpias para la próxima escritura.
      expect(prefs.getString('bluetalk_profile'), isNull);
      expect(prefs.getString('bluetalk_settings'), isNull);
    });
  });

  group('di', () {
    test('USE_SUPABASE está en false (MVP local)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(useSupabaseProvider), isFalse);
    });

    test('seeds son JSON válido (sanidad del formato)', () async {
      final raw = await rootBundle.loadString('assets/seed/cuentos.json');
      expect(jsonDecode(raw), isA<List<dynamic>>());
    });
  });
}
