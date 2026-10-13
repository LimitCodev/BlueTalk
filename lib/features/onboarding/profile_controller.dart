import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../data/models/models.dart';

/// Perfil leído en `main()` antes del primer frame (`null` = primera vez).
final initialProfileProvider = Provider<ChildProfile?>((ref) => null);

/// Controlador del perfil del niño: local, sin PII (solo apodo).
class ProfileController extends Notifier<ChildProfile?> {
  @override
  ChildProfile? build() => ref.read(initialProfileProvider);

  /// Crea el perfil con un apodo local y lo persiste (plan 01 §7).
  Future<void> create(String nickname) async {
    final profile = ChildProfile(
      id: 'local',
      nickname: nickname.trim(),
      createdAt: DateTime.now(),
    );
    await ref.read(profileRepoProvider).saveProfile(profile);
    state = profile;
  }

  /// Cambia el avatar (picto) del niño y lo persiste (plan 00 §5.2).
  Future<void> updateAvatar(String pictoId) async {
    final current = state;
    if (current == null || current.avatarPicto == pictoId) return;
    final updated = current.copyWith(avatarPicto: pictoId);
    await ref.read(profileRepoProvider).saveProfile(updated);
    state = updated;
  }
}

/// Perfil activo del niño (`null` → onboarding).
final profileProvider = NotifierProvider<ProfileController, ChildProfile?>(
  ProfileController.new,
);
