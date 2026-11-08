import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../contracts/repos.dart';
import '../models/models.dart';
import 'json_seguro.dart';

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
      for (final entry in tryDecodeList(raw)) {
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
