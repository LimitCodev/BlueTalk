/// Avance del niño en un juego (memoria, cuentos, artista).
class GameProgress {
  const GameProgress({
    required this.gameId,
    this.level = 1,
    this.stars = 0,
  });

  /// `memoria`, `cuentos`, `artista`.
  final String gameId;
  final int level;

  /// 0–3 estrellas por nivel.
  final int stars;

  factory GameProgress.fromMap(Map<String, dynamic> map) => GameProgress(
        gameId: map['gameId'] as String,
        level: (map['level'] as num?)?.toInt() ?? 1,
        stars: (map['stars'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'gameId': gameId,
        'level': level,
        'stars': stars,
      };
}
