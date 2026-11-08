import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../contracts/repos.dart';
import '../models/models.dart';
import 'json_seguro.dart';
import 'seed_store.dart';

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
      for (final row in tryDecodeList(raw)) {
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
