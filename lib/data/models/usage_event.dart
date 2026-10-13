/// Evento de uso agregado para las estadísticas del modo padre.
/// Solo datos de interacción locales; nunca PII (plan 00 §5.2).
class UsageEvent {
  const UsageEvent({
    required this.id,
    required this.type,
    required this.createdAt,
    this.data = const {},
  });

  final String id;

  /// `picto_tap`, `story_done`, `game_level_up`…
  final String type;
  final DateTime createdAt;

  /// Payload libre de números/strings (ids y contadores).
  final Map<String, dynamic> data;

  factory UsageEvent.fromMap(Map<String, dynamic> map) => UsageEvent(
        id: map['id'] as String,
        type: map['type'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ?? 0,
        ),
        data: Map<String, dynamic>.from(map['data'] as Map? ?? const {}),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'data': data,
      };
}
