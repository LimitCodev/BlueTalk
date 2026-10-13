/// Ajustes de la app. Persistidos por `SettingsRepo` (paso 6).
class AppSettings {
  const AppSettings({
    this.ttsRate = 0.5,
    this.ttsPitch = 1.0,
    this.textScale = 1.0,
    this.remindersEnabled = true,
  });

  /// Velocidad de la voz (0–1); ritmo pausado por defecto para AAC.
  final double ttsRate;
  final double ttsPitch;

  /// Tamaño de texto controlado por la app (además del del sistema).
  final double textScale;
  final bool remindersEnabled;

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
        ttsRate: (map['ttsRate'] as num?)?.toDouble() ?? 0.5,
        ttsPitch: (map['ttsPitch'] as num?)?.toDouble() ?? 1.0,
        textScale: (map['textScale'] as num?)?.toDouble() ?? 1.0,
        remindersEnabled: map['remindersEnabled'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'ttsRate': ttsRate,
        'ttsPitch': ttsPitch,
        'textScale': textScale,
        'remindersEnabled': remindersEnabled,
      };
}
