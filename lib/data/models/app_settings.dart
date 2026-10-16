/// Ajustes de la app. Persistidos por `SettingsRepo` (paso 6).
class AppSettings {
  const AppSettings({
    this.ttsRate = 0.5,
    this.ttsPitch = 1.0,
    this.textScale = 1.0,
    this.remindersEnabled = true,
    this.tema = 'celeste',
  });

  /// Velocidad de la voz (0–1); ritmo pausado por defecto para AAC.
  final double ttsRate;
  final double ttsPitch;

  /// Tamaño de texto controlado por la app (además del del sistema).
  final double textScale;
  final bool remindersEnabled;

  /// Id del tema de color elegido en Ajustes (plan 13 P4). Las claves
  /// válidas viven en `AppColors.temas`; un id desconocido cae al
  /// celeste de marca al construir el tema.
  final String tema;

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
        ttsRate: (map['ttsRate'] as num?)?.toDouble() ?? 0.5,
        ttsPitch: (map['ttsPitch'] as num?)?.toDouble() ?? 1.0,
        textScale: (map['textScale'] as num?)?.toDouble() ?? 1.0,
        remindersEnabled: map['remindersEnabled'] as bool? ?? true,
        tema: map['tema'] as String? ?? 'celeste',
      );

  Map<String, dynamic> toMap() => {
        'ttsRate': ttsRate,
        'ttsPitch': ttsPitch,
        'textScale': textScale,
        'remindersEnabled': remindersEnabled,
        'tema': tema,
      };

  AppSettings copyWith({
    double? ttsRate,
    double? ttsPitch,
    double? textScale,
    bool? remindersEnabled,
    String? tema,
  }) =>
      AppSettings(
        ttsRate: ttsRate ?? this.ttsRate,
        ttsPitch: ttsPitch ?? this.ttsPitch,
        textScale: textScale ?? this.textScale,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        tema: tema ?? this.tema,
      );
}
