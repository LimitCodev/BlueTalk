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

/// Decodifica JSON guardado; si está corrupto (batería agotada a mitad de
/// escritura, limpieza del sistema) devuelve null en vez de romper el arranque.
Map<String, dynamic>? _tryDecodeObject(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Igual que [_tryDecodeObject] pero para listas de mapas.
List<Map<String, dynamic>> _tryDecodeList(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return [];
    return [
      for (final row in decoded)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  } on FormatException {
    return [];
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
    final map = _tryDecodeObject(raw);
    if (map == null) {
      // Preferencias corruptas: se descarta el perfil y se empieza limpio.
      await _prefs.remove(_profileKey);
      return null;
    }
    return ChildProfile.fromMap(map);
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

/// Avance de juegos persistido en SharedPreferences.
///
/// Interim hasta Drift (mismo contrato, la feature no se entera).
class PrefsGameProgressRepo implements GameProgressRepo {
  PrefsGameProgressRepo(this._prefs);

  static const _key = 'bluetalk_game_progress';

  final SharedPreferences _prefs;
  Map<String, GameProgress>? _cache;

  Future<Map<String, GameProgress>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = _prefs.getString(_key);
    final map = <String, GameProgress>{};
    if (raw != null) {
      for (final entry in _tryDecodeList(raw)) {
        final progress = GameProgress.fromMap(entry);
        map[progress.gameId] = progress;
      }
    }
    return _cache = map;
  }

  @override
  Future<GameProgress?> progress(String gameId) async =>
      (await _load())[gameId];

  @override
  Future<void> saveProgress(GameProgress progress) async {
    final map = await _load();
    map[progress.gameId] = progress;
    await _prefs.setString(
      _key,
      jsonEncode([for (final p in map.values) p.toMap()]),
    );
  }
}

/// Horario: base en seed + cambios del usuario persistidos en prefs.
class SeedScheduleRepo implements ScheduleRepo {
  SeedScheduleRepo(this._store, this._prefs);

  static const _key = 'bluetalk_schedule';

  final SeedStore _store;
  final SharedPreferences _prefs;
  final _entries = <String, ScheduleEntry>{};
  var _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    for (final row in await _store.list('horario')) {
      final entry = ScheduleEntry.fromMap(row);
      _entries[entry.id] = entry;
    }
    // Los cambios guardados por el usuario tienen prioridad sobre el seed.
    final raw = _prefs.getString(_key);
    if (raw != null) {
      for (final row in _tryDecodeList(raw)) {
        final entry = ScheduleEntry.fromMap(row);
        _entries[entry.id] = entry;
      }
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
    await _prefs.setString(
      _key,
      jsonEncode([for (final e in _entries.values) e.toMap()]),
    );
  }
}

/// Humor y hábitos persistidos en SharedPreferences (interim hasta Drift).
class PrefsWellbeingRepo implements WellbeingRepo {
  PrefsWellbeingRepo(this._prefs);

  static const _moodsKey = 'bluetalk_moods';
  static const _habitsKey = 'bluetalk_habits';

  final SharedPreferences _prefs;
  List<MoodEntry>? _moods;
  Map<String, HabitEntry>? _habits;

  Future<List<MoodEntry>> _loadMoods() async {
    final cached = _moods;
    if (cached != null) return cached;
    final raw = _prefs.getString(_moodsKey);
    return _moods = raw == null
        ? []
        : [for (final row in _tryDecodeList(raw)) MoodEntry.fromMap(row)];
  }

  Future<Map<String, HabitEntry>> _loadHabits() async {
    final cached = _habits;
    if (cached != null) return cached;
    final raw = _prefs.getString(_habitsKey);
    final map = <String, HabitEntry>{};
    if (raw != null) {
      for (final row in _tryDecodeList(raw)) {
        final habit = HabitEntry.fromMap(row);
        map[habit.id] = habit;
      }
    }
    return _habits = map;
  }

  @override
  Future<List<MoodEntry>> moods() async =>
      List.unmodifiable(await _loadMoods());

  @override
  Future<void> addMood(MoodEntry entry) async {
    final list = await _loadMoods();
    list.add(entry);
    await _prefs.setString(
      _moodsKey,
      jsonEncode([for (final m in list) m.toMap()]),
    );
  }

  @override
  Future<List<HabitEntry>> habits() async =>
      (await _loadHabits()).values.toList();

  @override
  Future<void> saveHabit(HabitEntry entry) async {
    final map = await _loadHabits();
    map[entry.id] = entry;
    await _prefs.setString(
      _habitsKey,
      jsonEncode([for (final h in map.values) h.toMap()]),
    );
  }
}

/// Eventos de uso persistidos para el dashboard del modo padre.
///
/// Política de retención: los `picto_tap` se limitan a [_maxTaps] (los más
/// recientes) y cualquier otro tipo se conserva durante [_retencion], para
/// que un niño que comunica mucho no desplace eventos como `juego_fin`
/// (de ellos dependen el límite diario y las métricas del padre).
class PrefsUsageRepo implements UsageRepo {
  PrefsUsageRepo(this._prefs);

  static const _key = 'bluetalk_usage';
  static const _maxTaps = 300;
  static const _retencion = Duration(days: 14);

  final SharedPreferences _prefs;
  List<UsageEvent>? _cache;

  Future<List<UsageEvent>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = _prefs.getString(_key);
    return _cache = raw == null
        ? []
        : [for (final row in _tryDecodeList(raw)) UsageEvent.fromMap(row)];
  }

  @override
  Future<void> record(UsageEvent event) async {
    final list = await _load();
    list.add(event);
    // No-tapas antiguas a [_retencion] fuera; después, exceso de toques.
    final limite = event.createdAt.subtract(_retencion);
    list.removeWhere(
      (e) => e.type != 'picto_tap' && e.createdAt.isBefore(limite),
    );
    var sobran = list.where((e) => e.type == 'picto_tap').length - _maxTaps;
    if (sobran > 0) {
      // removeWhere recorre en orden: eliminamos los toques más antiguos.
      list.removeWhere((e) => e.type == 'picto_tap' && sobran-- > 0);
    }
    await _prefs.setString(
      _key,
      jsonEncode([for (final e in list) e.toMap()]),
    );
  }

  @override
  Future<List<UsageEvent>> events() async => List.unmodifiable(await _load());
}

/// Ajustes persistidos en SharedPreferences (JSON).
class PrefsSettingsRepo implements SettingsRepo {
  PrefsSettingsRepo(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<AppSettings> load() async {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    final map = _tryDecodeObject(raw);
    if (map == null) {
      // Ajustes corruptos: se vuelven a los defaults y se limpia la clave.
      await _prefs.remove(_settingsKey);
      return const AppSettings();
    }
    return AppSettings.fromMap(map);
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toMap()));
  }
}
