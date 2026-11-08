import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../contracts/repos.dart';
import '../models/models.dart';
import 'json_seguro.dart';

const _settingsKey = 'bluetalk_settings';

/// Ajustes persistidos en SharedPreferences (JSON).
class PrefsSettingsRepo implements SettingsRepo {
  PrefsSettingsRepo(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<AppSettings> load() async {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    final map = tryDecodeObject(raw);
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
