/// Pictograma AAC (set Mulberry Symbols, plan 09 §1).
class Pictogram {
  const Pictogram({
    required this.id,
    required this.categoryId,
    required this.label,
    required this.asset,
    this.keywords = const [],
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

  factory Pictogram.fromMap(Map<String, dynamic> map) => Pictogram(
        id: map['id'] as String,
        categoryId: map['categoryId'] as String? ?? '',
        label: map['label'] as String? ?? '',
        asset: map['asset'] as String? ?? '',
        keywords: (map['keywords'] as List?)?.cast<String>() ?? const [],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'label': label,
        'asset': asset,
        'keywords': keywords,
      };
}
