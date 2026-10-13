/// Check-in emocional diario (salud).
class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
  });

  final String id;
  final DateTime date;

  /// Estado de ánimo 1–5 (caritas).
  final int mood;

  factory MoodEntry.fromMap(Map<String, dynamic> map) => MoodEntry(
        id: map['id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(
          (map['date'] as num?)?.toInt() ?? 0,
        ),
        mood: (map['mood'] as num?)?.toInt() ?? 3,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'mood': mood,
      };
}
