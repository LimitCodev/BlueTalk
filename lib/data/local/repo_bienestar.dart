import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../contracts/repos.dart';
import '../models/models.dart';
import 'json_seguro.dart';

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
        : [for (final row in tryDecodeList(raw)) MoodEntry.fromMap(row)];
  }

  Future<Map<String, HabitEntry>> _loadHabits() async {
    final cached = _habits;
    if (cached != null) return cached;
    final raw = _prefs.getString(_habitsKey);
    final map = <String, HabitEntry>{};
    if (raw != null) {
      for (final row in tryDecodeList(raw)) {
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
