/// Pictograma AAC (set Mulberry Symbols, plan 09 §1).
class Pictogram {
  const Pictogram({
    required this.id,
    required this.categoryId,
    required this.label,
    required this.asset,
    this.keywords = const [],
    this.order,
    this.clase,
  });

  /// Id estable del archivo: `apple`, `eat_,_to`…
  final String id;
  final String categoryId;

  /// Etiqueta en español que se muestra y se pronuncia con TTS.
  final String label;

  /// Ruta del asset: `assets/pictos/.../apple.svg`.
  final String asset;

  /// Sinónimos para búsqueda literal.
  final List<String> keywords;

  /// Posición fija en el tablero nuclear; null en las categorías temáticas.
  final int? order;

  /// Clase gramatical del tablero nuclear (`verbo`, `pronombre`…).
  final String? clase;

  factory Pictogram.fromMap(Map<String, dynamic> map) => Pictogram(
        id: map['id'] as String,
        categoryId: map['categoryId'] as String? ?? '',
        label: map['label'] as String? ?? '',
        asset: map['asset'] as String? ?? '',
        keywords: (map['keywords'] as List?)?.cast<String>() ?? const [],
        order: (map['order'] as num?)?.toInt(),
        clase: map['clase'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'label': label,
        'asset': asset,
        'keywords': keywords,
        if (order != null) 'order': order,
        if (clase != null) 'clase': clase,
      };
}
