/// Regla de observación del modo padre: qué señal vigilar y avisar.
/// Siempre con disclaimer de no diagnóstico (plan 00 §10).
class ObservationRule {
  const ObservationRule({
    required this.id,
    required this.label,
    this.enabled = true,
  });

  final String id;
  final String label;
  final bool enabled;

  factory ObservationRule.fromMap(Map<String, dynamic> map) => ObservationRule(
        id: map['id'] as String,
        label: map['label'] as String? ?? '',
        enabled: map['enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'enabled': enabled,
      };
}
