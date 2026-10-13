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
}

/// Perfil activo del niño (`null` → onboarding).
final profileProvider = NotifierProvider<ProfileController, ChildProfile?>(
  ProfileController.new,
);
