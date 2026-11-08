import 'dart:convert';

/// Ayudantes compartidos por los repositorios locales.
extension FirstOrNullX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}

/// Decodifica JSON guardado; si está corrupto (batería agotada a mitad de
/// escritura, limpieza del sistema) devuelve null en vez de romper el arranque.
Map<String, dynamic>? tryDecodeObject(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Igual que [tryDecodeObject] pero para listas de mapas.
List<Map<String, dynamic>> tryDecodeList(String raw) {
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
