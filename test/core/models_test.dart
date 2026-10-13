import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/data/models/app_settings.dart';
import 'package:bluetalk/data/models/category.dart';
import 'package:bluetalk/data/models/child_profile.dart';
import 'package:bluetalk/data/models/pictogram.dart';
import 'package:bluetalk/data/models/schedule_entry.dart';

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
}
