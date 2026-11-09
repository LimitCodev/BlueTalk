/// Categoría de pictogramas (Comida, Animales, Emociones…).
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.order = 0,
    this.tipo = 'tematica',
  });

  /// Identificador estable en snake_case: `comida`, `emociones`…
  final String id;
  final String name;

  /// Pictograma que representa la categoría (id del asset sin extensión).
  final String icon;
  final int order;

  /// `nuclear` (posiciones fijas, siempre visible) o `tematica`.
  final String tipo;

  bool get nuclear => tipo == 'nuclear';

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        icon: map['icon'] as String? ?? '',
        order: (map['order'] as num?)?.toInt() ?? 0,
        tipo: map['tipo'] as String? ?? 'tematica',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'order': order,
        'tipo': tipo,
      };
}
