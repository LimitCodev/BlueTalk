import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/local/mock_repos.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/onboarding/profile_controller.dart';

void main() {
  test('updateAvatar cambia el avatar y lo persiste en el perfil local',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialProfileProvider.overrideWithValue(
          const ChildProfile(id: 'local', nickname: 'Sol'),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(profileProvider)?.avatarPicto, 'happy_man');

    await container.read(profileProvider.notifier).updateAvatar('cat');

    expect(container.read(profileProvider)?.avatarPicto, 'cat');
    expect(
      (await PrefsProfileRepo(prefs).currentProfile())?.avatarPicto,
      'cat',
      reason: 'el cambio debe sobrevivir a un reinicio',
    );
  });

  test('updateAvatar sin cambios no reescribe el perfil', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialProfileProvider.overrideWithValue(
          const ChildProfile(id: 'local', nickname: 'Sol'),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(profileProvider.notifier).updateAvatar('happy_man');

    expect(prefs.getString('bluetalk_profile'), isNull,
        reason: 'elegir el avatar actual no debe escribir nada');
  });
}
