/// Entrada del horario diario (rutinas).
class ScheduleEntry {
  const ScheduleEntry({
    required this.id,
    required this.title,
    required this.timeMinutes,
    this.pictoId,
    this.enabled = true,
  });

  final String id;
  final String title;

  /// Minutos desde medianoche (9:30 → 570). Evita problemas de zona horaria.
  final int timeMinutes;

  /// Pictograma asociado (opcional).
  final String? pictoId;
  final bool enabled;

  factory ScheduleEntry.fromMap(Map<String, dynamic> map) => ScheduleEntry(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        timeMinutes: (map['timeMinutes'] as num?)?.toInt() ?? 0,
        pictoId: map['pictoId'] as String?,
        enabled: map['enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'timeMinutes': timeMinutes,
        'pictoId': pictoId,
        'enabled': enabled,
      };
}
