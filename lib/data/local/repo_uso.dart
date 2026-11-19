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
///
/// Política de escritura: en una ráfaga se escribe como mucho una vez cada
/// [_agrupar]; el resto queda en memoria y se vuelca con [flush] (al pasar
/// a segundo plano, al leer los eventos o a los 2 s). Si el proceso muere
/// sin aviso se pierde la última ráfaga: son métricas, no configuración.
class PrefsUsageRepo implements UsageRepo {
  PrefsUsageRepo(this._prefs, {DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now;

  static const _key = 'bluetalk_usage';
  static const _maxTaps = 300;
  static const _retencion = Duration(days: 14);
  static const _agrupar = Duration(seconds: 2);

  final SharedPreferences _prefs;
  final DateTime Function() _reloj;
  List<UsageEvent>? _cache;
  DateTime? _ultimaEscritura;
  var _pendientes = 0;

  /// Visible para los tests de rendimiento: escrituras reales a disco.
  int escrituras = 0;

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
    _pendientes++;
    final ahora = _reloj();
    final anterior = _ultimaEscritura;
    if (anterior == null || ahora.difference(anterior) >= _agrupar) {
      await _guardar(list, ahora);
    }
  }

  /// Fuerza el volcado de lo que quedó en memoria.
  Future<void> flush() async {
    if (_pendientes == 0) return;
    await _guardar(await _load(), _reloj());
  }

  Future<void> _guardar(List<UsageEvent> list, DateTime ahora) async {
    // Se codifica y se marca como escrito antes del `await`: si llega otro
    // toque mientras el canal escribe, queda pendiente para el próximo.
    final texto = jsonEncode([for (final e in list) e.toMap()]);
    _ultimaEscritura = ahora;
    _pendientes = 0;
    escrituras++;
    await _prefs.setString(_key, texto);
  }

  @override
  Future<List<UsageEvent>> events() async {
    await flush();
    return List.unmodifiable(await _load());
  }
}
