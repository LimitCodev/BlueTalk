/// Categoría de pictogramas (Comida, Animales, Emociones…).
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.order = 0,
  });

  /// Identificador estable en snake_case: `comida`, `emociones`…
  final String id;
  final String name;

  /// Pictograma que representa la categoría (id del asset sin extensión).
  final String icon;
  final int order;

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        icon: map['icon'] as String? ?? '',
        order: (map['order'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'order': order,
      };
}
