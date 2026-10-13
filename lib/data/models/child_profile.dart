/// Perfil local del niño. **Sin PII**: solo apodo opcional y avatar picto
/// (plan 00 §5.2). Nada de apellidos, emails, fotos ni ubicación.
class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.nickname,
    this.avatarPicto = 'happy_man',
    this.createdAt,
  });

  final String id;
  final String nickname;
  final String avatarPicto;

  /// Solo para orden local; nunca se envía a ningún servidor en el MVP.
  final DateTime? createdAt;

  factory ChildProfile.fromMap(Map<String, dynamic> map) => ChildProfile(
        id: map['id'] as String,
        nickname: map['nickname'] as String? ?? '',
        avatarPicto: map['avatarPicto'] as String? ?? 'happy_man',
        createdAt: map['createdAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nickname': nickname,
        'avatarPicto': avatarPicto,
        'createdAt': createdAt?.millisecondsSinceEpoch,
      };

  ChildProfile copyWith({String? nickname, String? avatarPicto}) => ChildProfile(
        id: id,
        nickname: nickname ?? this.nickname,
        avatarPicto: avatarPicto ?? this.avatarPicto,
        createdAt: createdAt,
      );
}
