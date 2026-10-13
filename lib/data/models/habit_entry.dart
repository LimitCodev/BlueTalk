/// Hábito marcado en un día (salud): agua, descanso, cepillarse…
class HabitEntry {
  const HabitEntry({
    required this.id,
    required this.date,
    required this.title,
    this.pictoId,
    this.done = false,
  });

  final String id;
  final DateTime date;
  final String title;
  final String? pictoId;
  final bool done;

  factory HabitEntry.fromMap(Map<String, dynamic> map) => HabitEntry(
        id: map['id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(
          (map['date'] as num?)?.toInt() ?? 0,
        ),
        title: map['title'] as String? ?? '',
        pictoId: map['pictoId'] as String?,
        done: map['done'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'title': title,
        'pictoId': pictoId,
        'done': done,
      };
}
