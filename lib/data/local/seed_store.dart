import 'dart:convert';

/// Lector de seeds JSON con caché — fuente de datos inicial del MVP.
class SeedStore {
  SeedStore(this._loadString);

  /// Inyectable para tests; en producción es `rootBundle.loadString`.
  final Future<String> Function(String path) _loadString;
  final _cache = <String, List<Map<String, dynamic>>>{};

  /// Devuelve las filas de `assets/seed/<name>.json`.
  Future<List<Map<String, dynamic>>> list(String name) async {
    final cached = _cache[name];
    if (cached != null) return cached;

    final raw = await _loadString('assets/seed/$name.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    final rows = <Map<String, dynamic>>[
      for (final row in decoded) Map<String, dynamic>.from(row as Map),
    ];
    _cache[name] = rows;
    return rows;
  }
}
