import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/data/models/app_settings.dart';
import 'package:bluetalk/data/models/category.dart';
import 'package:bluetalk/data/models/child_profile.dart';
import 'package:bluetalk/data/models/game_progress.dart';
import 'package:bluetalk/data/models/habit_entry.dart';
import 'package:bluetalk/data/models/mood_entry.dart';
import 'package:bluetalk/data/models/observation_rule.dart';
import 'package:bluetalk/data/models/pictogram.dart';
import 'package:bluetalk/data/models/schedule_entry.dart';
import 'package:bluetalk/data/models/story.dart';
import 'package:bluetalk/data/models/usage_event.dart';

void main() {
  group('ChildProfile', () {
    test('roundtrip toMap/fromMap conserva todo', () {
      const profile = ChildProfile(
        id: 'p1',
        nickname: 'Sol',
        avatarPicto: 'happy_man',
      );
      final back = ChildProfile.fromMap(profile.toMap());
      expect(back.toMap(), profile.toMap());
      expect(back.nickname, 'Sol');
      expect(back.createdAt, isNull);
    });

    test('claves ausentes usan defaults seguros', () {
      final back = ChildProfile.fromMap(const {'id': 'p2', 'nickname': 'Nico'});
      expect(back.avatarPicto, 'happy_man');
    });
  });

  group('Category', () {
    test('roundtrip toMap/fromMap conserva todo', () {
      const category = Category(id: 'comida', name: 'Comida', icon: 'apple', order: 2);
      final back = Category.fromMap(category.toMap());
      expect(back.toMap(), category.toMap());
    });

    test('order acepta enteros desde JSON', () {
      final back = Category.fromMap(const {'id': 'x', 'name': 'X', 'icon': 'y', 'order': 3});
      expect(back.order, 3);
    });
  });

  group('Pictogram', () {
    test('roundtrip toMap/fromMap conserva keywords', () {
      const picto = Pictogram(
        id: 'apple',
        categoryId: 'comida',
        label: 'Manzana',
        asset: 'assets/pictos/muestra/apple.svg',
        keywords: ['fruta'],
      );
      final back = Pictogram.fromMap(picto.toMap());
      expect(back.toMap(), picto.toMap());
      expect(back.keywords, ['fruta']);
    });

    test('keywords ausentes queda lista vacía', () {
      final back = Pictogram.fromMap(
        const {'id': 'a', 'categoryId': 'c', 'label': 'L', 'asset': 'x.svg'},
      );
      expect(back.keywords, isEmpty);
    });
  });

  group('ScheduleEntry', () {
    test('roundtrip toMap/fromMap conserva todo', () {
      const entry = ScheduleEntry(
        id: 's1',
        title: 'Recreo',
        timeMinutes: 570,
        pictoId: 'ball',
      );
      final back = ScheduleEntry.fromMap(entry.toMap());
      expect(back.toMap(), entry.toMap());
      expect(back.timeMinutes, 570);
    });

    test('timeMinutes acepta num y enabled es true por defecto', () {
      final back = ScheduleEntry.fromMap(const {'id': 's2', 'title': 'Almuerzo', 'timeMinutes': 720.0});
      expect(back.timeMinutes, 720);
      expect(back.enabled, isTrue);
    });
  });

  group('AppSettings', () {
    test('roundtrip toMap/fromMap conserva todo', () {
      const settings = AppSettings(ttsRate: 0.4, ttsPitch: 1.1, textScale: 1.3);
      final back = AppSettings.fromMap(settings.toMap());
      expect(back.toMap(), settings.toMap());
      expect(back.ttsRate, 0.4);
    });

    test('enteros de JSON se convierten a double', () {
      final back = AppSettings.fromMap(const {'ttsRate': 1});
      expect(back.ttsRate, 1.0);
      expect(back.remindersEnabled, isTrue);
    });
  });

  group('Story', () {
    test('roundtrip conserva páginas', () {
      const story = Story(
        id: 'cuento1',
        title: 'El gato perdido',
        coverPictoId: 'cat',
        pages: ['El gato sale a jugar', 'El gato tiene hambre'],
      );
      final back = Story.fromMap(story.toMap());
      expect(back.toMap(), story.toMap());
      expect(back.pages, hasLength(2));
    });

    test('páginas ausentes queda lista vacía', () {
      final back = Story.fromMap(const {'id': 's', 'title': 'T'});
      expect(back.pages, isEmpty);
    });
  });

  group('GameProgress', () {
    test('roundtrip y defaults', () {
      const progress = GameProgress(gameId: 'memoria', level: 3, stars: 2);
      expect(GameProgress.fromMap(progress.toMap()).toMap(), progress.toMap());

      final back = GameProgress.fromMap(const {'gameId': 'memoria'});
      expect(back.level, 1);
      expect(back.stars, 0);
    });
  });

  group('MoodEntry', () {
    test('roundtrip con fecha en epoch', () {
      final entry = MoodEntry(
        id: 'm1',
        date: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        mood: 4,
      );
      final back = MoodEntry.fromMap(entry.toMap());
      expect(back.toMap(), entry.toMap());
      expect(back.mood, 4);
    });

    test('mood ausente usa 3 (neutral)', () {
      final back = MoodEntry.fromMap(const {'id': 'm2', 'date': 0});
      expect(back.mood, 3);
    });
  });

  group('HabitEntry', () {
    test('roundtrip conserva todo', () {
      final entry = HabitEntry(
        id: 'h1',
        date: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        title: 'Tomar agua',
        pictoId: 'water',
        done: true,
      );
      final back = HabitEntry.fromMap(entry.toMap());
      expect(back.toMap(), entry.toMap());
      expect(back.done, isTrue);
    });

    test('done ausente es false', () {
      final back = HabitEntry.fromMap(
        const {'id': 'h2', 'date': 0, 'title': 'Descansar'},
      );
      expect(back.done, isFalse);
    });
  });

  group('UsageEvent', () {
    test('roundtrip conserva data', () {
      final event = UsageEvent(
        id: 'u1',
        type: 'picto_tap',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        data: const {'pictoId': 'apple'},
      );
      final back = UsageEvent.fromMap(event.toMap());
      expect(back.toMap(), event.toMap());
      expect(back.data['pictoId'], 'apple');
    });

    test('data ausente queda vacío', () {
      final back = UsageEvent.fromMap(
        const {'id': 'u2', 'type': 'story_done', 'createdAt': 0},
      );
      expect(back.data, isEmpty);
    });
  });

  group('ObservationRule', () {
    test('roundtrip y enabled por defecto true', () {
      const rule = ObservationRule(id: 'r1', label: 'Pocos pictogramas usados');
      expect(ObservationRule.fromMap(rule.toMap()).toMap(), rule.toMap());

      final back = ObservationRule.fromMap(const {'id': 'r2', 'label': 'L'});
      expect(back.enabled, isTrue);
    });
  });
}
