/// Cuento AAC: páginas de texto que el niño acompaña con pictogramas.
class Story {
  const Story({
    required this.id,
    required this.title,
    this.coverPictoId,
    this.pages = const [],
  });

  final String id;
  final String title;
  final String? coverPictoId;

  /// Una oración por página (lenguaje literal, plan 00 §5.8).
  final List<String> pages;

  factory Story.fromMap(Map<String, dynamic> map) => Story(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        coverPictoId: map['coverPictoId'] as String?,
        pages: (map['pages'] as List?)?.cast<String>() ?? const [],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'coverPictoId': coverPictoId,
        'pages': pages,
      };
}
