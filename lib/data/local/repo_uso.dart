import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../contracts/repos.dart';
import '../models/models.dart';
import 'json_seguro.dart';

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
        : [for (final row in tryDecodeList(raw)) UsageEvent.fromMap(row)];
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
    await _prefs.setString(_key, jsonEncode([for (final e in list) e.toMap()]));
  }

  @override
  Future<List<UsageEvent>> events() async => List.unmodifiable(await _load());
}
