import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../contracts/repos.dart';
import '../models/models.dart';
import 'seed_store.dart';

extension _FirstOrNullX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}

const _profileKey = 'bluetalk_profile';
const _settingsKey = 'bluetalk_settings';

/// Perfil local persistido en SharedPreferences (JSON).
class PrefsProfileRepo implements ProfileRepo {
  PrefsProfileRepo(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<ChildProfile?> currentProfile() async {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    return ChildProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveProfile(ChildProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toMap()));
  }
}

/// Categorías y pictogramas desde `assets/seed/`.
class SeedPictogramRepo implements PictogramRepo {
  SeedPictogramRepo(this._store);

  final SeedStore _store;

  @override
  Future<List<Category>> categories() async {
    final cats = (await _store.list('categorias')).map(Category.fromMap);
    return cats.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Future<List<Pictogram>> pictogramsOf(String categoryId) async {
    final pictos = (await _store.list('pictogramas')).map(Pictogram.fromMap);
    return pictos.where((p) => p.categoryId == categoryId).toList();
  }

  @override
  Future<Pictogram?> pictogram(String id) async {
    final pictos = (await _store.list('pictogramas')).map(Pictogram.fromMap);
    return pictos.firstWhereOrNull((p) => p.id == id);
  }
}

/// Cuentos desde `assets/seed/`.
class SeedStoryRepo implements StoryRepo {
  SeedStoryRepo(this._store);

  final SeedStore _store;

  @override
  Future<List<Story>> stories() async =>
      (await _store.list('cuentos')).map(Story.fromMap).toList();

  @override
  Future<Story?> story(String id) async =>
      (await stories()).firstWhereOrNull((s) => s.id == id);
}

/// Avance de juegos en memoria (se migrará a Drift cuando toque).
class InMemoryGameProgressRepo implements GameProgressRepo {
  final _byGame = <String, GameProgress>{};

  @override
  Future<GameProgress?> progress(String gameId) async => _byGame[gameId];

  @override
  Future<void> saveProgress(GameProgress progress) async {
    _byGame[progress.gameId] = progress;
  }
}

/// Horario desde seed con mutaciones en memoria.
class SeedScheduleRepo implements ScheduleRepo {
  SeedScheduleRepo(this._store);

  final SeedStore _store;
  final _entries = <String, ScheduleEntry>{};
  var _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    for (final row in await _store.list('horario')) {
      final entry = ScheduleEntry.fromMap(row);
      _entries[entry.id] = entry;
    }
    _loaded = true;
  }

  @override
  Future<List<ScheduleEntry>> schedule() async {
    await _ensureLoaded();
    return _entries.values.toList()
      ..sort((a, b) => a.timeMinutes.compareTo(b.timeMinutes));
  }

  @override
  Future<void> saveEntry(ScheduleEntry entry) async {
    await _ensureLoaded();
    _entries[entry.id] = entry;
  }
}

/// Humor y hábitos en memoria (persistencia real llega con Drift).
class InMemoryWellbeingRepo implements WellbeingRepo {
  final _moods = <MoodEntry>[];
  final _habits = <HabitEntry>[];

  @override
  Future<List<MoodEntry>> moods() async => List.unmodifiable(_moods);

  @override
  Future<void> addMood(MoodEntry entry) async => _moods.add(entry);

  @override
  Future<List<HabitEntry>> habits() async => List.unmodifiable(_habits);

  @override
  Future<void> saveHabit(HabitEntry entry) async {
    _habits.removeWhere((h) => h.id == entry.id);
    _habits.add(entry);
  }
}

/// Eventos de uso en memoria para estadísticas.
class InMemoryUsageRepo implements UsageRepo {
  final _events = <UsageEvent>[];

  @override
  Future<void> record(UsageEvent event) async => _events.add(event);

  @override
  Future<List<UsageEvent>> events() async => List.unmodifiable(_events);
}

/// Ajustes persistidos en SharedPreferences (JSON).
class PrefsSettingsRepo implements SettingsRepo {
  PrefsSettingsRepo(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<AppSettings> load() async {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    return AppSettings.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toMap()));
  }
}
