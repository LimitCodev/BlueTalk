import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../contracts/repos.dart';
import '../models/models.dart';
import 'json_seguro.dart';

const _profileKey = 'bluetalk_profile';

/// Perfil local persistido en SharedPreferences (JSON).
class PrefsProfileRepo implements ProfileRepo {
  PrefsProfileRepo(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<ChildProfile?> currentProfile() async {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    final map = tryDecodeObject(raw);
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
